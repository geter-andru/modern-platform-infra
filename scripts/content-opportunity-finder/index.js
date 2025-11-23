/**
 * Content Opportunity Finder
 * Uses Hacker News API to find unanswered questions and content opportunities
 */

import Anthropic from '@anthropic-ai/sdk';
import fs from 'fs/promises';
import path from 'path';

const anthropic = new Anthropic();

// Configuration
const OUTPUT_ROOT = process.env.OUTPUT_ROOT || process.cwd();

// Topics to search for on Hacker News
const SEARCH_TOPICS = [
  'first sales hire startup',
  'ICP ideal customer profile',
  'B2B SaaS sales strategy',
  'founder led sales',
  'technical founder sales',
  'startup sales process',
  'enterprise sales startup',
  'sales hiring early stage',
  'GTM go to market strategy',
  'product market fit sales',
  'customer discovery startup',
  'finding first customers'
];

// HN Algolia API base
const HN_API = 'https://hn.algolia.com/api/v1';

/**
 * Main execution
 */
async function main() {
  console.log('📝 Content Opportunity Finder Starting...\n');
  console.log('Platform: Hacker News\n');

  // Fetch opportunities from Hacker News
  const opportunities = await scrapeHackerNews();
  console.log(`\n📊 Found ${opportunities.length} raw opportunities\n`);

  // Filter and score opportunities
  const scoredOpportunities = opportunities
    .filter(opp => opp.question && opp.question.length > 20)
    .map(opp => ({
      ...opp,
      relevanceScore: scoreRelevance(opp)
    }))
    .filter(opp => opp.relevanceScore >= 40)
    .sort((a, b) => b.relevanceScore - a.relevanceScore)
    .slice(0, 15);

  console.log(`🎯 ${scoredOpportunities.length} high-relevance opportunities\n`);

  // Generate answers for top opportunities
  for (const opp of scoredOpportunities) {
    console.log(`  → Generating answer for: ${opp.title?.slice(0, 50)}...`);
    opp.suggestedAnswer = await generateAnswer(opp);
    await sleep(500); // Rate limiting
  }

  // Save results
  await saveOpportunities(scoredOpportunities);

  // Export for GitHub Action
  const envFile = process.env.GITHUB_ENV;
  if (envFile) {
    const fsSync = await import('fs');
    fsSync.appendFileSync(envFile, `OPPORTUNITIES_FOUND=${scoredOpportunities.length}\n`);
  }

  // Summary
  console.log('\n📊 Summary:');
  console.log(`  Total opportunities: ${scoredOpportunities.length}`);
  console.log(`  Ask HN posts: ${scoredOpportunities.filter(o => o.type === 'ask_hn').length}`);
  console.log(`  Comments: ${scoredOpportunities.filter(o => o.type === 'comment').length}`);
  console.log(`  Stories: ${scoredOpportunities.filter(o => o.type === 'story').length}`);

  console.log('\n✨ Done!');
}

/**
 * Scrape Hacker News for content opportunities using Algolia API
 */
async function scrapeHackerNews() {
  console.log('🟠 Fetching from Hacker News API...');

  const opportunities = [];
  const oneWeekAgo = Math.floor(Date.now() / 1000) - (7 * 24 * 60 * 60);

  // Search for relevant questions and discussions
  for (const topic of SEARCH_TOPICS) {
    try {
      console.log(`  Searching: "${topic}"...`);

      // Search Ask HN posts (often questions seeking advice)
      const askUrl = `${HN_API}/search?query=${encodeURIComponent(topic)}&tags=ask_hn&numericFilters=created_at_i>${oneWeekAgo}&hitsPerPage=15`;
      const askResponse = await fetch(askUrl);
      const askData = await askResponse.json();

      if (askData.hits) {
        for (const hit of askData.hits) {
          const title = hit.title || '';
          const text = hit.story_text || '';

          // Prioritize posts with questions or seeking advice
          const isQuestion = title.includes('?') ||
                            title.toLowerCase().includes('how') ||
                            title.toLowerCase().includes('advice') ||
                            title.toLowerCase().includes('help');

          // Look for posts with low comment counts (unanswered opportunities)
          const hasOpportunity = (hit.num_comments || 0) < 15;

          if (isQuestion || hasOpportunity) {
            opportunities.push({
              platform: 'Hacker News',
              type: 'ask_hn',
              title: title,
              question: title,
              body: stripHtml(text).slice(0, 500),
              url: `https://news.ycombinator.com/item?id=${hit.objectID}`,
              author: hit.author || '[unknown]',
              engagement: hit.num_comments || 0,
              points: hit.points || 0,
              createdAt: new Date(hit.created_at_i * 1000).toISOString()
            });
          }
        }
      }

      // Search story posts
      const storyUrl = `${HN_API}/search?query=${encodeURIComponent(topic)}&tags=story&numericFilters=created_at_i>${oneWeekAgo}&hitsPerPage=10`;
      const storyResponse = await fetch(storyUrl);
      const storyData = await storyResponse.json();

      if (storyData.hits) {
        for (const hit of storyData.hits) {
          const title = hit.title || '';

          // Look for Show HN or discussions about these topics
          const isRelevant = title.toLowerCase().includes('show hn') ||
                            title.includes('?') ||
                            (hit.points || 0) > 20;

          if (isRelevant && (hit.num_comments || 0) < 20) {
            opportunities.push({
              platform: 'Hacker News',
              type: 'story',
              title: title,
              question: title,
              body: stripHtml(hit.story_text || '').slice(0, 500),
              url: `https://news.ycombinator.com/item?id=${hit.objectID}`,
              author: hit.author || '[unknown]',
              engagement: hit.num_comments || 0,
              points: hit.points || 0,
              createdAt: new Date(hit.created_at_i * 1000).toISOString()
            });
          }
        }
      }

      // Search comments for questions/pain points
      const commentUrl = `${HN_API}/search?query=${encodeURIComponent(topic)}&tags=comment&numericFilters=created_at_i>${oneWeekAgo}&hitsPerPage=10`;
      const commentResponse = await fetch(commentUrl);
      const commentData = await commentResponse.json();

      if (commentData.hits) {
        for (const hit of commentData.hits) {
          const text = hit.comment_text || '';
          const cleanText = stripHtml(text);

          // Look for comments asking questions
          const isQuestion = cleanText.includes('?') && cleanText.length > 50 && cleanText.length < 500;
          const hasKeywords = ['anyone', 'advice', 'help', 'how do', 'struggling', 'trying to'].some(kw =>
            cleanText.toLowerCase().includes(kw)
          );

          if (isQuestion && hasKeywords) {
            opportunities.push({
              platform: 'Hacker News',
              type: 'comment',
              title: `Comment on: ${hit.story_title || 'HN Discussion'}`,
              question: cleanText.slice(0, 300),
              body: cleanText,
              url: `https://news.ycombinator.com/item?id=${hit.objectID}`,
              parentUrl: hit.story_url || `https://news.ycombinator.com/item?id=${hit.story_id}`,
              author: hit.author || '[unknown]',
              engagement: 0,
              points: hit.points || 0,
              createdAt: new Date(hit.created_at_i * 1000).toISOString()
            });
          }
        }
      }

      await sleep(200); // Be nice to the API
    } catch (e) {
      console.log(`    Warning: Search failed for "${topic}": ${e.message}`);
    }
  }

  // Also fetch recent Ask HN posts generally
  try {
    console.log('  Fetching recent Ask HN posts...');
    const recentUrl = `${HN_API}/search?tags=ask_hn&numericFilters=created_at_i>${oneWeekAgo}&hitsPerPage=30`;
    const recentResponse = await fetch(recentUrl);
    const recentData = await recentResponse.json();

    if (recentData.hits) {
      for (const hit of recentData.hits) {
        const title = hit.title || '';
        const text = `${title} ${hit.story_text || ''}`.toLowerCase();

        // Filter for startup/sales related Ask HNs
        const businessKeywords = ['startup', 'saas', 'b2b', 'sales', 'customer', 'founder', 'business', 'product', 'market', 'revenue', 'gtm', 'hiring', 'first hire'];
        const isRelevant = businessKeywords.some(kw => text.includes(kw));

        if (isRelevant && (hit.num_comments || 0) < 20) {
          opportunities.push({
            platform: 'Hacker News',
            type: 'ask_hn',
            title: hit.title || '',
            question: hit.title || '',
            body: stripHtml(hit.story_text || '').slice(0, 500),
            url: `https://news.ycombinator.com/item?id=${hit.objectID}`,
            author: hit.author || '[unknown]',
            engagement: hit.num_comments || 0,
            points: hit.points || 0,
            createdAt: new Date(hit.created_at_i * 1000).toISOString()
          });
        }
      }
    }
  } catch (e) {
    console.log(`    Warning: Recent Ask HN fetch failed: ${e.message}`);
  }

  // Deduplicate by URL
  const unique = [...new Map(opportunities.map(o => [o.url, o])).values()];
  console.log(`  Found ${unique.length} unique opportunities`);

  return unique;
}

/**
 * Strip HTML tags from text
 */
function stripHtml(html) {
  return html
    .replace(/<[^>]*>/g, ' ')
    .replace(/&nbsp;/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#x27;/g, "'")
    .replace(/\s+/g, ' ')
    .trim();
}

/**
 * Score opportunity relevance
 */
function scoreRelevance(opp) {
  let score = 0;
  const text = `${opp.title} ${opp.question} ${opp.body || ''}`.toLowerCase();

  // High-value keywords
  const highValue = ['first sales', 'icp', 'ideal customer', 'founder', 'technical founder', 'b2b saas', 'enterprise sales', 'gtm', 'go to market'];
  const mediumValue = ['startup', 'sales', 'strategy', 'process', 'hiring', 'advice', 'customer', 'revenue'];

  for (const kw of highValue) {
    if (text.includes(kw)) score += 20;
  }

  for (const kw of mediumValue) {
    if (text.includes(kw)) score += 10;
  }

  // Bonus for questions
  if (text.includes('?')) score += 15;
  if (text.includes('how do')) score += 10;
  if (text.includes('advice')) score += 10;
  if (text.includes('struggling')) score += 10;
  if (text.includes('help')) score += 5;

  // Bonus for Ask HN posts (higher visibility)
  if (opp.type === 'ask_hn') score += 15;

  // Bonus for low engagement (more opportunity to contribute)
  if ((opp.engagement || 0) < 5) score += 20;
  else if ((opp.engagement || 0) < 10) score += 10;

  // Bonus for recent posts
  const ageHours = (Date.now() - new Date(opp.createdAt).getTime()) / (1000 * 60 * 60);
  if (ageHours < 24) score += 15;
  else if (ageHours < 48) score += 10;

  return score;
}

/**
 * Generate suggested answer using Claude
 */
async function generateAnswer(opp) {
  const prompt = `You are Brandon Geter, founder of Andru (Revenue Intelligence for B2B SaaS founders) with 9 years of SaaS sales experience.

Generate a helpful, genuine answer to this Hacker News question. The answer should:
1. Be genuinely helpful (not a pitch)
2. Share specific, actionable advice from your experience
3. Include a framework or specific steps when relevant
4. Match the HN community tone: direct, technical, substance-focused
5. NOT mention Andru or any product - this is purely helpful advice

## QUESTION
Platform: Hacker News
Type: ${opp.type}
Title: ${opp.title}
${opp.body ? `Body: ${opp.body}` : ''}

## YOUR BACKGROUND
- 9 years SaaS sales (Apttus, Sumo Logic, Graphite, OpsLevel)
- Generated $30M+ in pipeline
- Hired/trained 20+ sellers
- Helped technical founders translate product to business value

## HN COMMUNITY GUIDELINES
- Be direct, get to the point
- Share real experience and data when possible
- Avoid marketing speak or fluff
- Technical audience appreciates specifics
- It's okay to disagree respectfully if you have experience to back it up

Generate the answer (150-300 words). No intro like "Great question!" - just dive into substantive advice.`;

  try {
    const response = await anthropic.messages.create({
      model: 'claude-sonnet-4-20250514',
      max_tokens: 400,
      messages: [{ role: 'user', content: prompt }]
    });

    return response.content[0].text.trim();
  } catch (error) {
    console.error('    Error generating answer:', error.message);
    return null;
  }
}

/**
 * Save opportunities to file
 */
async function saveOpportunities(opportunities) {
  const outputDir = path.join(OUTPUT_ROOT, 'content-opportunities/daily');
  await fs.mkdir(outputDir, { recursive: true });

  const date = new Date().toISOString().split('T')[0];
  const filename = `${date}.json`;
  const filepath = path.join(outputDir, filename);

  const output = {
    date,
    platform: 'Hacker News',
    totalOpportunities: opportunities.length,
    byType: {
      ask_hn: opportunities.filter(o => o.type === 'ask_hn').length,
      story: opportunities.filter(o => o.type === 'story').length,
      comment: opportunities.filter(o => o.type === 'comment').length
    },
    opportunities
  };

  await fs.writeFile(filepath, JSON.stringify(output, null, 2), 'utf-8');
  console.log(`\n💾 Saved: ${filename}`);
}

/**
 * Sleep helper
 */
function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

// Run
main().catch(error => {
  console.error('Fatal error:', error);
  process.exit(1);
});

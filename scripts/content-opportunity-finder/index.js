/**
 * Content Opportunity Finder
 * Scrapes Quora, Reddit, and LinkedIn for unanswered questions in your domain
 */

import { chromium } from 'playwright';
import Anthropic from '@anthropic-ai/sdk';
import fs from 'fs/promises';
import path from 'path';

const anthropic = new Anthropic();

// Configuration
const OUTPUT_ROOT = process.env.OUTPUT_ROOT || process.cwd();
const PLATFORMS = (process.env.PLATFORMS || 'quora,reddit,linkedin').split(',').map(p => p.trim());

// Topics to search for
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
  'product market fit sales'
];

/**
 * Main execution
 */
async function main() {
  console.log('📝 Content Opportunity Finder Starting...\n');
  console.log(`Platforms: ${PLATFORMS.join(', ')}\n`);

  const allOpportunities = [];

  // Scrape each platform
  if (PLATFORMS.includes('reddit')) {
    const redditOpps = await scrapeReddit();
    allOpportunities.push(...redditOpps);
  }

  if (PLATFORMS.includes('quora')) {
    const quoraOpps = await scrapeQuora();
    allOpportunities.push(...quoraOpps);
  }

  if (PLATFORMS.includes('linkedin')) {
    const linkedinOpps = await scrapeLinkedInQuestions();
    allOpportunities.push(...linkedinOpps);
  }

  console.log(`\n📊 Found ${allOpportunities.length} raw opportunities\n`);

  // Filter and score opportunities
  const scoredOpportunities = allOpportunities
    .filter(opp => opp.question && opp.question.length > 20)
    .map(opp => ({
      ...opp,
      relevanceScore: scoreRelevance(opp)
    }))
    .filter(opp => opp.relevanceScore >= 50)
    .sort((a, b) => b.relevanceScore - a.relevanceScore)
    .slice(0, 15);

  console.log(`🎯 ${scoredOpportunities.length} high-relevance opportunities\n`);

  // Generate answers for top opportunities
  for (const opp of scoredOpportunities) {
    console.log(`  → Generating answer for: ${opp.title?.slice(0, 50)}...`);
    opp.suggestedAnswer = await generateAnswer(opp);
  }

  // Save results
  await saveOpportunities(scoredOpportunities);

  // Summary
  console.log('\n📊 Summary by Platform:');
  const byPlatform = {};
  for (const opp of scoredOpportunities) {
    byPlatform[opp.platform] = (byPlatform[opp.platform] || 0) + 1;
  }
  for (const [platform, count] of Object.entries(byPlatform)) {
    console.log(`  ${platform}: ${count}`);
  }

  console.log('\n✨ Done!');
}

/**
 * Scrape Reddit for questions
 */
async function scrapeReddit() {
  console.log('🔴 Scraping Reddit...');

  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  const opportunities = [];

  const subreddits = ['startups', 'sales', 'SaaS', 'Entrepreneur', 'smallbusiness'];

  try {
    for (const subreddit of subreddits) {
      // Search within subreddit
      for (const topic of SEARCH_TOPICS.slice(0, 3)) {
        const searchUrl = `https://old.reddit.com/r/${subreddit}/search?q=${encodeURIComponent(topic)}&restrict_sr=on&sort=new&t=week`;

        try {
          await page.goto(searchUrl, { waitUntil: 'domcontentloaded', timeout: 15000 });
          await page.waitForTimeout(1500);

          const posts = await page.$$eval('.thing.link:not(.promoted)', (els) => {
            return els.slice(0, 5).map(el => {
              const titleEl = el.querySelector('a.title');
              const authorEl = el.querySelector('.author');
              const commentsEl = el.querySelector('.comments');
              const scoreEl = el.querySelector('.score.unvoted');

              return {
                title: titleEl?.textContent?.trim() || '',
                url: titleEl?.href || '',
                author: authorEl?.textContent?.trim() || '',
                comments: parseInt(commentsEl?.textContent?.match(/(\d+)/)?.[1] || '0'),
                score: parseInt(scoreEl?.textContent?.replace(/[^0-9-]/g, '') || '0')
              };
            });
          });

          for (const post of posts) {
            // Prioritize posts with questions and low comment counts (unanswered)
            if ((post.title.includes('?') || post.title.toLowerCase().includes('how') ||
                 post.title.toLowerCase().includes('what') || post.title.toLowerCase().includes('advice')) &&
                post.comments < 10) {
              opportunities.push({
                platform: 'Reddit',
                subreddit: `r/${subreddit}`,
                title: post.title,
                question: post.title,
                url: post.url,
                author: post.author,
                engagement: post.comments,
                score: post.score
              });
            }
          }
        } catch (e) {
          // Continue on error
        }

        await page.waitForTimeout(1000);
      }
    }
  } catch (error) {
    console.error('  Error scraping Reddit:', error.message);
  } finally {
    await browser.close();
  }

  console.log(`  Found ${opportunities.length} Reddit opportunities`);
  return opportunities;
}

/**
 * Scrape Quora for questions
 */
async function scrapeQuora() {
  console.log('🟠 Scraping Quora...');

  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  const opportunities = [];

  try {
    for (const topic of SEARCH_TOPICS.slice(0, 5)) {
      const searchUrl = `https://www.quora.com/search?q=${encodeURIComponent(topic)}&type=question`;

      try {
        await page.goto(searchUrl, { waitUntil: 'domcontentloaded', timeout: 20000 });
        await page.waitForTimeout(2000);

        // Scroll to load more
        await page.evaluate(() => window.scrollTo(0, 1000));
        await page.waitForTimeout(1500);

        const questions = await page.$$eval('[class*="q-box"]', (els) => {
          return els.slice(0, 10).map(el => {
            const linkEl = el.querySelector('a[href*="/"]');
            const textEl = el.querySelector('span');
            const answersEl = el.querySelector('[class*="answer"]');

            const text = textEl?.textContent?.trim() || '';
            const href = linkEl?.href || '';

            // Only get questions (contain ?)
            if (!text.includes('?')) return null;

            return {
              title: text,
              url: href.startsWith('http') ? href : `https://www.quora.com${href}`,
              answers: parseInt(answersEl?.textContent?.match(/(\d+)/)?.[1] || '0')
            };
          }).filter(Boolean);
        });

        for (const q of questions) {
          if (q && q.title && q.answers < 5) {
            opportunities.push({
              platform: 'Quora',
              title: q.title,
              question: q.title,
              url: q.url,
              engagement: q.answers
            });
          }
        }
      } catch (e) {
        // Continue on error
      }

      await page.waitForTimeout(1500);
    }
  } catch (error) {
    console.error('  Error scraping Quora:', error.message);
  } finally {
    await browser.close();
  }

  console.log(`  Found ${opportunities.length} Quora opportunities`);
  return opportunities;
}

/**
 * Scrape LinkedIn for polls and questions
 */
async function scrapeLinkedInQuestions() {
  console.log('🔵 Scraping LinkedIn (public search)...');

  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  const opportunities = [];

  try {
    // LinkedIn public search for relevant discussions
    const searchTerms = ['startup sales advice', 'first sales hire', 'ICP help'];

    for (const term of searchTerms) {
      const searchUrl = `https://www.linkedin.com/search/results/content/?keywords=${encodeURIComponent(term)}&origin=GLOBAL_SEARCH_HEADER&sortBy=%22date_posted%22`;

      try {
        await page.goto(searchUrl, { waitUntil: 'domcontentloaded', timeout: 15000 });
        await page.waitForTimeout(2000);

        // Note: LinkedIn heavily restricts scraping without login
        // This will capture limited public content
        const posts = await page.$$eval('.search-result', (els) => {
          return els.slice(0, 5).map(el => {
            const textEl = el.querySelector('.search-result__snippet');
            const linkEl = el.querySelector('a');

            return {
              text: textEl?.textContent?.trim() || '',
              url: linkEl?.href || ''
            };
          });
        }).catch(() => []);

        for (const post of posts) {
          if (post.text && (post.text.includes('?') || post.text.toLowerCase().includes('advice'))) {
            opportunities.push({
              platform: 'LinkedIn',
              title: post.text.slice(0, 100),
              question: post.text,
              url: post.url
            });
          }
        }
      } catch (e) {
        // LinkedIn may block - continue
      }

      await page.waitForTimeout(2000);
    }
  } catch (error) {
    console.error('  Error scraping LinkedIn:', error.message);
  } finally {
    await browser.close();
  }

  console.log(`  Found ${opportunities.length} LinkedIn opportunities`);
  return opportunities;
}

/**
 * Score opportunity relevance
 */
function scoreRelevance(opp) {
  let score = 0;
  const text = `${opp.title} ${opp.question}`.toLowerCase();

  // High-value keywords
  const highValue = ['first sales', 'icp', 'ideal customer', 'founder', 'technical founder', 'b2b saas', 'enterprise sales', 'gtm'];
  const mediumValue = ['startup', 'sales', 'strategy', 'process', 'hiring', 'advice'];

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

  // Bonus for low engagement (more opportunity)
  if ((opp.engagement || 0) < 3) score += 20;
  if ((opp.engagement || 0) < 5) score += 10;

  // Platform bonuses
  if (opp.platform === 'Reddit' && opp.subreddit?.includes('startups')) score += 10;
  if (opp.platform === 'Quora') score += 5;

  return score;
}

/**
 * Generate suggested answer using Claude
 */
async function generateAnswer(opp) {
  const prompt = `You are Brandon Geter, founder of Andru (Revenue Intelligence for B2B SaaS founders) with 9 years of SaaS sales experience.

Generate a helpful, genuine answer to this question. The answer should:
1. Be genuinely helpful (not a pitch)
2. Share specific, actionable advice from your experience
3. Include a framework or specific steps when relevant
4. Be appropriate for the platform (${opp.platform})
5. NOT mention Andru or any product

## QUESTION
Platform: ${opp.platform}
${opp.subreddit ? `Subreddit: ${opp.subreddit}` : ''}
Question: ${opp.question}

## YOUR BACKGROUND
- 9 years SaaS sales (Apttus, Sumo Logic, Graphite, OpsLevel)
- Generated $30M+ in pipeline
- Hired/trained 20+ sellers
- Helped technical founders translate product to business value

## PLATFORM GUIDELINES
- Reddit: Be casual, genuine, share experience. No self-promo.
- Quora: Be comprehensive, authoritative. Can be longer.
- LinkedIn: Professional, thought-leadership tone.

Generate the answer (200-400 words). No intro like "Great question!" - just dive in.`;

  try {
    const response = await anthropic.messages.create({
      model: 'claude-sonnet-4-20250514',
      max_tokens: 500,
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
    totalOpportunities: opportunities.length,
    byPlatform: {
      reddit: opportunities.filter(o => o.platform === 'Reddit').length,
      quora: opportunities.filter(o => o.platform === 'Quora').length,
      linkedin: opportunities.filter(o => o.platform === 'LinkedIn').length
    },
    opportunities
  };

  await fs.writeFile(filepath, JSON.stringify(output, null, 2), 'utf-8');
  console.log(`\n💾 Saved: ${filename}`);
}

// Run
main().catch(error => {
  console.error('Fatal error:', error);
  process.exit(1);
});

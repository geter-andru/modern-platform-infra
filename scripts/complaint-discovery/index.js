/**
 * Complaint Discovery Agent
 * Uses Hacker News API to find user complaints and pain points
 * Stores in Supabase for pattern analysis
 */

import Anthropic from '@anthropic-ai/sdk';
import { createClient } from '@supabase/supabase-js';

const anthropic = new Anthropic();

// Configuration
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_KEY;

if (!supabaseUrl || !supabaseKey) {
  console.error('❌ SUPABASE_URL and SUPABASE_SERVICE_KEY are required');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

// Complaint indicator keywords
const COMPLAINT_KEYWORDS = [
  'frustrated', 'hate', 'struggling', 'waste', 'failed', 'impossible',
  'nightmare', 'terrible', 'awful', 'broken', 'useless', 'annoying',
  'anyone else', 'help me', 'advice needed', 'what am i doing wrong',
  'months building', 'no customers', 'no sales', 'can\'t figure out',
  'stuck on', 'burned out', 'giving up', 'should i pivot',
  'hard to find', 'impossible to', 'wasted time', 'mistake'
];

// Search terms for ICP-relevant content
const SEARCH_TERMS = [
  'first sales hire',
  'startup sales',
  'founder sales',
  'B2B sales',
  'no customers',
  'finding customers',
  'product market fit',
  'ICP ideal customer',
  'validate startup',
  'sales process'
];

// HN Algolia API base
const HN_API = 'https://hn.algolia.com/api/v1';

/**
 * Main execution
 */
async function main() {
  console.log('🔍 Complaint Discovery Agent Starting...\n');
  console.log('Platform: Hacker News\n');

  // Create scrape run record
  const { data: scrapeRun } = await supabase
    .from('complaint_scrape_runs')
    .insert({
      platform: 'hacker_news',
      search_terms: SEARCH_TERMS,
      subreddits_scraped: ['Hacker News'],
      status: 'running'
    })
    .select()
    .single();

  const runId = scrapeRun?.id;

  try {
    // Fetch from Hacker News
    const posts = await scrapeHackerNews();
    console.log(`\n📋 Found ${posts.length} potential complaint posts\n`);

    // Analyze each post with Claude
    const complaints = [];
    for (const post of posts) {
      console.log(`  → Analyzing: ${post.title.slice(0, 50)}...`);
      const analysis = await analyzePost(post);

      if (analysis && analysis.isComplaint) {
        complaints.push({
          ...post,
          ...analysis
        });
      }

      // Rate limiting for Claude API
      await sleep(500);
    }

    console.log(`\n🎯 Identified ${complaints.length} valid complaints\n`);

    // Save to Supabase
    let newCount = 0;
    let highPainCount = 0;

    for (const complaint of complaints) {
      const { error } = await supabase
        .from('complaints')
        .upsert({
          platform: 'hacker_news',
          subreddit: 'Hacker News',
          post_url: complaint.url,
          post_id: complaint.postId,
          author: complaint.author,
          title: complaint.title,
          raw_text: complaint.content,
          extracted_problem: complaint.extractedProblem,
          exact_phrases: complaint.exactPhrases,
          pain_score: complaint.painScore,
          category: complaint.category,
          upvotes: complaint.upvotes,
          comments_count: complaint.comments,
          is_processed: false
        }, {
          onConflict: 'post_url'
        });

      if (!error) {
        newCount++;
        if (complaint.painScore >= 7) highPainCount++;
      }
    }

    // Update scrape run
    await supabase
      .from('complaint_scrape_runs')
      .update({
        status: 'completed',
        posts_found: posts.length,
        complaints_identified: complaints.length,
        new_complaints: newCount,
        completed_at: new Date().toISOString()
      })
      .eq('id', runId);

    // Summary
    console.log(`\n📊 Summary:`);
    console.log(`  Posts scraped: ${posts.length}`);
    console.log(`  Complaints identified: ${complaints.length}`);
    console.log(`  New complaints saved: ${newCount}`);
    console.log(`  High pain (7+): ${highPainCount}`);

    // Export for GitHub Action
    const fs = await import('fs');
    const envFile = process.env.GITHUB_ENV;
    if (envFile) {
      fs.appendFileSync(envFile, `NEW_COMPLAINTS=${newCount}\n`);
      fs.appendFileSync(envFile, `HIGH_PAIN_COUNT=${highPainCount}\n`);
    }

    console.log('\n✨ Done!');

  } catch (error) {
    console.error('Fatal error:', error);

    if (runId) {
      await supabase
        .from('complaint_scrape_runs')
        .update({
          status: 'failed',
          error_message: error.message,
          completed_at: new Date().toISOString()
        })
        .eq('id', runId);
    }

    process.exit(1);
  }
}

/**
 * Scrape Hacker News for complaints using Algolia API
 */
async function scrapeHackerNews() {
  console.log('🟠 Fetching from Hacker News API...');

  const posts = [];
  const oneWeekAgo = Math.floor(Date.now() / 1000) - (7 * 24 * 60 * 60);

  // Search for relevant posts
  for (const term of SEARCH_TERMS) {
    try {
      console.log(`  Searching: "${term}"...`);

      // Search stories
      const storyUrl = `${HN_API}/search?query=${encodeURIComponent(term)}&tags=story&numericFilters=created_at_i>${oneWeekAgo}&hitsPerPage=20`;
      const storyResponse = await fetch(storyUrl);
      const storyData = await storyResponse.json();

      if (storyData.hits) {
        for (const hit of storyData.hits) {
          const text = `${hit.title || ''} ${hit.story_text || ''}`.toLowerCase();

          // Check for complaint indicators or just add if it's a relevant "Ask HN"
          const hasComplaint = COMPLAINT_KEYWORDS.some(kw => text.includes(kw));
          const isAskHN = hit.title?.toLowerCase().startsWith('ask hn');

          if (hasComplaint || isAskHN) {
            posts.push({
              postId: `hn_${hit.objectID}`,
              title: hit.title || '',
              url: `https://news.ycombinator.com/item?id=${hit.objectID}`,
              author: hit.author || '[unknown]',
              upvotes: hit.points || 0,
              comments: hit.num_comments || 0,
              content: hit.story_text || ''
            });
          }
        }
      }

      // Also search comments for pain points
      const commentUrl = `${HN_API}/search?query=${encodeURIComponent(term)}&tags=comment&numericFilters=created_at_i>${oneWeekAgo}&hitsPerPage=15`;
      const commentResponse = await fetch(commentUrl);
      const commentData = await commentResponse.json();

      if (commentData.hits) {
        for (const hit of commentData.hits) {
          const text = (hit.comment_text || '').toLowerCase();

          if (COMPLAINT_KEYWORDS.some(kw => text.includes(kw)) && text.length > 100) {
            posts.push({
              postId: `hn_comment_${hit.objectID}`,
              title: `Comment on: ${hit.story_title || 'HN Discussion'}`,
              url: `https://news.ycombinator.com/item?id=${hit.objectID}`,
              author: hit.author || '[unknown]',
              upvotes: hit.points || 0,
              comments: 0,
              content: stripHtml(hit.comment_text || '').slice(0, 2000)
            });
          }
        }
      }

      await sleep(200); // Be nice to the API
    } catch (e) {
      console.log(`    Warning: Search failed for "${term}": ${e.message}`);
    }
  }

  // Also get recent "Ask HN" posts (often contain pain points)
  try {
    console.log('  Fetching recent Ask HN posts...');
    const askUrl = `${HN_API}/search?tags=ask_hn&numericFilters=created_at_i>${oneWeekAgo}&hitsPerPage=30`;
    const askResponse = await fetch(askUrl);
    const askData = await askResponse.json();

    if (askData.hits) {
      for (const hit of askData.hits) {
        const text = `${hit.title || ''} ${hit.story_text || ''}`.toLowerCase();

        // Filter for startup/business related Ask HNs
        const businessKeywords = ['startup', 'saas', 'b2b', 'sales', 'customer', 'founder', 'business', 'product', 'market', 'revenue'];
        const isRelevant = businessKeywords.some(kw => text.includes(kw));

        if (isRelevant) {
          posts.push({
            postId: `hn_${hit.objectID}`,
            title: hit.title || '',
            url: `https://news.ycombinator.com/item?id=${hit.objectID}`,
            author: hit.author || '[unknown]',
            upvotes: hit.points || 0,
            comments: hit.num_comments || 0,
            content: stripHtml(hit.story_text || '').slice(0, 2000)
          });
        }
      }
    }
  } catch (e) {
    console.log(`    Warning: Ask HN fetch failed: ${e.message}`);
  }

  // Deduplicate by URL
  const unique = [...new Map(posts.map(p => [p.url, p])).values()];
  console.log(`  Found ${unique.length} unique posts`);

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
 * Analyze a post with Claude
 */
async function analyzePost(post) {
  const prompt = `Analyze this Hacker News post/comment to determine if it expresses a genuine complaint or pain point relevant to B2B SaaS founders.

## POST
Title: ${post.title}
Content: ${post.content || '(no body text)'}
Upvotes: ${post.upvotes}
Comments: ${post.comments}

## ANALYSIS REQUIRED
1. Is this a genuine complaint/pain point? (not just a question or discussion)
2. If yes, extract:
   - The core problem being expressed
   - EXACT phrases they used (verbatim quotes that capture the pain)
   - Pain score 1-10 (how intense is the frustration?)
   - Category: validation, sales, product, hiring, marketing, fundraising, operations, other

## OUTPUT FORMAT
Respond in JSON only:
{
  "isComplaint": true/false,
  "extractedProblem": "One sentence describing the core problem",
  "exactPhrases": ["phrase 1", "phrase 2", "phrase 3"],
  "painScore": 7,
  "category": "sales",
  "reasoning": "Brief explanation"
}

If not a complaint, just return: {"isComplaint": false}`;

  try {
    const response = await anthropic.messages.create({
      model: 'claude-sonnet-4-20250514',
      max_tokens: 500,
      messages: [{ role: 'user', content: prompt }]
    });

    const text = response.content[0].text;
    const jsonMatch = text.match(/\{[\s\S]*\}/);

    if (jsonMatch) {
      return JSON.parse(jsonMatch[0]);
    }

    return null;

  } catch (error) {
    console.error(`    Error analyzing post: ${error.message}`);
    return null;
  }
}

/**
 * Sleep helper
 */
function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

// Run
main().catch(console.error);

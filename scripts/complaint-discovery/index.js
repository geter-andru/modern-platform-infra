/**
 * Complaint Discovery Agent
 * Uses Reddit's official API to find user complaints and pain points
 * Stores in Supabase for pattern analysis
 */

import Anthropic from '@anthropic-ai/sdk';
import { createClient } from '@supabase/supabase-js';

const anthropic = new Anthropic();

// Configuration
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_KEY;
const SUBREDDITS = (process.env.SUBREDDITS || 'Entrepreneur,SaaS,startups,sales').split(',').map(s => s.trim());

// Reddit API credentials (use app-only auth)
const REDDIT_CLIENT_ID = process.env.REDDIT_CLIENT_ID;
const REDDIT_CLIENT_SECRET = process.env.REDDIT_CLIENT_SECRET;

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
  'stuck on', 'burned out', 'giving up', 'should i pivot'
];

// Search terms for ICP-relevant complaints
const SEARCH_TERMS = [
  'first sales hire',
  'no customers startup',
  'validate idea',
  'founder led sales',
  'B2B sales struggle',
  'ICP ideal customer',
  'product market fit',
  'startup sales process'
];

let redditAccessToken = null;

/**
 * Get Reddit access token using app-only (client credentials) flow
 */
async function getRedditToken() {
  if (!REDDIT_CLIENT_ID || !REDDIT_CLIENT_SECRET) {
    console.log('⚠️  Reddit API credentials not provided, using public JSON endpoints');
    return null;
  }

  try {
    const auth = Buffer.from(`${REDDIT_CLIENT_ID}:${REDDIT_CLIENT_SECRET}`).toString('base64');

    const response = await fetch('https://www.reddit.com/api/v1/access_token', {
      method: 'POST',
      headers: {
        'Authorization': `Basic ${auth}`,
        'Content-Type': 'application/x-www-form-urlencoded',
        'User-Agent': 'ComplaintDiscovery/1.0'
      },
      body: 'grant_type=client_credentials'
    });

    if (!response.ok) {
      console.log('⚠️  Reddit OAuth failed, using public endpoints');
      return null;
    }

    const data = await response.json();
    console.log('✅ Reddit API authenticated');
    return data.access_token;
  } catch (error) {
    console.log('⚠️  Reddit auth error:', error.message);
    return null;
  }
}

/**
 * Fetch from Reddit API or public JSON endpoint
 */
async function redditFetch(url) {
  const headers = {
    'User-Agent': 'ComplaintDiscovery/1.0 (by /u/andru_platform)'
  };

  if (redditAccessToken) {
    // Use OAuth API
    const apiUrl = url.replace('https://www.reddit.com', 'https://oauth.reddit.com');
    headers['Authorization'] = `Bearer ${redditAccessToken}`;

    const response = await fetch(apiUrl, { headers });
    if (response.ok) {
      return response.json();
    }
  }

  // Fallback to public JSON endpoint
  const jsonUrl = url.endsWith('.json') ? url : `${url}.json`;
  const response = await fetch(jsonUrl, { headers });

  if (!response.ok) {
    throw new Error(`Reddit API error: ${response.status}`);
  }

  return response.json();
}

/**
 * Main execution
 */
async function main() {
  console.log('🔍 Complaint Discovery Agent Starting...\n');
  console.log(`Subreddits: ${SUBREDDITS.join(', ')}\n`);

  // Get Reddit token if credentials provided
  redditAccessToken = await getRedditToken();

  // Create scrape run record
  const { data: scrapeRun } = await supabase
    .from('complaint_scrape_runs')
    .insert({
      platform: 'reddit',
      search_terms: SEARCH_TERMS,
      subreddits_scraped: SUBREDDITS,
      status: 'running'
    })
    .select()
    .single();

  const runId = scrapeRun?.id;

  try {
    // Scrape Reddit using API
    const posts = await scrapeReddit();
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

      // Rate limiting
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
          platform: 'reddit',
          subreddit: complaint.subreddit,
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

    // Set environment variables for GitHub Action
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

    // Update scrape run with error
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
 * Scrape Reddit for complaints using API
 */
async function scrapeReddit() {
  console.log('🔴 Scraping Reddit via API...');

  const posts = [];

  try {
    for (const subreddit of SUBREDDITS) {
      console.log(`  Scraping r/${subreddit}...`);

      // Search within subreddit for complaint-related posts
      for (const term of SEARCH_TERMS.slice(0, 4)) {
        try {
          const searchUrl = `https://www.reddit.com/r/${subreddit}/search.json?q=${encodeURIComponent(term)}&restrict_sr=on&sort=new&t=month&limit=15`;

          const data = await redditFetch(searchUrl);

          if (data?.data?.children) {
            for (const child of data.data.children) {
              const post = child.data;
              posts.push({
                subreddit: `r/${subreddit}`,
                postId: post.name,
                title: post.title || '',
                url: `https://www.reddit.com${post.permalink}`,
                author: post.author || '[deleted]',
                upvotes: post.ups || 0,
                comments: post.num_comments || 0,
                content: (post.selftext || '').slice(0, 2000)
              });
            }
          }

          await sleep(1000); // Rate limit between requests
        } catch (e) {
          console.log(`    Warning: Could not search "${term}" in r/${subreddit}: ${e.message}`);
        }
      }

      // Also check "new" posts
      try {
        const newUrl = `https://www.reddit.com/r/${subreddit}/new.json?limit=25`;
        const data = await redditFetch(newUrl);

        if (data?.data?.children) {
          for (const child of data.data.children) {
            const post = child.data;
            const text = `${post.title} ${post.selftext}`.toLowerCase();

            // Filter for complaint indicators
            const hasComplaintKeyword = COMPLAINT_KEYWORDS.some(kw => text.includes(kw));

            if (hasComplaintKeyword) {
              posts.push({
                subreddit: `r/${subreddit}`,
                postId: post.name,
                title: post.title || '',
                url: `https://www.reddit.com${post.permalink}`,
                author: post.author || '[deleted]',
                upvotes: post.ups || 0,
                comments: post.num_comments || 0,
                content: (post.selftext || '').slice(0, 2000)
              });
            }
          }
        }

        await sleep(1000);
      } catch (e) {
        console.log(`    Warning: Could not scrape new posts in r/${subreddit}: ${e.message}`);
      }
    }

  } catch (error) {
    console.error('Error scraping Reddit:', error.message);
  }

  // Deduplicate by URL
  const unique = [...new Map(posts.map(p => [p.url, p])).values()];
  console.log(`  Found ${unique.length} unique posts`);

  return unique;
}

/**
 * Analyze a post with Claude
 */
async function analyzePost(post) {
  const prompt = `Analyze this Reddit post to determine if it expresses a genuine complaint or pain point relevant to B2B SaaS founders.

## POST
Subreddit: ${post.subreddit}
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

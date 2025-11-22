/**
 * Complaint Discovery Agent
 * Scrapes Reddit for user complaints and pain points
 * Stores in Supabase for pattern analysis
 */

import { chromium } from 'playwright';
import Anthropic from '@anthropic-ai/sdk';
import { createClient } from '@supabase/supabase-js';

const anthropic = new Anthropic();

// Configuration
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_KEY;
const SUBREDDITS = (process.env.SUBREDDITS || 'Entrepreneur,SaaS,startups,sales').split(',').map(s => s.trim());

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

/**
 * Main execution
 */
async function main() {
  console.log('🔍 Complaint Discovery Agent Starting...\n');
  console.log(`Subreddits: ${SUBREDDITS.join(', ')}\n`);

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
    // Scrape Reddit
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
 * Scrape Reddit for complaints
 */
async function scrapeReddit() {
  console.log('🔴 Scraping Reddit...');

  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  const posts = [];

  try {
    for (const subreddit of SUBREDDITS) {
      console.log(`  Scraping r/${subreddit}...`);

      // Search within subreddit for complaint-related posts
      for (const term of SEARCH_TERMS.slice(0, 4)) {
        const searchUrl = `https://old.reddit.com/r/${subreddit}/search?q=${encodeURIComponent(term)}&restrict_sr=on&sort=new&t=month`;

        try {
          await page.goto(searchUrl, { waitUntil: 'domcontentloaded', timeout: 20000 });
          await page.waitForTimeout(1500);

          const searchResults = await extractPosts(page, subreddit);
          posts.push(...searchResults);

        } catch (e) {
          console.log(`    Warning: Could not search "${term}" in r/${subreddit}`);
        }

        await page.waitForTimeout(1000);
      }

      // Also check "new" posts
      try {
        await page.goto(`https://old.reddit.com/r/${subreddit}/new/`, {
          waitUntil: 'domcontentloaded',
          timeout: 20000
        });
        await page.waitForTimeout(1500);

        const newPosts = await extractPosts(page, subreddit);

        // Filter for complaint indicators
        const complaintPosts = newPosts.filter(post => {
          const text = `${post.title} ${post.content}`.toLowerCase();
          return COMPLAINT_KEYWORDS.some(kw => text.includes(kw));
        });

        posts.push(...complaintPosts);

      } catch (e) {
        console.log(`    Warning: Could not scrape new posts in r/${subreddit}`);
      }
    }

  } finally {
    await browser.close();
  }

  // Deduplicate by URL
  const unique = [...new Map(posts.map(p => [p.url, p])).values()];
  console.log(`  Found ${unique.length} unique posts`);

  return unique;
}

/**
 * Extract posts from a Reddit page
 */
async function extractPosts(page, subreddit) {
  return page.$$eval('.thing.link:not(.promoted)', (els, sub) => {
    return els.slice(0, 15).map(el => {
      const titleEl = el.querySelector('a.title');
      const authorEl = el.querySelector('.author');
      const scoreEl = el.querySelector('.score.unvoted');
      const commentsEl = el.querySelector('.comments');
      const selfTextEl = el.querySelector('.expando .usertext-body');

      return {
        subreddit: sub,
        postId: el.getAttribute('data-fullname'),
        title: titleEl?.textContent?.trim() || '',
        url: titleEl?.href || '',
        author: authorEl?.textContent?.trim() || '[deleted]',
        upvotes: parseInt(scoreEl?.textContent?.replace(/[^0-9-]/g, '') || '0'),
        comments: parseInt(commentsEl?.textContent?.match(/(\d+)/)?.[1] || '0'),
        content: selfTextEl?.textContent?.trim()?.slice(0, 2000) || ''
      };
    });
  }, subreddit);
}

/**
 * Analyze a post with Claude
 */
async function analyzePost(post) {
  const prompt = `Analyze this Reddit post to determine if it expresses a genuine complaint or pain point relevant to B2B SaaS founders.

## POST
Subreddit: r/${post.subreddit}
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

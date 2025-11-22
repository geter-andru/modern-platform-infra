/**
 * LinkedIn Feed Monitor
 * Scrapes LinkedIn feed for buying signals and generates engagement suggestions
 */

import { chromium } from 'playwright';
import Anthropic from '@anthropic-ai/sdk';
import fs from 'fs/promises';
import path from 'path';

const anthropic = new Anthropic();

// Configuration
const LINKEDIN_SESSION_COOKIE = process.env.LINKEDIN_SESSION_COOKIE;
const OUTPUT_ROOT = process.env.OUTPUT_ROOT || process.cwd();

// Signal keywords to look for
const BUYING_SIGNALS = {
  funding: ['just raised', 'excited to announce', 'closed our', 'series a', 'series b', 'seed round', 'funding'],
  hiring: ['hiring our first', 'building the sales team', 'looking for', 'growing the team', 'first sales hire', 'head of sales'],
  pain: ['struggling with', 'anyone recommend', 'looking for advice', 'frustrated with', 'challenge we face'],
  milestone: ['just hit', 'reached', 'milestone', 'crossed', 'celebrating'],
  change: ['joining', 'new role', 'excited to start', 'next chapter', 'leaving']
};

/**
 * Main execution
 */
async function main() {
  console.log('📡 LinkedIn Feed Monitor Starting...\n');

  if (!LINKEDIN_SESSION_COOKIE) {
    console.error('❌ LINKEDIN_SESSION_COOKIE is required');
    process.exit(1);
  }

  // Scrape feed
  const posts = await scrapeFeed();
  console.log(`\n📋 Scraped ${posts.length} posts from feed\n`);

  // Analyze for signals
  const signals = [];
  for (const post of posts) {
    const signal = analyzePost(post);
    if (signal) {
      // Generate engagement suggestion
      signal.suggestedComment = await generateComment(signal);
      signals.push(signal);
      console.log(`  ✓ Signal: ${signal.signalType} from ${signal.author}`);
    }
  }

  console.log(`\n🎯 Found ${signals.length} buying signals\n`);

  // Sort by priority
  signals.sort((a, b) => {
    const priorityOrder = { high: 0, medium: 1, low: 2 };
    return priorityOrder[a.priority] - priorityOrder[b.priority];
  });

  // Save results
  await saveSignals(signals);

  // Summary
  const highPriority = signals.filter(s => s.priority === 'high').length;
  const mediumPriority = signals.filter(s => s.priority === 'medium').length;

  console.log('📊 Summary:');
  console.log(`  🔴 High priority: ${highPriority}`);
  console.log(`  🟡 Medium priority: ${mediumPriority}`);
  console.log(`  🟢 Low priority: ${signals.length - highPriority - mediumPriority}`);

  console.log('\n✨ Done!');
}

/**
 * Scrape LinkedIn feed
 */
async function scrapeFeed() {
  console.log('🔗 Scraping LinkedIn feed...');

  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({
    userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
  });

  await context.addCookies([{
    name: 'li_at',
    value: LINKEDIN_SESSION_COOKIE,
    domain: '.linkedin.com',
    path: '/',
    httpOnly: true,
    secure: true,
    sameSite: 'None'
  }]);

  const page = await context.newPage();
  const posts = [];

  try {
    await page.goto('https://www.linkedin.com/feed/', {
      waitUntil: 'networkidle',
      timeout: 60000
    });

    // Wait for feed to load
    await page.waitForSelector('.feed-shared-update-v2', { timeout: 15000 });

    // Scroll to load more posts
    for (let i = 0; i < 5; i++) {
      await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));
      await page.waitForTimeout(2000);
    }

    // Extract posts
    const postData = await page.$$eval('.feed-shared-update-v2', (els) => {
      return els.map(el => {
        const authorEl = el.querySelector('.update-components-actor__name .visually-hidden');
        const titleEl = el.querySelector('.update-components-actor__description');
        const contentEl = el.querySelector('.feed-shared-update-v2__description');
        const linkEl = el.querySelector('a[href*="/feed/update/"]');
        const reactionsEl = el.querySelector('.social-details-social-counts__reactions-count');
        const commentsEl = el.querySelector('.social-details-social-counts__comments');

        return {
          author: authorEl?.textContent?.trim() || '',
          title: titleEl?.textContent?.trim() || '',
          content: contentEl?.textContent?.trim() || '',
          postUrl: linkEl?.href || '',
          reactions: parseInt(reactionsEl?.textContent?.replace(/,/g, '') || '0'),
          comments: parseInt(commentsEl?.textContent?.replace(/[^0-9]/g, '') || '0')
        };
      });
    });

    posts.push(...postData.filter(p => p.content && p.author));

  } catch (error) {
    console.error('Error scraping feed:', error.message);
  } finally {
    await browser.close();
  }

  return posts;
}

/**
 * Analyze post for buying signals
 */
function analyzePost(post) {
  const contentLower = post.content.toLowerCase();
  const signals = [];

  // Check for each signal type
  for (const [signalType, keywords] of Object.entries(BUYING_SIGNALS)) {
    for (const keyword of keywords) {
      if (contentLower.includes(keyword)) {
        signals.push(signalType);
        break;
      }
    }
  }

  if (signals.length === 0) return null;

  // Determine priority
  let priority = 'low';
  if (signals.includes('hiring') || signals.includes('funding')) {
    priority = 'high';
  } else if (signals.includes('pain') || signals.includes('milestone')) {
    priority = 'medium';
  }

  // Extract company from title/content
  const companyMatch = post.title.match(/at\s+([^·|]+)/i) ||
                       post.content.match(/at\s+([A-Z][a-zA-Z0-9\s]+?)[\s,\.]/);
  const company = companyMatch ? companyMatch[1].trim() : 'Unknown';

  return {
    author: post.author,
    company,
    title: post.title,
    content: post.content,
    excerpt: post.content.slice(0, 300),
    postUrl: post.postUrl,
    reactions: post.reactions,
    comments: post.comments,
    signalType: signals[0],
    allSignals: signals,
    priority,
    scrapedAt: new Date().toISOString()
  };
}

/**
 * Generate engagement comment suggestion
 */
async function generateComment(signal) {
  const prompt = `You are Brandon Geter, founder of Andru (Revenue Intelligence for B2B SaaS founders).

Generate a thoughtful LinkedIn comment for this post. The comment should:
1. Be genuine and add value (not salesy)
2. Share relevant experience or insight
3. Build relationship, not pitch
4. Be 2-3 sentences max

## POST CONTEXT
Author: ${signal.author}
Company: ${signal.company}
Signal Type: ${signal.signalType}
Content: ${signal.content.slice(0, 500)}

## YOUR BACKGROUND (for credibility)
- 9 years SaaS sales experience
- Generated $30M+ in pipeline
- Built Andru to help technical founders with sales

## COMMENT GUIDELINES BY SIGNAL TYPE
- funding: Congratulate + share one insight about the stage they're entering
- hiring: Share hiring/sales team building experience
- pain: Offer genuine help or framework (no pitch)
- milestone: Celebrate + ask thoughtful follow-up question
- change: Welcome/congratulate + build connection

Generate ONLY the comment text, no quotes or explanation. Keep under 300 characters.`;

  try {
    const response = await anthropic.messages.create({
      model: 'claude-sonnet-4-20250514',
      max_tokens: 150,
      messages: [{ role: 'user', content: prompt }]
    });

    return response.content[0].text.trim();
  } catch (error) {
    console.error('Error generating comment:', error.message);
    return null;
  }
}

/**
 * Save signals to file
 */
async function saveSignals(signals) {
  const outputDir = path.join(OUTPUT_ROOT, 'feed-signals/daily');
  await fs.mkdir(outputDir, { recursive: true });

  const date = new Date().toISOString().split('T')[0];
  const filename = `${date}.json`;
  const filepath = path.join(outputDir, filename);

  const output = {
    date,
    totalPosts: signals.length,
    highPriority: signals.filter(s => s.priority === 'high').length,
    mediumPriority: signals.filter(s => s.priority === 'medium').length,
    signals
  };

  await fs.writeFile(filepath, JSON.stringify(output, null, 2), 'utf-8');
  console.log(`\n💾 Saved: ${filename}`);
}

// Run
main().catch(error => {
  console.error('Fatal error:', error);
  process.exit(1);
});

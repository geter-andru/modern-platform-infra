#!/usr/bin/env node

/**
 * Lead Gen Agent - Main Orchestration Script
 *
 * Scrapes compelling events from multiple sources, selects the most relevant,
 * and generates platform-specific posts for human review.
 *
 * Usage:
 *   node scripts/lead-gen/index.js                    # Full run
 *   node scripts/lead-gen/index.js --platform=linkedin # Single platform
 *   node scripts/lead-gen/index.js --dry-run          # Scrape only, no generation
 */

import { gatherCompellingEvents } from './scrapers.js';
import { generateAllPosts, savePosts } from './post-generator.js';
import fs from 'fs/promises';
import path from 'path';

// Get script directory and infra root
const __dirname = path.dirname(new URL(import.meta.url).pathname);
const INFRA_ROOT = path.resolve(__dirname, '../..');
const OUTPUT_ROOT = process.env.OUTPUT_ROOT || INFRA_ROOT;

// Parse CLI arguments
const args = process.argv.slice(2);
const isDryRun = args.includes('--dry-run');
const platformArg = args.find(a => a.startsWith('--platform='));
const targetPlatform = platformArg ? platformArg.split('=')[1] : null;

/**
 * Score an event based on relevance to Andru's target audience
 * Higher score = more relevant
 */
function scoreEvent(event) {
  let score = 0;
  const combined = `${event.title || ''} ${event.excerpt || ''} ${event.company || ''}`.toLowerCase();

  // Funding signals (high value - these founders need ICP clarity)
  if (combined.includes('seed')) score += 10;
  if (combined.includes('series a')) score += 15;
  if (combined.includes('series b')) score += 8;
  if (combined.includes('raises') || combined.includes('raised')) score += 5;

  // Sales hire signals (very high value - exactly our ICP moment)
  if (combined.includes('first sales') || combined.includes('first hire')) score += 20;
  if (combined.includes('vp sales') || combined.includes('head of sales')) score += 12;
  if (combined.includes('founding') && combined.includes('sales')) score += 15;

  // GTM/ICP signals (high relevance to our content)
  if (combined.includes('icp')) score += 10;
  if (combined.includes('go-to-market') || combined.includes('gtm')) score += 8;
  if (combined.includes('b2b')) score += 5;
  if (combined.includes('saas')) score += 5;
  if (combined.includes('technical founder')) score += 10;

  // Negative signals (less relevant)
  if (combined.includes('consumer')) score -= 5;
  if (combined.includes('crypto') || combined.includes('web3')) score -= 3;

  // Source bonuses
  if (event.source === 'techcrunch') score += 3;
  if (event.source === 'reddit_startups') score += 2;

  return score;
}

/**
 * Select the best event from all scraped events
 */
function selectBestEvent(events) {
  const allEvents = [
    ...(events.funding || []),
    ...(events.reddit || []),
    ...(events.linkedin || [])
  ];

  if (allEvents.length === 0) {
    return null;
  }

  // Score and sort
  const scoredEvents = allEvents.map(e => ({
    ...e,
    score: scoreEvent(e)
  })).sort((a, b) => b.score - a.score);

  console.log('\n📊 Top 5 scored events:');
  scoredEvents.slice(0, 5).forEach((e, i) => {
    console.log(`  ${i + 1}. [${e.score}] ${e.title?.slice(0, 60)}... (${e.source})`);
  });

  return scoredEvents[0];
}

/**
 * Load previously processed events to avoid duplicates
 */
async function loadProcessedEvents() {
  const historyPath = path.join(OUTPUT_ROOT, 'lead-gen/processed-events.json');
  try {
    const data = await fs.readFile(historyPath, 'utf-8');
    return JSON.parse(data);
  } catch {
    return { urls: [] };
  }
}

/**
 * Save processed event URL to history
 */
async function saveProcessedEvent(url) {
  const historyPath = path.join(OUTPUT_ROOT, 'lead-gen/processed-events.json');
  const history = await loadProcessedEvents();

  history.urls.push(url);
  // Keep only last 100 URLs
  if (history.urls.length > 100) {
    history.urls = history.urls.slice(-100);
  }

  await fs.writeFile(historyPath, JSON.stringify(history, null, 2));
}

/**
 * Main agent execution
 */
async function main() {
  console.log('🤖 Andru Lead Gen Agent Starting...');
  console.log(`   Mode: ${isDryRun ? 'DRY RUN' : 'FULL'}`);
  console.log(`   Platform: ${targetPlatform || 'ALL'}`);
  console.log(`   Time: ${new Date().toISOString()}\n`);

  // Step 1: Gather compelling events
  const events = await gatherCompellingEvents();

  const totalEvents = (events.funding?.length || 0) +
                      (events.reddit?.length || 0) +
                      (events.linkedin?.length || 0);

  if (totalEvents === 0) {
    console.log('❌ No events found. Exiting.');
    process.exit(0);
  }

  // Step 2: Filter out already-processed events
  const history = await loadProcessedEvents();
  const filterEvent = (e) => !history.urls.includes(e.url);

  const freshEvents = {
    funding: (events.funding || []).filter(filterEvent),
    reddit: (events.reddit || []).filter(filterEvent),
    linkedin: (events.linkedin || []).filter(filterEvent)
  };

  const freshCount = (freshEvents.funding?.length || 0) +
                     (freshEvents.reddit?.length || 0) +
                     (freshEvents.linkedin?.length || 0);

  console.log(`\n🆕 Fresh events (not previously processed): ${freshCount}`);

  if (freshCount === 0) {
    console.log('ℹ️  All events already processed. Exiting.');
    process.exit(0);
  }

  // Step 3: Select best event
  const bestEvent = selectBestEvent(freshEvents);

  if (!bestEvent) {
    console.log('❌ Could not select a best event. Exiting.');
    process.exit(0);
  }

  console.log(`\n🎯 Selected event: "${bestEvent.title}"`);
  console.log(`   Source: ${bestEvent.source}`);
  console.log(`   URL: ${bestEvent.url}`);
  console.log(`   Score: ${bestEvent.score}`);

  if (isDryRun) {
    console.log('\n🏃 Dry run complete. No posts generated.');
    process.exit(0);
  }

  // Step 4: Generate posts
  const result = await generateAllPosts(bestEvent);

  // Step 5: Save posts for review
  const savedFiles = await savePosts(result);

  // Step 6: Mark event as processed
  await saveProcessedEvent(bestEvent.url);

  // Step 7: Summary
  console.log('\n✅ Lead Gen Agent Complete!');
  console.log(`   Generated ${savedFiles.length} posts for review`);
  console.log('   Location: lead-gen/posts/');
  console.log('\n📋 Next steps:');
  console.log('   1. Review the generated posts in dev/lead-gen/posts/');
  console.log('   2. Edit as needed');
  console.log('   3. Mark [ ] Posted when published');

  // Output summary for GitHub Actions
  if (process.env.GITHUB_OUTPUT) {
    const summary = `Generated ${savedFiles.length} posts for: ${bestEvent.title.slice(0, 50)}`;
    await fs.appendFile(process.env.GITHUB_OUTPUT, `summary=${summary}\n`);
  }
}

// Run
main().catch(error => {
  console.error('💥 Agent failed:', error.message);
  process.exit(1);
});

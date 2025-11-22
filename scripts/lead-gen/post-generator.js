/**
 * Post Generator
 * Uses Claude API to generate platform-specific posts based on compelling events
 */

import Anthropic from '@anthropic-ai/sdk';
import fs from 'fs/promises';
import path from 'path';

const anthropic = new Anthropic();

// Load strategy and philosophy docs
// Get script directory
const __dirname = path.dirname(new URL(import.meta.url).pathname);
const INFRA_ROOT = path.resolve(__dirname, '../..');

// Content paths - can be overridden via environment variables
// Default assumes content is in infra/content/ directory
const CONTENT_ROOT = process.env.CONTENT_ROOT || path.join(INFRA_ROOT, 'content');
const STRATEGY_PATH = process.env.STRATEGY_PATH || path.join(CONTENT_ROOT, 'COMPELLING_EVENT_POSTING_STRATEGY.md');
const PHILOSOPHY_PATH = process.env.PHILOSOPHY_PATH || CONTENT_ROOT;
const OUTPUT_ROOT = process.env.OUTPUT_ROOT || INFRA_ROOT;

/**
 * Load the posting strategy document
 */
async function loadStrategy() {
  try {
    return await fs.readFile(STRATEGY_PATH, 'utf-8');
  } catch (error) {
    console.error('Could not load strategy:', error.message);
    return '';
  }
}

/**
 * Load core philosophy documents
 */
async function loadPhilosophy() {
  try {
    const files = await fs.readdir(PHILOSOPHY_PATH);
    const mdFiles = files.filter(f => f.endsWith('.md') || !f.includes('.'));

    const contents = await Promise.all(
      mdFiles.slice(0, 3).map(async (f) => {
        const content = await fs.readFile(path.join(PHILOSOPHY_PATH, f), 'utf-8');
        return `## ${f}\n${content.slice(0, 3000)}`; // Truncate for context limits
      })
    );

    return contents.join('\n\n---\n\n');
  } catch (error) {
    console.error('Could not load philosophy:', error.message);
    return '';
  }
}

/**
 * Classify the event type
 */
function classifyEvent(event) {
  const title = (event.title || '').toLowerCase();
  const excerpt = (event.excerpt || '').toLowerCase();
  const combined = `${title} ${excerpt}`;

  if (combined.includes('raises') || combined.includes('funding') || combined.includes('series') || combined.includes('seed')) {
    return 'funding';
  }
  if (combined.includes('hire') || combined.includes('sales') || combined.includes('vp sales') || combined.includes('first')) {
    return 'sales_hire';
  }
  if (combined.includes('layoff') || combined.includes('pivot') || combined.includes('shut down')) {
    return 'layoff';
  }
  if (event.source === 'reddit_startups') {
    return 'reddit_discussion';
  }
  return 'general';
}

/**
 * Generate a post for a specific platform
 */
async function generatePost(event, platform, strategy, philosophy) {
  const eventType = classifyEvent(event);

  const platformInstructions = {
    linkedin: `
You are writing a LinkedIn post for Brandon Geter, founder of Andru.

TARGET AUDIENCE: 65% investors, 35% founders
TONE: Professional, analytical, thought leadership
LENGTH: 800-1500 characters with line breaks for readability
FORMAT:
- Hook (compelling event + contrarian take)
- Context (what happened + why it matters)
- Philosophy (Andru perspective)
- Insight (specific recommendation)
- @mention the company/founder if known
- CTA question to drive engagement

DO NOT use hashtags excessively (max 2-3 at end).
DO NOT be salesy about Andru.
DO provide genuine value and insight.
`,
    twitter: `
You are writing a Twitter/X post for Brandon Geter, founder of Andru.

TARGET AUDIENCE: 75% founders, 25% investors
TONE: Punchy, direct, slightly provocative, founder-to-founder
LENGTH: Single tweet (280 chars) OR short thread (5-8 tweets, each under 280 chars)
FORMAT:
- Hot take hook
- 1-2 sentences context
- One Andru principle (without naming Andru explicitly)
- @mention if relevant
- Engagement question or prediction

If writing a thread, format as:
Tweet 1: [content]

Tweet 2: [content]

etc.

DO NOT be preachy.
DO be authentic and direct.
`,
    reddit: `
You are writing a Reddit post for r/startups or r/SaaS.

TARGET AUDIENCE: 50% founders, 50% lurkers/investors
TONE: Authentic, helpful, community-first, NO self-promotion
LENGTH: 200-400 words
FORMAT:
- Title: [Observation or question based on the event]
- Body: Share insight from experience, ask for community input

CRITICAL:
- DO NOT mention Andru or any product
- DO NOT include links
- DO share genuine frameworks and ask questions
- Write as a fellow founder sharing lessons learned
`
  };

  const prompt = `
${platformInstructions[platform]}

---

## ANDRU PHILOSOPHY (use these concepts naturally, don't force them):

Key concepts to weave in where relevant:
- "Contaminated data" vs "Pure Signal" - early customers often bought for wrong reasons
- "Sahara vs Grocery Store" - find where you're essential, not optional
- "The right customers sell for you" - evangelists > transactions
- "90% fail from lack of clarity, not lack of market need"
- Technical founders struggle to translate features → outcomes → ROI

---

## BRANDON'S BACKGROUND (for credibility):
- 9 years SaaS sales (Apttus, Sumo Logic, Graphite, OpsLevel)
- Generated $30M+ in pipeline across 7 companies
- Built Andru in 4 months with zero coding background
- Hired/trained 20+ sellers

---

## THE COMPELLING EVENT:

Source: ${event.source}
Title: ${event.title}
URL: ${event.url}
${event.excerpt ? `Excerpt: ${event.excerpt}` : ''}
${event.company ? `Company: ${event.company}` : ''}
${event.author ? `Author: ${event.author}` : ''}

Event Type: ${eventType}

---

## POSTING STRATEGY CONTEXT:

${strategy.slice(0, 2000)}

---

Now generate the ${platform.toUpperCase()} post. Be thoughtful, add genuine value, and make it feel like Brandon wrote it himself based on his experience.
`;

  try {
    const response = await anthropic.messages.create({
      model: 'claude-sonnet-4-20250514',
      max_tokens: 1500,
      messages: [
        {
          role: 'user',
          content: prompt
        }
      ]
    });

    return response.content[0].text;
  } catch (error) {
    console.error(`Error generating ${platform} post:`, error.message);
    return null;
  }
}

/**
 * Generate posts for all platforms for a given event
 */
export async function generateAllPosts(event) {
  console.log(`\n📝 Generating posts for: "${event.title}"\n`);

  const [strategy, philosophy] = await Promise.all([
    loadStrategy(),
    loadPhilosophy()
  ]);

  const platforms = ['linkedin', 'twitter', 'reddit'];
  const posts = {};

  for (const platform of platforms) {
    console.log(`  → Generating ${platform} post...`);
    posts[platform] = await generatePost(event, platform, strategy, philosophy);
  }

  return {
    event,
    posts,
    generatedAt: new Date().toISOString()
  };
}

/**
 * Save generated posts to files
 */
export async function savePosts(result) {
  const postsDir = path.join(OUTPUT_ROOT, 'lead-gen/posts');
  const date = new Date().toISOString().split('T')[0];
  const slug = (result.event.title || 'event')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .slice(0, 50);

  const savedFiles = [];

  for (const [platform, content] of Object.entries(result.posts)) {
    if (!content) continue;

    const filename = `${date}_${platform}_${slug}.md`;
    const filepath = path.join(postsDir, filename);

    const fileContent = `# ${platform.toUpperCase()} Post - ${date}

## Source Event
- **Title:** ${result.event.title}
- **URL:** ${result.event.url}
- **Source:** ${result.event.source}
- **Generated:** ${result.generatedAt}

---

## Post Content

${content}

---

## Status
- [ ] Reviewed
- [ ] Posted
`;

    await fs.writeFile(filepath, fileContent, 'utf-8');
    savedFiles.push(filename);
    console.log(`  ✅ Saved: ${filename}`);
  }

  return savedFiles;
}

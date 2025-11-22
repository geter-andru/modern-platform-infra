/**
 * LinkedIn Connections Scraper
 * Scrapes the connections page to detect new connections
 */

import { chromium } from 'playwright';
import fs from 'fs/promises';
import path from 'path';

const __dirname = path.dirname(new URL(import.meta.url).pathname);

/**
 * Load previously processed connections
 */
export async function loadProcessedConnections() {
  const filepath = path.join(__dirname, 'processed-connections.json');
  try {
    const content = await fs.readFile(filepath, 'utf-8');
    return JSON.parse(content);
  } catch {
    return { connections: [], lastRun: null };
  }
}

/**
 * Save processed connections
 */
export async function saveProcessedConnections(data) {
  const filepath = path.join(__dirname, 'processed-connections.json');
  await fs.writeFile(filepath, JSON.stringify(data, null, 2), 'utf-8');
}

/**
 * Scrape current LinkedIn connections list
 */
export async function scrapeConnections(sessionCookie) {
  console.log('🔗 Scraping LinkedIn connections...');

  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({
    userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
  });

  // Add LinkedIn session cookie
  await context.addCookies([{
    name: 'li_at',
    value: sessionCookie,
    domain: '.linkedin.com',
    path: '/',
    httpOnly: true,
    secure: true,
    sameSite: 'None'
  }]);

  const page = await context.newPage();
  const connections = [];

  try {
    // Navigate to connections page
    await page.goto('https://www.linkedin.com/mynetwork/invite-connect/connections/', {
      waitUntil: 'networkidle',
      timeout: 60000
    });

    // Wait for connections to load
    await page.waitForSelector('.mn-connection-card', { timeout: 15000 });

    // Scroll to load more connections (up to 100)
    for (let i = 0; i < 5; i++) {
      await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));
      await page.waitForTimeout(1500);
    }

    // Extract connection data
    const connectionData = await page.$$eval('.mn-connection-card', (cards) => {
      return cards.map(card => {
        const nameEl = card.querySelector('.mn-connection-card__name');
        const titleEl = card.querySelector('.mn-connection-card__occupation');
        const linkEl = card.querySelector('a.mn-connection-card__link');
        const imgEl = card.querySelector('.presence-entity__image');
        const timeEl = card.querySelector('.time-badge');

        return {
          name: nameEl?.textContent?.trim() || '',
          title: titleEl?.textContent?.trim() || '',
          profileUrl: linkEl?.href || '',
          imageUrl: imgEl?.src || '',
          connectedTime: timeEl?.textContent?.trim() || ''
        };
      });
    });

    connections.push(...connectionData);
    console.log(`  → Found ${connections.length} connections`);

  } catch (error) {
    console.error('Error scraping connections:', error.message);
  } finally {
    await browser.close();
  }

  return connections;
}

/**
 * Find new connections by comparing with processed list
 */
export async function findNewConnections(sessionCookie) {
  const processed = await loadProcessedConnections();
  const current = await scrapeConnections(sessionCookie);

  // Create set of already processed profile URLs
  const processedUrls = new Set(processed.connections.map(c => c.profileUrl));

  // Find connections not in processed list
  const newConnections = current.filter(c =>
    c.profileUrl && !processedUrls.has(c.profileUrl)
  );

  console.log(`  → ${newConnections.length} new connection(s) to process`);

  return {
    new: newConnections,
    all: current,
    processed
  };
}

/**
 * Mark connections as processed
 */
export async function markAsProcessed(connections) {
  const processed = await loadProcessedConnections();

  for (const conn of connections) {
    if (!processed.connections.find(c => c.profileUrl === conn.profileUrl)) {
      processed.connections.push({
        ...conn,
        processedAt: new Date().toISOString()
      });
    }
  }

  processed.lastRun = new Date().toISOString();
  await saveProcessedConnections(processed);
}

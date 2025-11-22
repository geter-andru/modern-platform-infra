/**
 * Lead Gen Scrapers
 * Uses Playwright to scrape compelling events from various sources
 */

import { chromium } from 'playwright';

/**
 * Scrape recent funding rounds from TechCrunch
 * @returns {Promise<Array>} Array of funding events
 */
export async function scrapeTechCrunchFunding() {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();

  try {
    await page.goto('https://techcrunch.com/category/startups/', {
      waitUntil: 'domcontentloaded',
      timeout: 30000
    });

    // Wait for articles to load
    await page.waitForSelector('article', { timeout: 10000 }).catch(() => null);

    const articles = await page.$$eval('article', (els) => {
      return els.slice(0, 10).map(el => {
        const titleEl = el.querySelector('h2 a, h3 a');
        const linkEl = el.querySelector('a');
        const excerptEl = el.querySelector('p');

        return {
          title: titleEl?.textContent?.trim() || '',
          url: linkEl?.href || '',
          excerpt: excerptEl?.textContent?.trim() || '',
          source: 'techcrunch'
        };
      });
    });

    // Filter for funding-related articles
    const fundingKeywords = ['raises', 'raised', 'funding', 'series a', 'series b', 'seed', 'million', 'venture'];
    const fundingArticles = articles.filter(a =>
      fundingKeywords.some(kw => a.title.toLowerCase().includes(kw) || a.excerpt.toLowerCase().includes(kw))
    );

    await browser.close();
    return fundingArticles;
  } catch (error) {
    console.error('TechCrunch scrape error:', error.message);
    await browser.close();
    return [];
  }
}

/**
 * Scrape Reddit r/startups for relevant discussions
 * @returns {Promise<Array>} Array of Reddit posts
 */
export async function scrapeRedditStartups() {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();

  // Set user agent to avoid blocks
  await page.setExtraHTTPHeaders({
    'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
  });

  try {
    await page.goto('https://old.reddit.com/r/startups/new/', {
      waitUntil: 'domcontentloaded',
      timeout: 30000
    });

    await page.waitForSelector('.thing', { timeout: 10000 }).catch(() => null);

    const posts = await page.$$eval('.thing.link', (els) => {
      return els.slice(0, 15).map(el => {
        const titleEl = el.querySelector('a.title');
        const authorEl = el.querySelector('.author');
        const scoreEl = el.querySelector('.score.unvoted');
        const isPromoted = el.classList.contains('promoted') || el.querySelector('.promoted-tag');

        return {
          title: titleEl?.textContent?.trim() || '',
          url: titleEl?.href || '',
          author: authorEl?.textContent?.trim() || '',
          score: scoreEl?.textContent?.trim() || '0',
          source: 'reddit_startups',
          isPromoted: !!isPromoted
        };
      }).filter(p => !p.isPromoted && !p.url.includes('alb.reddit.com')); // Filter out ads
    });

    // Filter for ICP/sales/funding related posts
    const relevantKeywords = ['sales', 'first hire', 'icp', 'customer', 'funding', 'raised', 'series', 'gtm', 'go-to-market', 'b2b'];
    const relevantPosts = posts.filter(p =>
      relevantKeywords.some(kw => p.title.toLowerCase().includes(kw))
    );

    await browser.close();
    return relevantPosts.length > 0 ? relevantPosts : posts.slice(0, 5); // Fallback to top 5 if no matches
  } catch (error) {
    console.error('Reddit scrape error:', error.message);
    await browser.close();
    return [];
  }
}

/**
 * Scrape Twitter/X for VC and founder posts (requires login state)
 * For now, returns placeholder - would need auth cookies
 * @returns {Promise<Array>} Array of tweets
 */
export async function scrapeTwitterVC() {
  // Twitter requires authentication - for MVP, we'll use a manual input approach
  // or integrate with Twitter API v2 later
  console.log('Twitter scraping requires API access - skipping for MVP');
  return [];
}

/**
 * Scrape LinkedIn Jobs for sales hires at startups
 * Note: LinkedIn heavily blocks scrapers - this is best-effort
 * @returns {Promise<Array>} Array of job postings
 */
export async function scrapeLinkedInJobs() {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();

  try {
    // Use LinkedIn's public job search (no auth required for basic results)
    const searchUrl = 'https://www.linkedin.com/jobs/search/?keywords=sales%20representative%20startup&f_TPR=r86400&f_E=2'; // Entry level, past 24h

    await page.goto(searchUrl, {
      waitUntil: 'domcontentloaded',
      timeout: 30000
    });

    await page.waitForSelector('.jobs-search__results-list', { timeout: 10000 }).catch(() => null);

    const jobs = await page.$$eval('.jobs-search__results-list li', (els) => {
      return els.slice(0, 10).map(el => {
        const titleEl = el.querySelector('.base-search-card__title');
        const companyEl = el.querySelector('.base-search-card__subtitle');
        const linkEl = el.querySelector('a.base-card__full-link');

        return {
          title: titleEl?.textContent?.trim() || '',
          company: companyEl?.textContent?.trim() || '',
          url: linkEl?.href || '',
          source: 'linkedin_jobs'
        };
      });
    });

    // Filter for first sales hire indicators
    const firstHireKeywords = ['first', 'founding', '0-1', 'early stage', 'startup'];
    const relevantJobs = jobs.filter(j =>
      firstHireKeywords.some(kw => j.title.toLowerCase().includes(kw) || j.company.toLowerCase().includes(kw))
    );

    await browser.close();
    return relevantJobs.length > 0 ? relevantJobs : jobs.slice(0, 3);
  } catch (error) {
    console.error('LinkedIn scrape error:', error.message);
    await browser.close();
    return [];
  }
}

/**
 * Main function to gather all compelling events
 * @returns {Promise<Object>} Categorized events
 */
export async function gatherCompellingEvents() {
  console.log('🔍 Gathering compelling events...\n');

  const [funding, reddit, linkedin] = await Promise.all([
    scrapeTechCrunchFunding(),
    scrapeRedditStartups(),
    scrapeLinkedInJobs()
  ]);

  console.log(`📊 Found: ${funding.length} funding articles, ${reddit.length} Reddit posts, ${linkedin.length} LinkedIn jobs\n`);

  return {
    funding,
    reddit,
    linkedin,
    scrapedAt: new Date().toISOString()
  };
}

/**
 * Company Website Scraper
 * Analyzes company website to understand the product
 */

import { chromium } from 'playwright';

/**
 * Scrape company website for product information
 */
export async function scrapeCompanyWebsite(websiteUrl) {
  if (!websiteUrl) {
    console.log('  🌐 No company website to scrape');
    return null;
  }

  console.log(`  🌐 Scraping company website: ${websiteUrl}`);

  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();

  const companyInfo = {
    url: websiteUrl,
    title: '',
    tagline: '',
    description: '',
    features: [],
    useCases: [],
    pricing: null,
    targetAudience: ''
  };

  try {
    // Ensure URL has protocol
    const url = websiteUrl.startsWith('http') ? websiteUrl : `https://${websiteUrl}`;

    await page.goto(url, {
      waitUntil: 'domcontentloaded',
      timeout: 30000
    });

    // Extract page title
    companyInfo.title = await page.title();

    // Extract meta description
    companyInfo.description = await page.$eval(
      'meta[name="description"]',
      el => el.content
    ).catch(() => '');

    // Extract h1 (usually tagline)
    companyInfo.tagline = await page.$eval('h1', el => el.textContent?.trim() || '').catch(() => '');

    // Get all visible text for analysis
    const pageText = await page.evaluate(() => {
      // Get text from main content areas
      const selectors = ['main', 'article', '.hero', '.content', 'body'];
      for (const sel of selectors) {
        const el = document.querySelector(sel);
        if (el) {
          return el.innerText?.slice(0, 5000) || '';
        }
      }
      return document.body.innerText?.slice(0, 5000) || '';
    });

    // Try to find features section
    const features = await page.$$eval(
      '[class*="feature"], [class*="benefit"], .card h3, .card h4',
      els => els.slice(0, 6).map(el => el.textContent?.trim() || '')
    ).catch(() => []);
    companyInfo.features = features.filter(f => f.length > 0 && f.length < 200);

    // Try to identify target audience from content
    const audiencePatterns = [
      /for\s+([\w\s]+(?:teams?|companies?|businesses?|founders?|developers?|engineers?))/gi,
      /helps?\s+([\w\s]+)\s+(?:to|with|by)/gi,
      /built\s+for\s+([\w\s]+)/gi
    ];

    for (const pattern of audiencePatterns) {
      const match = pageText.match(pattern);
      if (match) {
        companyInfo.targetAudience = match[1] || match[0];
        break;
      }
    }

    // Store raw text for Claude analysis
    companyInfo.rawContent = pageText;

    console.log(`    ✓ ${companyInfo.tagline || companyInfo.title}`);

  } catch (error) {
    console.error(`    ✗ Error scraping website: ${error.message}`);
  } finally {
    await browser.close();
  }

  return companyInfo;
}

/**
 * Extract product info from multiple pages
 */
export async function deepScrapeCompany(websiteUrl) {
  if (!websiteUrl) return null;

  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext();

  const info = {
    homepage: null,
    about: null,
    pricing: null,
    product: null
  };

  try {
    const baseUrl = websiteUrl.startsWith('http') ? websiteUrl : `https://${websiteUrl}`;
    const page = await context.newPage();

    // Scrape homepage
    await page.goto(baseUrl, { waitUntil: 'domcontentloaded', timeout: 20000 });
    info.homepage = await extractPageContent(page);

    // Try common subpages
    const subpages = ['/about', '/product', '/features', '/pricing'];

    for (const subpage of subpages) {
      try {
        await page.goto(`${baseUrl}${subpage}`, {
          waitUntil: 'domcontentloaded',
          timeout: 10000
        });
        const content = await extractPageContent(page);
        if (content.text.length > 200) {
          info[subpage.replace('/', '')] = content;
        }
      } catch {
        // Page doesn't exist, skip
      }
    }

  } catch (error) {
    console.error(`Error in deep scrape: ${error.message}`);
  } finally {
    await browser.close();
  }

  return info;
}

/**
 * Extract content from a page
 */
async function extractPageContent(page) {
  return {
    title: await page.title(),
    text: await page.evaluate(() => {
      const main = document.querySelector('main') || document.body;
      return main.innerText?.slice(0, 3000) || '';
    }),
    headings: await page.$$eval('h1, h2, h3', els =>
      els.slice(0, 10).map(el => el.textContent?.trim() || '')
    ).catch(() => [])
  };
}

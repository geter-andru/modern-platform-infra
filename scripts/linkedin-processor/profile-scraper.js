/**
 * LinkedIn Profile Scraper
 * Deep scrape of individual LinkedIn profiles
 */

import { chromium } from 'playwright';

/**
 * Scrape detailed profile information
 */
export async function scrapeProfile(profileUrl, sessionCookie) {
  console.log(`  📋 Scraping profile: ${profileUrl}`);

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
  const profile = {
    url: profileUrl,
    name: '',
    firstName: '',
    lastName: '',
    headline: '',
    company: '',
    companyUrl: '',
    location: '',
    about: '',
    experience: [],
    recentPosts: [],
    skills: []
  };

  try {
    await page.goto(profileUrl, {
      waitUntil: 'networkidle',
      timeout: 60000
    });

    // Wait for main content
    await page.waitForSelector('.text-heading-xlarge', { timeout: 10000 });

    // Extract basic info
    profile.name = await page.$eval('.text-heading-xlarge', el => el.textContent?.trim() || '').catch(() => '');
    profile.headline = await page.$eval('.text-body-medium', el => el.textContent?.trim() || '').catch(() => '');
    profile.location = await page.$eval('.text-body-small.inline.t-black--light', el => el.textContent?.trim() || '').catch(() => '');

    // Parse first and last name
    const nameParts = profile.name.split(' ');
    profile.firstName = nameParts[0] || '';
    profile.lastName = nameParts.slice(1).join(' ') || '';

    // Extract company from headline or experience
    const companyMatch = profile.headline.match(/(?:at|@)\s+(.+?)(?:\s*[|·•]|$)/i);
    if (companyMatch) {
      profile.company = companyMatch[1].trim();
    }

    // Extract About section
    try {
      // Click "see more" if exists
      const seeMoreBtn = await page.$('#about ~ .pvs-list__outer-container button[aria-expanded="false"]');
      if (seeMoreBtn) await seeMoreBtn.click();
      await page.waitForTimeout(500);

      profile.about = await page.$eval('#about ~ .pvs-list__outer-container .inline-show-more-text',
        el => el.textContent?.trim() || ''
      ).catch(() => '');
    } catch {
      // About section might not exist
    }

    // Extract Experience
    try {
      const experiences = await page.$$eval('#experience ~ .pvs-list__outer-container .pvs-entity', (els) => {
        return els.slice(0, 3).map(el => {
          const title = el.querySelector('.t-bold .visually-hidden')?.textContent?.trim() || '';
          const company = el.querySelector('.t-normal .visually-hidden')?.textContent?.trim() || '';
          const duration = el.querySelector('.pvs-entity__caption-wrapper')?.textContent?.trim() || '';
          return { title, company, duration };
        });
      });
      profile.experience = experiences;

      // Get company from most recent experience if not found
      if (!profile.company && experiences.length > 0) {
        const companyText = experiences[0].company;
        profile.company = companyText.split('·')[0].trim();
      }
    } catch {
      // Experience section might not exist
    }

    // Try to get company LinkedIn URL
    try {
      profile.companyUrl = await page.$eval(
        '#experience ~ .pvs-list__outer-container a[href*="/company/"]',
        el => el.href
      ).catch(() => '');
    } catch {
      // Company URL might not be available
    }

    // Extract recent activity/posts
    try {
      await page.goto(`${profileUrl}/recent-activity/all/`, {
        waitUntil: 'networkidle',
        timeout: 30000
      });

      await page.waitForTimeout(2000);

      const posts = await page.$$eval('.feed-shared-update-v2', (els) => {
        return els.slice(0, 3).map(el => {
          const text = el.querySelector('.feed-shared-update-v2__description')?.textContent?.trim() || '';
          return text.slice(0, 500); // Truncate
        });
      }).catch(() => []);

      profile.recentPosts = posts.filter(p => p.length > 0);
    } catch {
      // Activity page might not load
    }

    console.log(`    ✓ ${profile.name} @ ${profile.company}`);

  } catch (error) {
    console.error(`    ✗ Error scraping profile: ${error.message}`);
  } finally {
    await browser.close();
  }

  return profile;
}

/**
 * Scrape profile from a direct URL (for manual trigger)
 */
export async function scrapeProfileFromUrl(url, sessionCookie) {
  // Clean up the URL
  const cleanUrl = url.split('?')[0].replace(/\/$/, '');
  return scrapeProfile(cleanUrl, sessionCookie);
}

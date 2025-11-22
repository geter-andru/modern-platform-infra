/**
 * LinkedIn Connection Processor
 * Main orchestrator for the automated LinkedIn → ICP pipeline
 *
 * Flow:
 * 1. Scrape LinkedIn connections (or use provided profile URL)
 * 2. Detect new connections
 * 3. For each new connection:
 *    - Scrape their LinkedIn profile
 *    - Enrich with Lusha (company data)
 *    - Scrape their company website
 *    - Generate ICP scenario with Claude
 *    - Generate personalized InMail draft
 * 4. Update scenarios.json in frontend repo
 * 5. Save InMail drafts for review
 */

import fs from 'fs/promises';
import path from 'path';

import { findNewConnections, markAsProcessed } from './connections-scraper.js';
import { scrapeProfile, scrapeProfileFromUrl } from './profile-scraper.js';
import { enrichWithLusha } from './lusha-enricher.js';
import { scrapeCompanyWebsite } from './company-scraper.js';
import { generateScenario, mergeScenario } from './scenario-generator.js';
import { generateInMail, saveInMailDraft } from './message-generator.js';

// Environment configuration
const LINKEDIN_SESSION_COOKIE = process.env.LINKEDIN_SESSION_COOKIE;
const LUSHA_API_KEY = process.env.LUSHA_API_KEY;
const FRONTEND_SCENARIOS_PATH = process.env.FRONTEND_SCENARIOS_PATH;
const OUTPUT_ROOT = process.env.OUTPUT_ROOT || process.cwd();
const PROFILE_URL = process.env.PROFILE_URL; // Optional: single profile to process
const DRY_RUN = process.env.DRY_RUN === 'true';

/**
 * Main execution
 */
async function main() {
  console.log('🔗 LinkedIn Connection Processor Starting...\n');

  if (!LINKEDIN_SESSION_COOKIE) {
    console.error('❌ LINKEDIN_SESSION_COOKIE is required');
    process.exit(1);
  }

  let profilesToProcess = [];

  // Mode 1: Single profile URL provided (manual trigger)
  if (PROFILE_URL) {
    console.log('📌 Manual mode: Processing single profile');
    const profile = await scrapeProfileFromUrl(PROFILE_URL, LINKEDIN_SESSION_COOKIE);
    if (profile && profile.name) {
      profilesToProcess = [profile];
    }
  }
  // Mode 2: Daily scan for new connections
  else {
    console.log('🔄 Auto mode: Scanning for new connections');
    const { new: newConnections } = await findNewConnections(LINKEDIN_SESSION_COOKIE);

    if (newConnections.length === 0) {
      console.log('\n✅ No new connections to process. Exiting.');
      return;
    }

    // Scrape full profiles for new connections
    for (const conn of newConnections) {
      const profile = await scrapeProfile(conn.profileUrl, LINKEDIN_SESSION_COOKIE);
      if (profile && profile.name) {
        profilesToProcess.push(profile);
      }
      // Rate limiting
      await sleep(2000);
    }
  }

  console.log(`\n📋 Processing ${profilesToProcess.length} profile(s)\n`);

  // Load existing scenarios
  let existingScenarios = [];
  if (FRONTEND_SCENARIOS_PATH) {
    try {
      const content = await fs.readFile(FRONTEND_SCENARIOS_PATH, 'utf-8');
      existingScenarios = JSON.parse(content);
      console.log(`📂 Loaded ${existingScenarios.length} existing scenarios\n`);
    } catch (error) {
      console.log('⚠️ Could not load existing scenarios, starting fresh\n');
    }
  }

  const results = {
    processed: [],
    scenarios: [],
    inmails: [],
    errors: []
  };

  // Process each profile
  for (const profile of profilesToProcess) {
    console.log(`\n${'='.repeat(50)}`);
    console.log(`Processing: ${profile.name} @ ${profile.company}`);
    console.log('='.repeat(50));

    try {
      // Step 1: Enrich with Lusha
      const enrichedProfile = await enrichWithLusha(profile, LUSHA_API_KEY);

      // Step 2: Get company website URL
      const websiteUrl = enrichedProfile.lusha?.companyWebsite ||
                         await inferWebsiteUrl(enrichedProfile.company);

      // Step 3: Scrape company website
      const companyInfo = await scrapeCompanyWebsite(websiteUrl);

      if (DRY_RUN) {
        console.log('\n🔍 DRY RUN - Skipping scenario and message generation');
        console.log('  Profile:', enrichedProfile.name);
        console.log('  Company:', enrichedProfile.company);
        console.log('  Website:', websiteUrl);
        console.log('  Industry:', enrichedProfile.lusha?.industry);
        continue;
      }

      // Step 4: Generate scenario
      const scenario = await generateScenario(enrichedProfile, companyInfo);

      if (scenario) {
        results.scenarios.push(scenario);

        // Merge into existing scenarios
        const { scenarios: updatedScenarios, action } = mergeScenario(existingScenarios, scenario);
        existingScenarios = updatedScenarios;
        console.log(`    → Scenario ${action}: ${scenario.slug}`);
      }

      // Step 5: Generate InMail
      const inmail = await generateInMail(enrichedProfile, scenario);

      if (inmail) {
        const filename = await saveInMailDraft(inmail, OUTPUT_ROOT);
        results.inmails.push({ ...inmail, filename });
      }

      results.processed.push({
        name: profile.name,
        company: profile.company,
        scenario: scenario?.slug,
        inmail: !!inmail
      });

      // Rate limiting between profiles
      await sleep(3000);

    } catch (error) {
      console.error(`  ❌ Error processing ${profile.name}: ${error.message}`);
      results.errors.push({
        name: profile.name,
        error: error.message
      });
    }
  }

  // Save updated scenarios to frontend repo
  if (FRONTEND_SCENARIOS_PATH && results.scenarios.length > 0 && !DRY_RUN) {
    console.log(`\n📝 Saving ${results.scenarios.length} scenario(s) to frontend repo...`);
    await fs.writeFile(
      FRONTEND_SCENARIOS_PATH,
      JSON.stringify(existingScenarios, null, 2),
      'utf-8'
    );
    console.log('  ✓ scenarios.json updated');
  }

  // Mark connections as processed
  if (!PROFILE_URL && !DRY_RUN) {
    await markAsProcessed(profilesToProcess);
  }

  // Summary
  console.log('\n' + '='.repeat(50));
  console.log('📊 SUMMARY');
  console.log('='.repeat(50));
  console.log(`  ✓ Processed: ${results.processed.length}`);
  console.log(`  ✓ Scenarios: ${results.scenarios.length}`);
  console.log(`  ✓ InMails: ${results.inmails.length}`);
  console.log(`  ✗ Errors: ${results.errors.length}`);

  if (results.errors.length > 0) {
    console.log('\nErrors:');
    results.errors.forEach(e => console.log(`  - ${e.name}: ${e.error}`));
  }

  console.log('\n✨ Done!');
}

/**
 * Infer website URL from company name
 */
async function inferWebsiteUrl(companyName) {
  if (!companyName) return null;

  // Simple inference - could be enhanced with a web search
  const slug = companyName
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '')
    .slice(0, 30);

  // Try common patterns
  const patterns = [
    `https://${slug}.com`,
    `https://www.${slug}.com`,
    `https://${slug}.io`,
    `https://get${slug}.com`,
    `https://try${slug}.com`
  ];

  // Just return the first pattern - the scraper will handle 404s
  return patterns[0];
}

/**
 * Sleep helper
 */
function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

// Run
main().catch(error => {
  console.error('Fatal error:', error);
  process.exit(1);
});

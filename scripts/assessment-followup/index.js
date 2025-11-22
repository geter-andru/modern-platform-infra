/**
 * Assessment Follow-up Agent
 * Generates personalized follow-up emails for users who completed assessments
 */

import Anthropic from '@anthropic-ai/sdk';
import { createClient } from '@supabase/supabase-js';
import fs from 'fs/promises';
import path from 'path';

const anthropic = new Anthropic();

// Initialize Supabase client
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_KEY;

if (!supabaseUrl || !supabaseKey) {
  console.error('Missing SUPABASE_URL or SUPABASE_SERVICE_KEY');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

// Path configuration
const __dirname = path.dirname(new URL(import.meta.url).pathname);
const INFRA_ROOT = path.resolve(__dirname, '../..');
const OUTPUT_ROOT = process.env.OUTPUT_ROOT || INFRA_ROOT;
const DAYS_BACK = parseInt(process.env.DAYS_BACK || '1', 10);

/**
 * Fetch recent assessment completions
 */
async function fetchRecentAssessments() {
  const daysAgo = new Date();
  daysAgo.setDate(daysAgo.getDate() - DAYS_BACK);

  console.log(`Fetching assessments from last ${DAYS_BACK} day(s)...`);

  const { data, error } = await supabase
    .from('assessment_results')
    .select(`
      id,
      user_id,
      scenario_slug,
      total_score,
      category_scores,
      created_at,
      profiles:user_id (
        email,
        full_name,
        company_name
      )
    `)
    .gte('created_at', daysAgo.toISOString())
    .order('created_at', { ascending: false });

  if (error) {
    console.error('Error fetching assessments:', error);
    return [];
  }

  return data || [];
}

/**
 * Load scenario data for context
 */
async function loadScenarioData(slug) {
  try {
    // Try to fetch from frontend data
    const scenariosPath = path.join(INFRA_ROOT, '..', 'frontend', 'data', 'scenarios.json');
    const content = await fs.readFile(scenariosPath, 'utf-8');
    const scenarios = JSON.parse(content);
    return scenarios.find(s => s.slug === slug);
  } catch (error) {
    console.log(`Could not load scenario data for ${slug}`);
    return null;
  }
}

/**
 * Analyze assessment scores for personalization
 */
function analyzeScores(categoryScores) {
  const analysis = {
    strengths: [],
    opportunities: []
  };

  for (const [category, score] of Object.entries(categoryScores || {})) {
    if (score >= 70) {
      analysis.strengths.push(category);
    } else if (score < 50) {
      analysis.opportunities.push(category);
    }
  }

  return analysis;
}

/**
 * Generate personalized follow-up email
 */
async function generateFollowUp(assessment, scenario) {
  const analysis = analyzeScores(assessment.category_scores);
  const profile = assessment.profiles;

  const prompt = `You are Brandon Geter, founder of Andru - an AI-powered Revenue Intelligence Platform for B2B SaaS founders.

Generate a personalized follow-up email for someone who just completed our sales readiness assessment.

## RECIPIENT INFO:
- Name: ${profile?.full_name || 'there'}
- Company: ${profile?.company_name || 'your company'}
- Email: ${profile?.email || 'unknown'}
- Scenario viewed: ${scenario?.company || assessment.scenario_slug}

## ASSESSMENT RESULTS:
- Overall Score: ${assessment.total_score}%
- Strengths: ${analysis.strengths.join(', ') || 'Still discovering'}
- Growth Areas: ${analysis.opportunities.join(', ') || 'Strong across the board'}

## SCENARIO CONTEXT (if available):
${scenario ? `
Company Profile: ${scenario.company}
Key Challenge: ${scenario.persona?.challenge || 'Enterprise sales transformation'}
` : 'No specific scenario data'}

## BRANDON'S BACKGROUND (for credibility):
- 9 years SaaS sales (Apttus, Sumo Logic, Graphite, OpsLevel)
- Generated $30M+ in pipeline across 7 companies
- Built Andru in 4 months with zero coding background

## EMAIL REQUIREMENTS:
1. Subject line: Personalized, not salesy, reference their score
2. Opening: Acknowledge their assessment completion, mention specific strength
3. Value: One specific insight based on their growth areas
4. CTA: Offer a 15-min call to discuss findings (not pushy)
5. Signature: Brandon Geter, Founder @ Andru

TONE: Helpful, founder-to-founder, genuine. NOT salesy or generic.

Generate the email in this format:
SUBJECT: [subject line]

[email body]`;

  try {
    const response = await anthropic.messages.create({
      model: 'claude-sonnet-4-20250514',
      max_tokens: 1000,
      messages: [{ role: 'user', content: prompt }]
    });

    return response.content[0].text;
  } catch (error) {
    console.error('Error generating follow-up:', error.message);
    return null;
  }
}

/**
 * Save follow-up draft to file
 */
async function saveFollowUp(assessment, emailContent) {
  const draftsDir = path.join(OUTPUT_ROOT, 'followup/drafts');
  await fs.mkdir(draftsDir, { recursive: true });

  const date = new Date().toISOString().split('T')[0];
  const profile = assessment.profiles;
  const slug = (profile?.email || 'unknown')
    .replace('@', '_at_')
    .replace(/[^a-z0-9_]+/gi, '-')
    .slice(0, 40);

  const filename = `${date}_${slug}.md`;
  const filepath = path.join(draftsDir, filename);

  const fileContent = `# Follow-up Draft - ${date}

## Recipient
- **Name:** ${profile?.full_name || 'Unknown'}
- **Email:** ${profile?.email || 'Unknown'}
- **Company:** ${profile?.company_name || 'Unknown'}

## Assessment Summary
- **Score:** ${assessment.total_score}%
- **Scenario:** ${assessment.scenario_slug}
- **Completed:** ${assessment.created_at}

---

## Email Draft

${emailContent}

---

## Status
- [ ] Reviewed
- [ ] Personalized
- [ ] Sent
- [ ] Demo Scheduled
`;

  await fs.writeFile(filepath, fileContent, 'utf-8');
  console.log(`  ✅ Saved: ${filename}`);
  return filename;
}

/**
 * Main execution
 */
async function main() {
  console.log('🚀 Assessment Follow-up Agent Starting...\n');

  // Fetch recent assessments
  const assessments = await fetchRecentAssessments();
  console.log(`Found ${assessments.length} assessment(s) to process\n`);

  if (assessments.length === 0) {
    console.log('No new assessments to process. Exiting.');
    return;
  }

  const savedFiles = [];

  for (const assessment of assessments) {
    const profile = assessment.profiles;
    console.log(`\n📝 Processing: ${profile?.email || assessment.id}`);

    // Load scenario context
    const scenario = await loadScenarioData(assessment.scenario_slug);

    // Generate personalized follow-up
    console.log('  → Generating follow-up email...');
    const emailContent = await generateFollowUp(assessment, scenario);

    if (emailContent) {
      const filename = await saveFollowUp(assessment, emailContent);
      savedFiles.push(filename);
    }
  }

  console.log(`\n✨ Generated ${savedFiles.length} follow-up draft(s)`);
}

main().catch(console.error);

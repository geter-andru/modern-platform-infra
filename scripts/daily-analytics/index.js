/**
 * Daily Analytics Report Generator
 * Generates insights from platform metrics with AI analysis
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

/**
 * Fetch metrics for a time period
 */
async function fetchMetrics(daysBack = 1) {
  const endDate = new Date();
  const startDate = new Date();
  startDate.setDate(startDate.getDate() - daysBack);

  const metrics = {};

  // 1. Page views and engagement
  try {
    const { data: pageViews } = await supabase
      .from('public_page_analytics')
      .select('page_path, event_type, created_at')
      .gte('created_at', startDate.toISOString())
      .lte('created_at', endDate.toISOString());

    metrics.pageViews = pageViews || [];
  } catch (e) {
    metrics.pageViews = [];
  }

  // 2. Assessment starts and completions
  try {
    const { data: assessments } = await supabase
      .from('assessment_results')
      .select('id, total_score, scenario_slug, created_at')
      .gte('created_at', startDate.toISOString())
      .lte('created_at', endDate.toISOString());

    metrics.assessments = assessments || [];
  } catch (e) {
    metrics.assessments = [];
  }

  // 3. New user signups
  try {
    const { data: signups } = await supabase
      .from('profiles')
      .select('id, created_at')
      .gte('created_at', startDate.toISOString())
      .lte('created_at', endDate.toISOString());

    metrics.signups = signups || [];
  } catch (e) {
    metrics.signups = [];
  }

  // 4. CTA clicks
  try {
    const { data: ctaClicks } = await supabase
      .from('public_page_analytics')
      .select('*')
      .eq('event_type', 'cta_click')
      .gte('created_at', startDate.toISOString())
      .lte('created_at', endDate.toISOString());

    metrics.ctaClicks = ctaClicks || [];
  } catch (e) {
    metrics.ctaClicks = [];
  }

  return metrics;
}

/**
 * Calculate funnel metrics
 */
function calculateFunnel(metrics) {
  const funnel = {
    visits: new Set(metrics.pageViews.map(pv => pv.session_id || pv.id)).size,
    assessmentStarts: metrics.pageViews.filter(pv =>
      pv.page_path?.includes('/assessment') && pv.event_type === 'page_view'
    ).length,
    assessmentCompletes: metrics.assessments.length,
    signups: metrics.signups.length,
    ctaClicks: metrics.ctaClicks.length
  };

  // Calculate conversion rates
  funnel.conversionRates = {
    visitToAssessment: funnel.visits > 0
      ? ((funnel.assessmentStarts / funnel.visits) * 100).toFixed(1)
      : 0,
    assessmentCompletion: funnel.assessmentStarts > 0
      ? ((funnel.assessmentCompletes / funnel.assessmentStarts) * 100).toFixed(1)
      : 0,
    assessmentToSignup: funnel.assessmentCompletes > 0
      ? ((funnel.signups / funnel.assessmentCompletes) * 100).toFixed(1)
      : 0
  };

  return funnel;
}

/**
 * Analyze scenario performance
 */
function analyzeScenarios(metrics) {
  const scenarioStats = {};

  // Count page views per scenario
  metrics.pageViews.forEach(pv => {
    const match = pv.page_path?.match(/\/icp\/([^\/]+)/);
    if (match) {
      const slug = match[1];
      scenarioStats[slug] = scenarioStats[slug] || { views: 0, ctaClicks: 0, completions: 0 };
      scenarioStats[slug].views++;
    }
  });

  // Count CTA clicks per scenario
  metrics.ctaClicks.forEach(click => {
    const match = click.page_path?.match(/\/icp\/([^\/]+)/);
    if (match) {
      const slug = match[1];
      if (scenarioStats[slug]) {
        scenarioStats[slug].ctaClicks++;
      }
    }
  });

  // Count assessment completions per scenario
  metrics.assessments.forEach(a => {
    if (scenarioStats[a.scenario_slug]) {
      scenarioStats[a.scenario_slug].completions++;
    }
  });

  return scenarioStats;
}

/**
 * Generate AI insights
 */
async function generateInsights(metrics, funnel, scenarioStats) {
  const prompt = `Analyze these daily platform metrics and provide actionable insights:

## FUNNEL METRICS
- Total Visits: ${funnel.visits}
- Assessment Page Views: ${funnel.assessmentStarts}
- Assessment Completions: ${funnel.assessmentCompletes}
- New Signups: ${funnel.signups}
- CTA Clicks: ${funnel.ctaClicks}

## CONVERSION RATES
- Visit → Assessment: ${funnel.conversionRates.visitToAssessment}%
- Assessment Start → Complete: ${funnel.conversionRates.assessmentCompletion}%
- Assessment → Signup: ${funnel.conversionRates.assessmentToSignup}%

## SCENARIO PERFORMANCE
${Object.entries(scenarioStats).map(([slug, stats]) =>
  `- ${slug}: ${stats.views} views, ${stats.ctaClicks} CTA clicks, ${stats.completions} completions`
).join('\n')}

## CONTEXT
This is a B2B SaaS platform (Andru) helping technical founders with sales.
Target: early-stage founders, especially those with technical backgrounds.

Provide:
1. **Key Observation** - Most significant finding (one line)
2. **Alerts** - Any concerning metrics (use ⚠️ for warning, 🔴 for critical)
3. **Opportunities** - 2-3 actionable improvements
4. **Top Performing Scenario** - Which scenario is converting best and why
5. **Recommendation** - One specific action to take today

Keep it concise and actionable. No fluff.`;

  try {
    const response = await anthropic.messages.create({
      model: 'claude-sonnet-4-20250514',
      max_tokens: 800,
      messages: [{ role: 'user', content: prompt }]
    });

    return response.content[0].text;
  } catch (error) {
    console.error('Error generating insights:', error.message);
    return 'Unable to generate AI insights.';
  }
}

/**
 * Generate the report
 */
async function generateReport() {
  console.log('📊 Fetching metrics...');

  // Get today's metrics and comparison
  const todayMetrics = await fetchMetrics(1);
  const weekMetrics = await fetchMetrics(7);

  console.log('📈 Calculating funnel...');
  const todayFunnel = calculateFunnel(todayMetrics);
  const weekFunnel = calculateFunnel(weekMetrics);

  console.log('🎯 Analyzing scenarios...');
  const scenarioStats = analyzeScenarios(todayMetrics);

  console.log('🤖 Generating AI insights...');
  const insights = await generateInsights(todayMetrics, todayFunnel, scenarioStats);

  const date = new Date().toISOString().split('T')[0];

  const report = `# Daily Analytics Report - ${date}

## 📊 Today's Metrics

| Metric | Today | 7-Day Avg |
|--------|-------|-----------|
| Visits | ${todayFunnel.visits} | ${Math.round(weekFunnel.visits / 7)} |
| Assessment Starts | ${todayFunnel.assessmentStarts} | ${Math.round(weekFunnel.assessmentStarts / 7)} |
| Assessment Completes | ${todayFunnel.assessmentCompletes} | ${Math.round(weekFunnel.assessmentCompletes / 7)} |
| Signups | ${todayFunnel.signups} | ${Math.round(weekFunnel.signups / 7)} |
| CTA Clicks | ${todayFunnel.ctaClicks} | ${Math.round(weekFunnel.ctaClicks / 7)} |

## 🔄 Conversion Rates

| Stage | Rate |
|-------|------|
| Visit → Assessment | ${todayFunnel.conversionRates.visitToAssessment}% |
| Assessment Start → Complete | ${todayFunnel.conversionRates.assessmentCompletion}% |
| Assessment → Signup | ${todayFunnel.conversionRates.assessmentToSignup}% |

## 🎯 Scenario Performance

| Scenario | Views | CTA Clicks | Completions | CTR |
|----------|-------|------------|-------------|-----|
${Object.entries(scenarioStats).map(([slug, stats]) =>
  `| ${slug} | ${stats.views} | ${stats.ctaClicks} | ${stats.completions} | ${stats.views > 0 ? ((stats.ctaClicks / stats.views) * 100).toFixed(1) : 0}% |`
).join('\n')}

## 🤖 AI Insights

${insights}

---

*Generated at ${new Date().toISOString()}*
`;

  return report;
}

/**
 * Save report to file
 */
async function saveReport(report) {
  const reportsDir = path.join(OUTPUT_ROOT, 'analytics/reports');
  await fs.mkdir(reportsDir, { recursive: true });

  const date = new Date().toISOString().split('T')[0];
  const filename = `${date}.md`;
  const filepath = path.join(reportsDir, filename);

  await fs.writeFile(filepath, report, 'utf-8');
  console.log(`✅ Saved: ${filename}`);

  return filename;
}

/**
 * Main execution
 */
async function main() {
  console.log('🚀 Daily Analytics Report Starting...\n');

  const report = await generateReport();
  await saveReport(report);

  console.log('\n✨ Report generated successfully!');
}

main().catch(console.error);

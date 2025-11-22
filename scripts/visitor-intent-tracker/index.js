/**
 * Website Visitor Intent Tracker
 * Analyzes visitor behavior to identify high-intent prospects
 */

import { createClient } from '@supabase/supabase-js';
import Anthropic from '@anthropic-ai/sdk';
import fs from 'fs/promises';
import path from 'path';

const anthropic = new Anthropic();

// Configuration
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_KEY;
const OUTPUT_ROOT = process.env.OUTPUT_ROOT || process.cwd();

if (!supabaseUrl || !supabaseKey) {
  console.error('❌ SUPABASE_URL and SUPABASE_SERVICE_KEY are required');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

// High-intent page patterns
const HIGH_INTENT_PAGES = {
  critical: ['/pricing', '/demo', '/contact', '/signup'],
  high: ['/assessment', '/icp/'],
  medium: ['/about', '/features', '/how-it-works']
};

/**
 * Main execution
 */
async function main() {
  console.log('🔥 Visitor Intent Tracker Starting...\n');

  // Get yesterday's date range
  const endDate = new Date();
  const startDate = new Date();
  startDate.setDate(startDate.getDate() - 1);
  startDate.setHours(0, 0, 0, 0);
  endDate.setHours(0, 0, 0, 0);

  console.log(`📅 Analyzing visitors from ${startDate.toISOString().split('T')[0]}\n`);

  // Fetch analytics data
  const visitors = await fetchVisitorData(startDate, endDate);
  console.log(`📊 Found ${visitors.length} unique visitor sessions\n`);

  // Analyze intent for each visitor
  const analyzedVisitors = [];
  for (const visitor of visitors) {
    const analysis = analyzeIntent(visitor);
    if (analysis.intentLevel !== 'low') {
      analysis.suggestedAction = await generateOutreachSuggestion(analysis);
      analyzedVisitors.push(analysis);
    }
  }

  // Sort by intent level
  const intentOrder = { hot: 0, warm: 1, medium: 2 };
  analyzedVisitors.sort((a, b) => intentOrder[a.intentLevel] - intentOrder[b.intentLevel]);

  console.log(`\n🎯 Intent Analysis Results:`);
  console.log(`  🔥 Hot: ${analyzedVisitors.filter(v => v.intentLevel === 'hot').length}`);
  console.log(`  🟠 Warm: ${analyzedVisitors.filter(v => v.intentLevel === 'warm').length}`);
  console.log(`  🟡 Medium: ${analyzedVisitors.filter(v => v.intentLevel === 'medium').length}`);

  // Save results
  await saveResults(analyzedVisitors);

  console.log('\n✨ Done!');
}

/**
 * Fetch visitor data from Supabase
 */
async function fetchVisitorData(startDate, endDate) {
  const visitors = new Map();

  try {
    // Fetch page views
    const { data: pageViews, error } = await supabase
      .from('public_page_analytics')
      .select('*')
      .gte('created_at', startDate.toISOString())
      .lt('created_at', endDate.toISOString())
      .order('created_at', { ascending: true });

    if (error) throw error;

    // Group by session/visitor
    for (const pv of pageViews || []) {
      const sessionId = pv.session_id || pv.visitor_id || pv.id;

      if (!visitors.has(sessionId)) {
        visitors.set(sessionId, {
          sessionId,
          pageViews: [],
          events: [],
          firstVisit: pv.created_at,
          lastVisit: pv.created_at,
          utmSource: pv.utm_source,
          utmMedium: pv.utm_medium,
          utmCampaign: pv.utm_campaign,
          referrer: pv.referrer
        });
      }

      const visitor = visitors.get(sessionId);
      visitor.pageViews.push({
        path: pv.page_path,
        eventType: pv.event_type,
        timestamp: pv.created_at,
        metadata: pv.metadata
      });
      visitor.lastVisit = pv.created_at;

      if (pv.event_type && pv.event_type !== 'page_view') {
        visitor.events.push({
          type: pv.event_type,
          path: pv.page_path,
          timestamp: pv.created_at
        });
      }
    }

    // Try to enrich with profile data if available
    const { data: profiles } = await supabase
      .from('profiles')
      .select('id, email, company_name, created_at')
      .gte('created_at', startDate.toISOString())
      .lt('created_at', endDate.toISOString());

    // Match profiles to sessions if possible
    // (This is simplified - in production you'd have better session tracking)

  } catch (error) {
    console.error('Error fetching visitor data:', error.message);
  }

  return Array.from(visitors.values());
}

/**
 * Analyze visitor intent based on behavior
 */
function analyzeIntent(visitor) {
  let intentScore = 0;
  const signals = [];
  const pagesViewed = [...new Set(visitor.pageViews.map(pv => pv.path))];

  // Score based on pages visited
  for (const page of pagesViewed) {
    if (HIGH_INTENT_PAGES.critical.some(p => page.includes(p))) {
      intentScore += 30;
      signals.push(`Visited critical page: ${page}`);
    } else if (HIGH_INTENT_PAGES.high.some(p => page.includes(p))) {
      intentScore += 20;
      signals.push(`Visited high-intent page: ${page}`);
    } else if (HIGH_INTENT_PAGES.medium.some(p => page.includes(p))) {
      intentScore += 10;
      signals.push(`Visited medium-intent page: ${page}`);
    }
  }

  // Score based on events
  for (const event of visitor.events) {
    if (event.type === 'cta_click') {
      intentScore += 25;
      signals.push(`Clicked CTA on ${event.path}`);
    }
    if (event.type === 'assessment_started') {
      intentScore += 30;
      signals.push('Started assessment');
    }
    if (event.type === 'assessment_completed') {
      intentScore += 40;
      signals.push('Completed assessment');
    }
    if (event.type === 'completion_detected') {
      intentScore += 15;
      signals.push('Read full page content');
    }
  }

  // Score based on engagement depth
  const uniquePages = pagesViewed.length;
  if (uniquePages >= 5) {
    intentScore += 20;
    signals.push(`Deep engagement: ${uniquePages} pages`);
  } else if (uniquePages >= 3) {
    intentScore += 10;
    signals.push(`Good engagement: ${uniquePages} pages`);
  }

  // Score based on return visits
  const visitDuration = new Date(visitor.lastVisit) - new Date(visitor.firstVisit);
  const minutesOnSite = Math.round(visitDuration / 60000);

  if (minutesOnSite > 10) {
    intentScore += 15;
    signals.push(`Long session: ${minutesOnSite} minutes`);
  }

  // Score based on ICP page visits (specific company scenario)
  const icpPages = pagesViewed.filter(p => p.includes('/icp/'));
  if (icpPages.length > 0) {
    intentScore += 25;
    signals.push(`Viewed ICP scenarios: ${icpPages.join(', ')}`);
  }

  // Determine intent level
  let intentLevel = 'low';
  if (intentScore >= 60) {
    intentLevel = 'hot';
  } else if (intentScore >= 40) {
    intentLevel = 'warm';
  } else if (intentScore >= 20) {
    intentLevel = 'medium';
  }

  // Extract company from ICP page if available
  let company = null;
  const icpMatch = pagesViewed.find(p => p.match(/\/icp\/([^\/]+)/));
  if (icpMatch) {
    const slug = icpMatch.match(/\/icp\/([^\/]+)/)[1];
    company = slug.split('-').map(w => w.charAt(0).toUpperCase() + w.slice(1)).join(' ');
  }

  return {
    sessionId: visitor.sessionId,
    company,
    pagesViewed,
    events: visitor.events,
    firstVisit: visitor.firstVisit,
    lastVisit: visitor.lastVisit,
    totalTime: `${minutesOnSite} minutes`,
    utmSource: visitor.utmSource,
    utmCampaign: visitor.utmCampaign,
    intentScore,
    intentLevel,
    signals
  };
}

/**
 * Generate outreach suggestion using Claude
 */
async function generateOutreachSuggestion(visitor) {
  const prompt = `Based on this website visitor's behavior, suggest a specific outreach action.

## VISITOR BEHAVIOR
- Intent Level: ${visitor.intentLevel}
- Pages Viewed: ${visitor.pagesViewed.join(', ')}
- Signals: ${visitor.signals.join('; ')}
- Time on Site: ${visitor.totalTime}
- UTM Source: ${visitor.utmSource || 'direct'}
${visitor.company ? `- Company (from ICP page): ${visitor.company}` : ''}

## SUGGEST
One specific, actionable outreach suggestion (1-2 sentences). Consider:
- If they viewed an ICP page, reference that company's scenario
- If they started but didn't complete assessment, encourage completion
- If high intent, suggest direct outreach
- Be specific about the action to take

Output ONLY the suggestion, no explanation.`;

  try {
    const response = await anthropic.messages.create({
      model: 'claude-sonnet-4-20250514',
      max_tokens: 100,
      messages: [{ role: 'user', content: prompt }]
    });

    return response.content[0].text.trim();
  } catch (error) {
    return 'Review visitor journey and send personalized follow-up based on pages viewed.';
  }
}

/**
 * Save results to file
 */
async function saveResults(visitors) {
  const outputDir = path.join(OUTPUT_ROOT, 'intent-signals/daily');
  await fs.mkdir(outputDir, { recursive: true });

  const date = new Date();
  date.setDate(date.getDate() - 1); // Yesterday
  const dateStr = date.toISOString().split('T')[0];
  const filename = `${dateStr}.json`;
  const filepath = path.join(outputDir, filename);

  const output = {
    date: dateStr,
    totalVisitors: visitors.length,
    hot: visitors.filter(v => v.intentLevel === 'hot').length,
    warm: visitors.filter(v => v.intentLevel === 'warm').length,
    medium: visitors.filter(v => v.intentLevel === 'medium').length,
    visitors
  };

  await fs.writeFile(filepath, JSON.stringify(output, null, 2), 'utf-8');
  console.log(`\n💾 Saved: ${filename}`);
}

// Run
main().catch(error => {
  console.error('Fatal error:', error);
  process.exit(1);
});

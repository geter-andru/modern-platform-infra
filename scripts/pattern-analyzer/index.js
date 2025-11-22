/**
 * Pattern Analyzer
 * Analyzes complaints to identify recurring patterns and exact language
 * Runs weekly to aggregate insights
 */

import Anthropic from '@anthropic-ai/sdk';
import { createClient } from '@supabase/supabase-js';

const anthropic = new Anthropic();

// Configuration
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_KEY;
const LOOKBACK_DAYS = parseInt(process.env.LOOKBACK_DAYS || '7');

if (!supabaseUrl || !supabaseKey) {
  console.error('❌ SUPABASE_URL and SUPABASE_SERVICE_KEY are required');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

/**
 * Main execution
 */
async function main() {
  console.log('📊 Pattern Analyzer Starting...\n');
  console.log(`Analyzing complaints from the last ${LOOKBACK_DAYS} days\n`);

  try {
    // 1. Fetch unprocessed complaints
    const lookbackDate = new Date();
    lookbackDate.setDate(lookbackDate.getDate() - LOOKBACK_DAYS);

    const { data: complaints, error: fetchError } = await supabase
      .from('complaints')
      .select('*')
      .eq('is_processed', false)
      .gte('created_at', lookbackDate.toISOString())
      .order('pain_score', { ascending: false });

    if (fetchError) {
      throw new Error(`Failed to fetch complaints: ${fetchError.message}`);
    }

    console.log(`📋 Found ${complaints?.length || 0} unprocessed complaints\n`);

    if (!complaints || complaints.length === 0) {
      console.log('No new complaints to analyze. Exiting.');
      return;
    }

    // 2. Group complaints by category for analysis
    const byCategory = {};
    for (const complaint of complaints) {
      const cat = complaint.category || 'other';
      if (!byCategory[cat]) byCategory[cat] = [];
      byCategory[cat].push(complaint);
    }

    console.log('Categories found:', Object.keys(byCategory).join(', '));

    // 3. Analyze patterns with Claude
    const patterns = await analyzePatterns(complaints);
    console.log(`\n🎯 Identified ${patterns.length} patterns\n`);

    // 4. Save/update patterns in Supabase
    let newPatterns = 0;
    let updatedPatterns = 0;

    for (const pattern of patterns) {
      // Check if pattern already exists
      const { data: existing } = await supabase
        .from('complaint_patterns')
        .select('id, frequency_count, complaint_ids, key_phrases')
        .eq('problem_statement', pattern.problem_statement)
        .single();

      if (existing) {
        // Update existing pattern
        const existingIds = existing.complaint_ids || [];
        const newIds = [...new Set([...existingIds, ...pattern.complaint_ids])];

        const existingPhrases = existing.key_phrases || [];
        const newPhrases = [...new Set([...existingPhrases, ...pattern.key_phrases])].slice(0, 20);

        await supabase
          .from('complaint_patterns')
          .update({
            frequency_count: existing.frequency_count + pattern.frequency_count,
            last_seen_at: new Date().toISOString(),
            complaint_ids: newIds,
            key_phrases: newPhrases,
            avg_pain_score: pattern.avg_pain_score,
            platforms: pattern.platforms
          })
          .eq('id', existing.id);

        updatedPatterns++;
      } else {
        // Insert new pattern
        await supabase
          .from('complaint_patterns')
          .insert({
            problem_statement: pattern.problem_statement,
            category: pattern.category,
            frequency_count: pattern.frequency_count,
            key_phrases: pattern.key_phrases,
            avg_pain_score: pattern.avg_pain_score,
            complaint_ids: pattern.complaint_ids,
            platforms: pattern.platforms,
            is_actionable: pattern.is_actionable
          });

        newPatterns++;
      }
    }

    // 5. Mark complaints as processed
    const complaintIds = complaints.map(c => c.id);
    await supabase
      .from('complaints')
      .update({ is_processed: true })
      .in('id', complaintIds);

    // 6. Generate summary for GitHub Action
    const topPatterns = patterns
      .sort((a, b) => b.frequency_count - a.frequency_count)
      .slice(0, 10);

    console.log('\n📊 Top Patterns This Week:');
    for (let i = 0; i < topPatterns.length; i++) {
      const p = topPatterns[i];
      console.log(`  ${i + 1}. [${p.category}] ${p.problem_statement}`);
      console.log(`     Pain: ${p.avg_pain_score}/10 | Frequency: ${p.frequency_count}`);
      console.log(`     Phrases: "${p.key_phrases.slice(0, 3).join('", "')}"`);
    }

    // Export for GitHub Action
    const fs = await import('fs');
    const envFile = process.env.GITHUB_ENV;
    if (envFile) {
      fs.appendFileSync(envFile, `NEW_PATTERNS=${newPatterns}\n`);
      fs.appendFileSync(envFile, `UPDATED_PATTERNS=${updatedPatterns}\n`);
      fs.appendFileSync(envFile, `COMPLAINTS_PROCESSED=${complaints.length}\n`);

      // Export top pattern for issue title
      if (topPatterns.length > 0) {
        fs.appendFileSync(envFile, `TOP_PATTERN=${topPatterns[0].problem_statement.slice(0, 50)}\n`);
      }
    }

    console.log('\n📊 Summary:');
    console.log(`  Complaints processed: ${complaints.length}`);
    console.log(`  New patterns: ${newPatterns}`);
    console.log(`  Updated patterns: ${updatedPatterns}`);
    console.log('\n✨ Done!');

  } catch (error) {
    console.error('Fatal error:', error);
    process.exit(1);
  }
}

/**
 * Analyze complaints to identify patterns using Claude
 */
async function analyzePatterns(complaints) {
  // Prepare complaint summaries for Claude
  const complaintSummaries = complaints.map(c => ({
    id: c.id,
    category: c.category,
    problem: c.extracted_problem,
    phrases: c.exact_phrases,
    painScore: c.pain_score,
    platform: c.platform
  }));

  const prompt = `You are analyzing user complaints from Reddit, Quora, and other platforms to identify patterns in B2B SaaS founder pain points.

## COMPLAINTS TO ANALYZE
${JSON.stringify(complaintSummaries, null, 2)}

## YOUR TASK
1. Group similar complaints into patterns
2. For each pattern, identify:
   - A clear problem statement (1 sentence)
   - The category (validation, sales, product, hiring, marketing, fundraising, operations, other)
   - Key phrases people use (EXACT quotes from the complaints)
   - Average pain score
   - Which platforms this appears on
   - Is this actionable (can we help with this)?

## OUTPUT FORMAT
Return a JSON array of patterns:
[
  {
    "problem_statement": "Founders don't know how to identify their ideal customer profile",
    "category": "validation",
    "frequency_count": 5,
    "key_phrases": ["don't know who to sell to", "everyone is my customer", "keep pivoting"],
    "avg_pain_score": 7.5,
    "complaint_ids": ["uuid1", "uuid2"],
    "platforms": ["reddit", "quora"],
    "is_actionable": true
  }
]

Important:
- Combine truly similar problems (don't create too many patterns)
- Use EXACT phrases from the complaints when possible
- Include complaint IDs for each pattern
- Minimum 3 complaints to form a pattern (unless pain score is 9+)

Return ONLY the JSON array, no other text.`;

  try {
    const response = await anthropic.messages.create({
      model: 'claude-sonnet-4-20250514',
      max_tokens: 4000,
      messages: [{ role: 'user', content: prompt }]
    });

    const text = response.content[0].text;
    const jsonMatch = text.match(/\[[\s\S]*\]/);

    if (jsonMatch) {
      return JSON.parse(jsonMatch[0]);
    }

    console.error('Could not parse patterns from Claude response');
    return [];

  } catch (error) {
    console.error('Error analyzing patterns:', error.message);
    return [];
  }
}

// Run
main().catch(console.error);

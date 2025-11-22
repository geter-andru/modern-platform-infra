/**
 * Scenario Generator
 * Uses Claude to generate ICP scenarios based on company research
 */

import Anthropic from '@anthropic-ai/sdk';

const anthropic = new Anthropic();

/**
 * Generate a complete scenario for a company
 */
export async function generateScenario(enrichedProfile, companyInfo) {
  console.log(`  🎯 Generating scenario for: ${enrichedProfile.company}`);

  const prompt = buildScenarioPrompt(enrichedProfile, companyInfo);

  try {
    const response = await anthropic.messages.create({
      model: 'claude-sonnet-4-20250514',
      max_tokens: 4000,
      messages: [{
        role: 'user',
        content: prompt
      }]
    });

    const content = response.content[0].text;

    // Parse JSON from response
    const jsonMatch = content.match(/```json\n?([\s\S]*?)\n?```/) ||
                      content.match(/\{[\s\S]*"company"[\s\S]*"timestamps"[\s\S]*\}/);

    if (jsonMatch) {
      const jsonStr = jsonMatch[1] || jsonMatch[0];
      const scenario = JSON.parse(jsonStr);

      // Validate required fields
      if (!scenario.company || !scenario.slug || !scenario.timestamps) {
        throw new Error('Missing required scenario fields');
      }

      console.log(`    ✓ Generated scenario: "${scenario.title}"`);
      return scenario;
    }

    throw new Error('Could not parse scenario JSON from response');

  } catch (error) {
    console.error(`    ✗ Error generating scenario: ${error.message}`);
    return null;
  }
}

/**
 * Build the scenario generation prompt
 */
function buildScenarioPrompt(profile, companyInfo) {
  const slug = generateSlug(profile.company);

  return `You are an expert at creating compelling B2B SaaS buyer journey scenarios. Generate a scenario JSON for the following company.

## COMPANY INFORMATION

**Company:** ${profile.company}
**Founder/Contact:** ${profile.name} (${profile.headline})
**LinkedIn About:** ${profile.about || 'Not available'}
**Recent Posts:** ${profile.recentPosts?.join(' | ') || 'None found'}

${companyInfo ? `
**Website:** ${companyInfo.url}
**Tagline:** ${companyInfo.tagline || 'N/A'}
**Description:** ${companyInfo.description || 'N/A'}
**Features:** ${companyInfo.features?.join(', ') || 'N/A'}
**Target Audience:** ${companyInfo.targetAudience || 'N/A'}
**Raw Website Content:**
${companyInfo.rawContent?.slice(0, 2000) || 'N/A'}
` : 'No website data available'}

${profile.lusha ? `
**Industry:** ${profile.lusha.industry || 'Unknown'}
**Company Size:** ${profile.lusha.companySize || 'Unknown'}
**Funding Stage:** ${profile.lusha.fundingStage || 'Unknown'}
` : ''}

## SCENARIO FORMAT

Create a JSON scenario following this EXACT structure:

\`\`\`json
{
  "company": "${profile.company}",
  "slug": "${slug}",
  "title": "[Persona Title] [Outcome/Achievement Verb] [Specific Business Result]",
  "persona": "[Decision Maker Title, e.g., VP of Engineering, Head of Sales, CTO]",
  "scenario": "It's [time] on a [day], [context]. [Name] ([title], [MBTI type]) just [triggering event that creates urgency].",
  "worstCase": "[Specific negative outcome if they don't solve the problem - include numbers, timeline, business impact]",
  "timestamps": [
    {
      "time": "[Time] - The [Emotional State]",
      "narrative": "[Scene description with specific details, numbers in <strong> tags]",
      "thinking": "[Internal monologue showing problem analysis]",
      "feeling": "[Emotional state driving urgency]",
      "action": "[What they do - can be empty for first timestamp]",
      "momentOfValue": ""
    },
    {
      "time": "[Time] - The Discovery",
      "narrative": "[How they discover ${profile.company} - organic, referral, search]",
      "thinking": "[Why this solution makes sense for their specific situation]",
      "feeling": "[Hope/skepticism/curiosity]",
      "action": "[First interaction with the product]",
      "momentOfValue": ""
    },
    {
      "time": "[Time] - The Resolution",
      "narrative": "[How the product solves their problem with specific results]",
      "thinking": "[Realization of value - connect to business outcomes]",
      "feeling": "[Relief, confidence, vindication]",
      "action": "[Next steps, sharing with team, etc.]",
      "momentOfValue": "${profile.company} [specific measurable outcome - include numbers, time saved, money saved, risk avoided]."
    }
  ]
}
\`\`\`

## REQUIREMENTS

1. **Research the actual product** - Use the website content to understand what ${profile.company} actually does
2. **Match the persona to the buyer** - Who actually makes purchasing decisions for this product?
3. **Create realistic urgency** - A specific deadline, crisis, or opportunity that forces action
4. **Include specific numbers** - Revenue at risk, time pressure, cost implications
5. **Use <strong> tags** for emphasis on key metrics and numbers
6. **The momentOfValue** must be specific and measurable - not generic

## EXAMPLE PATTERNS

Title patterns that work:
- "VP of Engineering Preventing Production Bug Crisis" (Greptile)
- "DevOps Lead Avoiding the Deployment Deadline Miss" (Blacksmith)
- "VP of Engineering Avoiding the Enterprise Deal Blocker" (Delve)

Scenario opening patterns:
- "It's 9:14 AM on a Monday, two days before their Series B product demo..."
- "It's 2:43 PM on a Thursday, 4 hours before the committed deployment window..."

Generate the scenario JSON now. Respond ONLY with the JSON in a code block.`;
}

/**
 * Generate URL-safe slug from company name
 */
function generateSlug(companyName) {
  return companyName
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 50);
}

/**
 * Add scenario to existing scenarios array
 */
export function mergeScenario(existingScenarios, newScenario) {
  // Check if scenario for this company already exists
  const existingIndex = existingScenarios.findIndex(
    s => s.slug === newScenario.slug || s.company.toLowerCase() === newScenario.company.toLowerCase()
  );

  if (existingIndex >= 0) {
    // Update existing
    existingScenarios[existingIndex] = newScenario;
    return { scenarios: existingScenarios, action: 'updated' };
  }

  // Add new
  existingScenarios.push(newScenario);
  return { scenarios: existingScenarios, action: 'added' };
}

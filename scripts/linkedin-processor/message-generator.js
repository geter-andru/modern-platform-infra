/**
 * Message Generator
 * Creates personalized LinkedIn InMail drafts
 */

import Anthropic from '@anthropic-ai/sdk';
import fs from 'fs/promises';
import path from 'path';

const anthropic = new Anthropic();

/**
 * Generate personalized InMail message
 */
export async function generateInMail(enrichedProfile, scenario) {
  console.log(`  ✉️ Generating InMail for: ${enrichedProfile.firstName}`);

  const slug = scenario?.slug || generateSlug(enrichedProfile.company);
  const icpUrl = `https://platform.andru-ai.com/icp/${slug}`;

  const prompt = `You are Brandon Geter, founder of Andru - an AI-powered Revenue Intelligence Platform for B2B SaaS founders.

Generate a personalized LinkedIn InMail message for a new connection. This message should be sent AFTER they've accepted your connection request.

## RECIPIENT

Name: ${enrichedProfile.firstName} ${enrichedProfile.lastName}
Title: ${enrichedProfile.headline}
Company: ${enrichedProfile.company}
About: ${enrichedProfile.about || 'Not available'}
${enrichedProfile.lusha ? `Industry: ${enrichedProfile.lusha.industry || 'Tech'}` : ''}
${enrichedProfile.lusha?.fundingStage ? `Funding Stage: ${enrichedProfile.lusha.fundingStage}` : ''}

Recent LinkedIn Posts:
${enrichedProfile.recentPosts?.slice(0, 2).join('\n---\n') || 'None found'}

## SCENARIO CREATED FOR THEM

${scenario ? `
Title: ${scenario.title}
Persona: ${scenario.persona}
Value: ${scenario.timestamps?.[scenario.timestamps.length - 1]?.momentOfValue || 'Custom ICP analysis'}
` : 'A custom ICP analysis page has been created for them.'}

## CUSTOM ICP PAGE URL

${icpUrl}

## BRANDON'S BACKGROUND (for credibility)

- 9 years SaaS sales (Apttus, Sumo Logic, Graphite, OpsLevel)
- Generated $30M+ in pipeline across 7 companies
- Built Andru in 4 months with zero coding background
- Hired/trained 20+ sellers

## MESSAGE REQUIREMENTS

1. **Length:** 150-250 characters (LinkedIn InMail sweet spot)
2. **Tone:** Founder-to-founder, genuine, not salesy
3. **Hook:** Reference something specific about them or their company
4. **Value:** Mention the custom ICP page created for their product
5. **CTA:** Soft - invite them to check it out, no pressure

## MESSAGE PATTERNS THAT WORK

Pattern 1 (Direct):
"${enrichedProfile.firstName}, built a custom buyer journey analysis for ${enrichedProfile.company} showing how [specific persona] discovers your value. Take a look: [url]"

Pattern 2 (Observation-based):
"${enrichedProfile.firstName}, noticed [specific thing about them/company]. Created a scenario mapping your ideal buyer's journey. Curious what you think: [url]"

Pattern 3 (Value-first):
"${enrichedProfile.firstName}, put together a quick ICP scenario for ${enrichedProfile.company} - maps the 'aha moment' for your target buyers. Worth a 2-min look: [url]"

## OUTPUT FORMAT

Return ONLY the message text, no quotes, no explanation. Keep it under 300 characters.`;

  try {
    const response = await anthropic.messages.create({
      model: 'claude-sonnet-4-20250514',
      max_tokens: 200,
      messages: [{
        role: 'user',
        content: prompt
      }]
    });

    const message = response.content[0].text.trim();
    console.log(`    ✓ Generated (${message.length} chars)`);

    return {
      to: enrichedProfile.name,
      company: enrichedProfile.company,
      profileUrl: enrichedProfile.url,
      icpUrl,
      message,
      charCount: message.length
    };

  } catch (error) {
    console.error(`    ✗ Error generating message: ${error.message}`);
    return null;
  }
}

/**
 * Save InMail draft to file
 */
export async function saveInMailDraft(inmail, outputRoot) {
  const draftsDir = path.join(outputRoot, 'linkedin-outreach/drafts');
  await fs.mkdir(draftsDir, { recursive: true });

  const date = new Date().toISOString().split('T')[0];
  const slug = generateSlug(inmail.company);
  const filename = `${date}_${slug}.md`;
  const filepath = path.join(draftsDir, filename);

  const content = `# LinkedIn InMail Draft - ${date}

## Recipient
- **Name:** ${inmail.to}
- **Company:** ${inmail.company}
- **Profile:** ${inmail.profileUrl}
- **ICP Page:** ${inmail.icpUrl}

---

## Message (${inmail.charCount} characters)

${inmail.message}

---

## Status
- [ ] Reviewed
- [ ] Personalized
- [ ] Sent via LinkedIn
- [ ] Response received

## Notes
<!-- Add any personalization notes here -->
`;

  await fs.writeFile(filepath, content, 'utf-8');
  console.log(`    📄 Saved: ${filename}`);

  return filename;
}

/**
 * Generate URL-safe slug
 */
function generateSlug(text) {
  return (text || 'unknown')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 50);
}

/**
 * Lusha API Enrichment
 * Enriches LinkedIn profile data with company information
 */

const LUSHA_API_BASE = 'https://api.lusha.com/v2';

/**
 * Enrich profile with Lusha company data
 */
export async function enrichWithLusha(profile, apiKey) {
  console.log(`  🔍 Enriching with Lusha: ${profile.company}`);

  if (!apiKey) {
    console.log('    ⚠️ No Lusha API key provided, skipping enrichment');
    return {
      ...profile,
      lusha: null
    };
  }

  const enrichment = {
    companyWebsite: null,
    companySize: null,
    industry: null,
    fundingStage: null,
    technologies: [],
    linkedInCompanyUrl: null
  };

  try {
    // First try to get company data
    if (profile.company) {
      const companyData = await fetchCompanyData(profile.company, apiKey);
      if (companyData) {
        enrichment.companyWebsite = companyData.website || companyData.domain;
        enrichment.companySize = companyData.employeesRange || companyData.size;
        enrichment.industry = companyData.industry;
        enrichment.fundingStage = companyData.fundingStage || companyData.funding;
        enrichment.technologies = companyData.technologies || [];
        enrichment.linkedInCompanyUrl = companyData.linkedinUrl || companyData.linkedin;
      }
    }

    // If we have LinkedIn profile URL, try person enrichment too
    if (profile.url && !enrichment.companyWebsite) {
      const personData = await fetchPersonData(profile, apiKey);
      if (personData?.company) {
        enrichment.companyWebsite = personData.company.website;
        enrichment.companySize = personData.company.size;
        enrichment.industry = personData.company.industry;
      }
    }

    if (enrichment.companyWebsite) {
      console.log(`    ✓ Found: ${enrichment.companyWebsite} (${enrichment.industry || 'unknown industry'})`);
    } else {
      console.log(`    ⚠️ No company data found in Lusha`);
    }

  } catch (error) {
    console.error(`    ✗ Lusha API error: ${error.message}`);
  }

  return {
    ...profile,
    lusha: enrichment
  };
}

/**
 * Fetch company data from Lusha
 */
async function fetchCompanyData(companyName, apiKey) {
  try {
    const response = await fetch(`${LUSHA_API_BASE}/company/enrich`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'api_key': apiKey
      },
      body: JSON.stringify({
        company: companyName
      })
    });

    if (!response.ok) {
      if (response.status === 404) {
        return null; // Company not found
      }
      throw new Error(`Lusha API error: ${response.status}`);
    }

    const data = await response.json();
    return data.data || data;
  } catch (error) {
    if (error.message.includes('404')) {
      return null;
    }
    throw error;
  }
}

/**
 * Fetch person data from Lusha using LinkedIn URL
 */
async function fetchPersonData(profile, apiKey) {
  try {
    const response = await fetch(`${LUSHA_API_BASE}/person/enrich`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'api_key': apiKey
      },
      body: JSON.stringify({
        linkedinUrl: profile.url,
        firstName: profile.firstName,
        lastName: profile.lastName,
        company: profile.company
      })
    });

    if (!response.ok) {
      if (response.status === 404) {
        return null;
      }
      throw new Error(`Lusha API error: ${response.status}`);
    }

    const data = await response.json();
    return data.data || data;
  } catch (error) {
    if (error.message.includes('404')) {
      return null;
    }
    throw error;
  }
}

/**
 * Batch enrich multiple profiles
 */
export async function batchEnrich(profiles, apiKey) {
  const enriched = [];

  for (const profile of profiles) {
    const result = await enrichWithLusha(profile, apiKey);
    enriched.push(result);

    // Rate limiting - Lusha typically allows 2-5 requests per second
    await new Promise(resolve => setTimeout(resolve, 500));
  }

  return enriched;
}

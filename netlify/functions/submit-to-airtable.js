// Netlify Function to submit data to Airtable
// This avoids CORS issues by making the API call from the server side

exports.handler = async (event, context) => {
  // Only allow POST requests
  if (event.httpMethod !== 'POST') {
    return {
      statusCode: 405,
      body: JSON.stringify({ error: 'Method not allowed' })
    };
  }

  // Parse the request body
  let data;
  try {
    data = JSON.parse(event.body);
  } catch (error) {
    return {
      statusCode: 400,
      body: JSON.stringify({ error: 'Invalid request body' })
    };
  }

  // Airtable configuration
  const AIRTABLE_BASE_ID = 'app0jJkgTCqn46vp9';
  const AIRTABLE_API_KEY = process.env.AIRTABLE_API_KEY || '';
  const AIRTABLE_TABLE = 'tblQl6DpGJNKKeQHu';
  
  // Build the Airtable API URL
  const url = `https://api.airtable.com/v0/${AIRTABLE_BASE_ID}/${encodeURIComponent(AIRTABLE_TABLE)}`;
  
  try {
    // Make the API call to Airtable
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${AIRTABLE_API_KEY}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        fields: data
      })
    });

    if (response.ok) {
      const result = await response.json();
      console.log('✅ Data saved to Airtable:', result.id);
      
      return {
        statusCode: 200,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        },
        body: JSON.stringify({
          success: true,
          recordId: result.id,
          message: 'Data saved successfully'
        })
      };
    } else {
      const errorText = await response.text();
      console.error('❌ Airtable API error:', response.status, errorText);
      
      return {
        statusCode: response.status,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        },
        body: JSON.stringify({
          success: false,
          error: `Airtable API error: ${response.status}`,
          details: errorText
        })
      };
    }
  } catch (error) {
    console.error('❌ Network error:', error);
    
    return {
      statusCode: 500,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      },
      body: JSON.stringify({
        success: false,
        error: 'Network error',
        details: error.message
      })
    };
  }
};
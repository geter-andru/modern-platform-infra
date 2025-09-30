/**
 * Netlify Function: Get Resources
 * Retrieves completed resources stored by the core-resources-webhook
 */

const allowedOrigins = [
  'https://platform.andru-ai.com',
  'http://localhost:3000',
  'http://localhost:3001'
];

exports.handler = async (event, context) => {
  // Handle CORS
  const origin = event.headers.origin;
  const corsHeaders = {
    'Access-Control-Allow-Headers': 'Content-Type, Authorization, x-session-id, x-customer-id',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Origin': allowedOrigins.includes(origin) ? origin : allowedOrigins[0]
  };

  // Handle preflight requests
  if (event.httpMethod === 'OPTIONS') {
    return {
      statusCode: 200,
      headers: corsHeaders,
      body: ''
    };
  }

  try {
    // Only allow GET requests
    if (event.httpMethod !== 'GET') {
      return {
        statusCode: 405,
        headers: corsHeaders,
        body: JSON.stringify({ error: 'Method not allowed' })
      };
    }

    // Get session ID from query parameters
    const sessionId = event.queryStringParameters?.sessionId;
    
    if (!sessionId) {
      return {
        statusCode: 400,
        headers: corsHeaders,
        body: JSON.stringify({ error: 'Missing sessionId parameter' })
      };
    }

    // Check global storage (limited to same function instance)
    global.completedResources = global.completedResources || {};
    const storedData = global.completedResources[sessionId];

    if (!storedData) {
      return {
        statusCode: 404,
        headers: corsHeaders,
        body: JSON.stringify({ 
          error: 'Resources not found',
          sessionId,
          message: 'Resources may not be ready yet or session ID is invalid',
          debug: {
            globalKeys: Object.keys(global.completedResources || {}),
            fileExists: require('fs').existsSync(`/tmp/resources/${sessionId}.json`),
            tmpDir: require('fs').existsSync('/tmp/resources') ? require('fs').readdirSync('/tmp/resources') : 'Not found'
          }
        })
      };
    }

    // Return the resources
    return {
      statusCode: 200,
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        success: true,
        ...storedData,
        retrieved_at: new Date().toISOString()
      })
    };

  } catch (error) {
    console.error('Get resources error:', error);
    
    return {
      statusCode: 500,
      headers: corsHeaders,
      body: JSON.stringify({
        error: 'Internal server error',
        message: error.message,
        timestamp: new Date().toISOString()
      })
    };
  }
};
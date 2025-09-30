const { OAuth2Client } = require('google-auth-library');

// Google OAuth2 client for token verification
const client = new OAuth2Client(
  process.env.GOOGLE_CLIENT_ID,
  process.env.GOOGLE_CLIENT_SECRET
);

exports.handler = async (event, context) => {
  // Enable CORS
  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
  };

  // Handle preflight requests
  if (event.httpMethod === 'OPTIONS') {
    return {
      statusCode: 200,
      headers,
      body: '',
    };
  }

  if (event.httpMethod !== 'POST') {
    return {
      statusCode: 405,
      headers,
      body: JSON.stringify({ error: 'Method not allowed' }),
    };
  }

  try {
    const requestBody = JSON.parse(event.body);
    
    // Handle ID Token verification (original popup flow)
    if (requestBody.idToken) {
      const { idToken } = requestBody;

      // Verify the Google ID token
      const ticket = await client.verifyIdToken({
        idToken,
        audience: process.env.GOOGLE_CLIENT_ID,
      });

      const payload = ticket.getPayload();
      
      // Extract user information
      const userInfo = {
        googleId: payload.sub,
        email: payload.email,
        name: payload.name,
        firstName: payload.given_name,
        lastName: payload.family_name,
        picture: payload.picture,
        emailVerified: payload.email_verified,
      };

      return {
        statusCode: 200,
        headers,
        body: JSON.stringify({
          success: true,
          user: userInfo,
          timestamp: new Date().toISOString(),
        }),
      };
    }
    
    // Handle Authorization Code flow (redirect flow)
    if (requestBody.code) {
      const { code, redirectUri } = requestBody;
      
      if (!code || !redirectUri) {
        return {
          statusCode: 400,
          headers,
          body: JSON.stringify({ error: 'Missing authorization code or redirect URI' }),
        };
      }

      // Exchange authorization code for tokens
      const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: new URLSearchParams({
          client_id: process.env.GOOGLE_CLIENT_ID,
          client_secret: process.env.GOOGLE_CLIENT_SECRET,
          code,
          grant_type: 'authorization_code',
          redirect_uri: redirectUri,
        }),
      });

      const tokenData = await tokenResponse.json();
      
      if (!tokenData.id_token) {
        return {
          statusCode: 400,
          headers,
          body: JSON.stringify({ 
            success: false, 
            error: 'Failed to get ID token',
            details: tokenData 
          }),
        };
      }

      // Verify the ID token
      const ticket = await client.verifyIdToken({
        idToken: tokenData.id_token,
        audience: process.env.GOOGLE_CLIENT_ID,
      });

      const payload = ticket.getPayload();
      
      // Extract user information
      const userInfo = {
        googleId: payload.sub,
        email: payload.email,
        name: payload.name,
        firstName: payload.given_name,
        lastName: payload.family_name,
        picture: payload.picture,
        emailVerified: payload.email_verified,
      };

      return {
        statusCode: 200,
        headers,
        body: JSON.stringify({
          success: true,
          user: userInfo,
          idToken: tokenData.id_token,
          timestamp: new Date().toISOString(),
        }),
      };
    }

    return {
      statusCode: 400,
      headers,
      body: JSON.stringify({ error: 'Missing idToken or code' }),
    };

  } catch (error) {
    console.error('Google Auth verification error:', error);
    
    return {
      statusCode: 401,
      headers,
      body: JSON.stringify({
        success: false,
        error: 'Authentication failed',
        details: process.env.NODE_ENV === 'development' ? error.message : undefined,
      }),
    };
  }
};
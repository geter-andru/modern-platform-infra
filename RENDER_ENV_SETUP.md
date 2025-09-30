# Render Environment Variables Setup

## Required Environment Variables for Deployment

When setting up your Render web service, configure these environment variables in the Render dashboard:

### Core Application
```
NODE_ENV=production
PORT=10000
```

### Claude AI Service (CRITICAL)
```
ANTHROPIC_API_KEY=placeholder_key_here
```
**Note:** Set this manually in Render dashboard - never commit actual API keys to git

### Database Configuration  
```
NEXT_PUBLIC_SUPABASE_URL=https://molcqjsqtjbfclasynpg.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vbGNxanNxdGpiZmNsYXN5bnBnIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NTg4OTU0NywiZXhwIjoyMDcxNDY1NTQ3fQ.1k0NjvG3rA3vxEJsbacUtFtUijh9AFIBXnM0vUpxmX8
```

### Frontend Integration
```
FRONTEND_URL=https://your-netlify-app.netlify.app
```

## Deployment Steps

### 1. Create Render Account
- Sign up at https://render.com
- Connect your GitHub account

### 2. Create New Web Service  
- Click "New +" → "Web Service"
- Connect your GitHub repository
- Select the `modern-platform` directory as root

### 3. Configure Build Settings
- **Build Command**: `npm run build:server`
- **Start Command**: `npm start`
- **Environment**: Node
- **Plan**: Starter ($7/month) or higher

### 4. Set Environment Variables
- Go to Environment tab in Render dashboard
- Add all variables listed above
- **IMPORTANT**: Copy/paste API keys exactly - no typos!

### 5. Deploy & Monitor
- Click "Deploy"
- Monitor build logs for any errors
- Check health endpoint: `https://your-app.onrender.com/health`

## Testing After Deployment

### Health Check
```bash
curl https://your-app.onrender.com/health
```

Should return:
```json
{
  "status": "healthy",
  "services": {
    "claudeAI": true,
    "supabase": true,
    "database": true
  }
}
```

### Claude AI Test
```bash
curl -X POST https://your-app.onrender.com/api/claude-ai/chat \
  -H "Content-Type: application/json" \
  -H "x-user-id: test-user" \
  -d '{"message": "Hello Claude!"}'
```

### Job Queue Test
```bash
curl -X POST https://your-app.onrender.com/api/jobs \
  -H "Content-Type: application/json" \
  -H "x-user-id: test-user" \
  -d '{"type": "ai-processing", "data": {"message": "Test job"}}'
```

## Expected Performance
- **Cold Start**: 2-5 seconds (first request after idle)
- **API Response**: 100-500ms for job creation
- **Claude AI Processing**: 5-30 seconds depending on complexity
- **Concurrent Users**: Optimized for 10 simultaneous users

## Troubleshooting

### Common Issues
1. **Build fails**: Check TypeScript compilation errors
2. **Environment variables missing**: Verify all keys are set correctly
3. **Claude API fails**: Confirm API key is valid and has credits
4. **Database connection fails**: Check Supabase service role key

### Logs & Monitoring
- View logs in Render dashboard
- Monitor queue stats at `/api/jobs/stats`
- Check cache performance at `/api/cache/stats`
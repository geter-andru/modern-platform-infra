# Supabase Production Environment Variables

**Status:** Required for December 1, 2025 launch
**Last Updated:** 2025-11-10

## Overview

This document lists all environment variables that must be configured in your production Supabase project for the founding member waitlist launch.

---

## 🔐 Authentication Configuration

### Google OAuth (Required)

```bash
# Get these from Google Cloud Console → APIs & Services → Credentials
# https://console.cloud.google.com/apis/credentials

SUPABASE_AUTH_EXTERNAL_GOOGLE_CLIENT_ID="your-google-client-id.apps.googleusercontent.com"
SUPABASE_AUTH_EXTERNAL_GOOGLE_SECRET="your-google-client-secret"
```

**Setup Steps:**
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create a new project or select existing
3. Navigate to: APIs & Services → Credentials
4. Create OAuth 2.0 Client ID (Web application)
5. Add authorized redirect URIs:
   - `https://your-project-id.supabase.co/auth/v1/callback`
   - `http://localhost:54321/auth/v1/callback` (for local testing)
6. Copy Client ID and Client Secret to environment variables

---

## 🌐 Site URL Configuration

### Production URLs (Required)

```bash
# Primary site URL (where users will be redirected after authentication)
SUPABASE_SITE_URL="https://app.andru.io"  # Update with your actual domain

# Additional allowed redirect URLs (comma-separated)
SUPABASE_ADDITIONAL_REDIRECT_URL_1="https://app.andru.io/waitlist-welcome"
SUPABASE_ADDITIONAL_REDIRECT_URL_2="https://app.andru.io/dashboard"
```

**Setup Steps:**
1. Configure your production domain
2. Ensure all URLs use HTTPS (except localhost)
3. Add exact URLs (no wildcards)
4. Include specific redirect paths for magic links

---

## 📧 Email Configuration (Production SMTP)

### SendGrid / AWS SES / Custom SMTP (Required for Production)

**Note:** Local development uses Inbucket for email testing. Production requires a real SMTP provider.

**Option 1: SendGrid (Recommended)**
```bash
# Get API key from https://app.sendgrid.com/settings/api_keys
SENDGRID_API_KEY="SG.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

**Option 2: AWS SES**
```bash
AWS_SES_ACCESS_KEY_ID="your-access-key"
AWS_SES_SECRET_ACCESS_KEY="your-secret-key"
AWS_SES_REGION="us-east-1"
```

**Option 3: Custom SMTP**
```bash
SMTP_HOST="smtp.yourdomain.com"
SMTP_PORT="587"
SMTP_USER="noreply@andru.io"
SMTP_PASS="your-smtp-password"
SMTP_ADMIN_EMAIL="admin@andru.io"
SMTP_SENDER_NAME="Andru Revenue Intelligence"
```

**Setup Steps:**
1. Create SendGrid account (or alternative SMTP provider)
2. Verify sender domain (andru.io)
3. Generate API key with Mail Send permissions
4. Configure environment variable
5. Update `infra/supabase/config.toml` to uncomment SMTP section (lines 187-194)

---

## 🎯 Founding Member Configuration

### Pricing & Access Control

These are hardcoded in `/backend/src/routes/payment.js` (lines 21-23):

```javascript
const FOUNDING_MEMBER_EARLY_ACCESS_PRICE = 497;
const FOUNDING_MEMBER_FOREVER_LOCK_PRICE = 750;
const PLATFORM_ACCESS_GRANT_DATE = new Date('2025-12-01T00:00:00Z');
```

**No environment variables needed** - these are application constants.

---

## 🔗 Backend Environment Variables

### Required in `/backend/.env`

```bash
# Supabase Connection
SUPABASE_URL="https://your-project-id.supabase.co"
SUPABASE_SERVICE_ROLE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

# Frontend URL (for magic link redirects)
FRONTEND_URL="https://app.andru.io"

# Stripe Configuration
STRIPE_SECRET_KEY="sk_live_..."  # Use live key for production
STRIPE_WEBHOOK_SECRET="whsec_..."  # Get from Stripe webhook settings

# JWT Secret (generate secure random string)
JWT_SECRET="your-super-secure-random-string-min-32-chars"

# CORS Origins (comma-separated)
CORS_ORIGIN="https://app.andru.io,https://www.andru.io"

# Node Environment
NODE_ENV="production"
```

---

## 🖥️ Frontend Environment Variables

### Required in `/frontend/.env.production`

```bash
# Supabase Public Configuration
NEXT_PUBLIC_SUPABASE_URL="https://your-project-id.supabase.co"
NEXT_PUBLIC_SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

# Backend API URL
NEXT_PUBLIC_API_BASE_URL="https://api.andru.io"

# Stripe Public Key
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY="pk_live_..."
```

---

## 🚀 Deployment Checklist

### Before December 1, 2025 Launch

- [ ] **Google OAuth configured** in Google Cloud Console
- [ ] **Google OAuth credentials** added to Supabase environment
- [ ] **Production SMTP** configured (SendGrid/AWS SES)
- [ ] **Custom email template** deployed (`infra/supabase/templates/magic_link.html`)
- [ ] **Site URLs** updated for production domain
- [ ] **Redirect URLs** added for all auth flows
- [ ] **Stripe webhook** configured with production endpoint
- [ ] **Backend environment variables** set in hosting platform
- [ ] **Frontend environment variables** set in Vercel/Netlify
- [ ] **Test magic link email** sends successfully
- [ ] **Test Google OAuth** login flow
- [ ] **Test payment webhook** creates user + milestone
- [ ] **Verify waitlist-welcome page** redirects correctly

---

## 🔍 Testing Configuration

### Local Development (.env.local)

```bash
# Use local Supabase instance
SUPABASE_URL="http://127.0.0.1:54321"
SUPABASE_SERVICE_ROLE_KEY="eyJhbGci..."  # From local Supabase CLI
SUPABASE_ANON_KEY="eyJhbGci..."  # From local Supabase CLI

# Use Stripe test mode
STRIPE_SECRET_KEY="sk_test_..."
STRIPE_WEBHOOK_SECRET="whsec_test_..."

# Local frontend
FRONTEND_URL="http://localhost:3000"
CORS_ORIGIN="http://localhost:3000"

# Local site URL
SUPABASE_SITE_URL="http://localhost:3000"
```

### Test Magic Link Flow

```bash
# Start local Supabase
cd infra/supabase
supabase start

# Access email testing interface
open http://127.0.0.1:54324  # Inbucket email viewer

# Trigger payment webhook (use Stripe CLI)
stripe trigger checkout.session.completed
```

---

## 📝 Notes

1. **Never commit secrets** to git - use `.env.local` (gitignored)
2. **Use environment variable substitution** in config.toml (e.g., `env(VAR_NAME)`)
3. **Rotate secrets regularly** - especially service role keys
4. **Test locally first** before deploying to production
5. **Monitor Supabase logs** for authentication issues
6. **Set up alerts** for webhook failures

---

## 🆘 Troubleshooting

### Magic Link Not Sending

1. Check SMTP configuration in Supabase dashboard
2. Verify sender domain is authenticated
3. Check Supabase logs: Settings → Logs → Auth
4. Test with Inbucket locally first

### Google OAuth Not Working

1. Verify redirect URI matches exactly (including trailing slash)
2. Check OAuth consent screen is configured
3. Ensure Google OAuth is enabled in Supabase dashboard
4. Check `skip_nonce_check = true` in config.toml

### Webhook Not Creating Users

1. Check webhook secret matches Stripe dashboard
2. Verify Supabase service role key is correct
3. Check backend logs for error messages
4. Test with Stripe CLI: `stripe listen --forward-to localhost:3001/api/payment/webhook`

---

## 📚 References

- [Supabase Auth Configuration](https://supabase.com/docs/guides/auth)
- [Google OAuth Setup](https://supabase.com/docs/guides/auth/social-login/auth-google)
- [Custom Email Templates](https://supabase.com/docs/guides/auth/custom-email-templates)
- [Stripe Webhooks](https://stripe.com/docs/webhooks)
- [SendGrid API Setup](https://docs.sendgrid.com/api-reference/api-keys)

# Andru Lead Gen Agent

Automated lead generation agent that scrapes compelling events and generates platform-specific posts for human review.

## Overview

This agent:
1. **Scrapes** compelling events (funding announcements, sales job postings, Reddit discussions)
2. **Scores** events based on relevance to Andru's target audience
3. **Generates** platform-specific posts using Claude AI
4. **Saves** posts for human review before publishing

## Architecture

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Scrapers      │────▶│   Scorer        │────▶│   Generator     │
│   (Playwright)  │     │   (Select best) │     │   (Claude API)  │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                                                        │
                                                        ▼
                                               ┌─────────────────┐
                                               │   Human Review  │
                                               │   (Markdown)    │
                                               └─────────────────┘
```

## Sources Scraped

| Source | What | Frequency |
|--------|------|-----------|
| TechCrunch | Startup funding announcements | Daily |
| Reddit r/startups | Founder discussions | Daily |
| LinkedIn Jobs | Sales hiring signals | Daily |

## Setup

### 1. Install Dependencies

```bash
cd scripts/lead-gen
npm install
npx playwright install chromium
```

### 2. Set Environment Variables

```bash
export ANTHROPIC_API_KEY="your-api-key"
```

### 3. Run Locally

```bash
# Full run (scrape + generate)
npm start

# Dry run (scrape only, no generation)
npm run dry-run

# Platform-specific
npm run linkedin
npm run twitter
npm run reddit
```

## GitHub Actions

The agent runs daily at 9 AM PST via GitHub Actions.

### Required Secrets

Add to your GitHub repository settings:
- `ANTHROPIC_API_KEY` - Your Anthropic API key

### Manual Trigger

1. Go to Actions → Lead Gen Agent
2. Click "Run workflow"
3. Optionally enable "dry run" mode

## Output

Generated posts are saved to:
```
lead-gen/posts/
├── 2025-11-22_linkedin_funding-announcement.md
├── 2025-11-22_twitter_funding-announcement.md
└── 2025-11-22_reddit_funding-announcement.md
```

Each file contains:
- Source event metadata
- Generated post content
- Review checklist

## Event Scoring

Events are scored based on relevance:

| Signal | Score |
|--------|-------|
| "first sales" / "first hire" | +20 |
| "Series A" | +15 |
| "founding sales" | +15 |
| "VP Sales" | +12 |
| "Seed funding" | +10 |
| "technical founder" | +10 |
| "ICP" | +10 |
| "GTM" / "go-to-market" | +8 |
| "Series B" | +8 |
| "B2B" | +5 |
| "SaaS" | +5 |
| "raises" / "raised" | +5 |
| Consumer (negative) | -5 |
| Crypto/Web3 (negative) | -3 |

## Files

```
infra/
├── scripts/lead-gen/
│   ├── index.js          # Main orchestration
│   ├── scrapers.js       # Playwright scrapers
│   ├── post-generator.js # Claude API integration
│   ├── package.json      # Dependencies
│   └── README.md         # This file
├── lead-gen/
│   ├── posts/            # Generated posts (for review)
│   └── processed-events.json  # History (avoid duplicates)
└── .github/workflows/
    └── lead-gen.yml      # GitHub Actions workflow

modern-platform/ (separate repo, checked out for content)
├── dev/analytics/lead-gen/
│   └── COMPELLING_EVENT_POSTING_STRATEGY.md  # Strategy doc
└── docs/philosophy/      # Core philosophy content
```

## Philosophy Integration

The agent loads:
- `COMPELLING_EVENT_POSTING_STRATEGY.md` - Platform-specific guidelines
- `docs/philosophy/` - Core Andru philosophy

These are woven into generated content for authentic, on-brand posts.

## Human-in-the-Loop

This agent generates **drafts**, not published posts. The workflow:

1. Agent generates posts daily
2. GitHub Action commits to `lead-gen/posts/`
3. GitHub creates an issue for review
4. Human reviews, edits, and publishes
5. Human marks `[x] Posted` in the file

## Troubleshooting

### No events found
- Check if scrapers are being blocked (LinkedIn especially)
- Verify Playwright browser is installed

### API errors
- Verify `ANTHROPIC_API_KEY` is set
- Check Claude API status

### Posts not generating
- Ensure strategy doc exists at `dev/analytics/lead-gen/COMPELLING_EVENT_POSTING_STRATEGY.md`
- Check `docs/philosophy/` directory exists

## Future Enhancements

- [ ] Twitter API integration (currently placeholder)
- [ ] More sophisticated event scoring (ML-based)
- [ ] Image/visual generation for posts
- [ ] Engagement tracking integration

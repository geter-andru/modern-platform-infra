/**
 * Email Notifier
 * Sends workflow results via Resend API (simple, free tier available)
 */

// Configuration
const RESEND_API_KEY = process.env.RESEND_API_KEY;
const RECIPIENT_EMAIL = process.env.NOTIFICATION_EMAIL || 'geter@humusnshore.org';

// Notification type from env
const NOTIFICATION_TYPE = process.env.NOTIFICATION_TYPE || 'generic';
const NOTIFICATION_DATA = process.env.NOTIFICATION_DATA ? JSON.parse(process.env.NOTIFICATION_DATA) : {};

async function main() {
  console.log(`📧 Email Notifier - Sending ${NOTIFICATION_TYPE} notification to ${RECIPIENT_EMAIL}...`);

  if (!RESEND_API_KEY) {
    console.log('⚠️ RESEND_API_KEY not configured. Skipping email notification.');
    console.log('To enable email notifications:');
    console.log('1. Sign up at https://resend.com (free tier: 3000 emails/month)');
    console.log('2. Add RESEND_API_KEY secret to GitHub repo');
    process.exit(0); // Don't fail the workflow
  }

  try {
    // Generate email content based on type
    const { subject, html } = generateEmailContent(NOTIFICATION_TYPE, NOTIFICATION_DATA);

    // Send via Resend API
    const response = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${RESEND_API_KEY}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        from: 'Andru Automation <notifications@andru-ai.com>',
        to: RECIPIENT_EMAIL,
        subject,
        html
      })
    });

    const result = await response.json();

    if (response.ok) {
      console.log(`✅ Email sent: ${result.id}`);
    } else {
      console.error('❌ Failed to send email:', result);
    }

  } catch (error) {
    console.error('❌ Error sending email:', error.message);
    // Don't fail the workflow
    process.exit(0);
  }
}

function generateEmailContent(type, data) {
  const date = new Date().toLocaleDateString('en-US', {
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  });

  switch (type) {
    case 'complaint-discovery':
      return {
        subject: `🔍 ${data.newComplaints || 0} New Complaints Discovered - ${date}`,
        html: `
          <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 600px; margin: 0 auto;">
            <h2 style="color: #1a1a1a;">Daily Complaint Discovery Report</h2>
            <p style="color: #666;"><strong>Date:</strong> ${date}</p>
            <hr style="border: none; border-top: 1px solid #eee;">

            <table style="border-collapse: collapse; width: 100%; margin: 20px 0;">
              <tr>
                <td style="padding: 12px; background: #f8f9fa; border-radius: 4px;"><strong>New Complaints</strong></td>
                <td style="padding: 12px; font-size: 24px; font-weight: bold;">${data.newComplaints || 0}</td>
              </tr>
              <tr>
                <td style="padding: 12px; background: #f8f9fa;"><strong>High Pain (7+)</strong></td>
                <td style="padding: 12px; font-size: 24px; font-weight: bold; color: ${(data.highPain || 0) > 0 ? '#d32f2f' : '#1a1a1a'};">🔥 ${data.highPain || 0}</td>
              </tr>
              <tr>
                <td style="padding: 12px; background: #f8f9fa;"><strong>Posts Scraped</strong></td>
                <td style="padding: 12px;">${data.postsScraped || 0}</td>
              </tr>
            </table>

            <div style="margin: 20px 0;">
              <a href="https://github.com/geter-andru/modern-platform-infra/issues?q=label%3Acomplaint-discovery+is%3Aopen"
                 style="background: #1976d2; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; display: inline-block;">
                View Details on GitHub →
              </a>
            </div>

            <details style="margin-top: 20px;">
              <summary style="cursor: pointer; color: #666;">Quick SQL Query</summary>
              <pre style="background: #f5f5f5; padding: 12px; font-size: 11px; border-radius: 4px; overflow-x: auto;">
SELECT title, pain_score, exact_phrases
FROM complaints
WHERE pain_score >= 7
ORDER BY created_at DESC LIMIT 10;</pre>
            </details>

            <hr style="border: none; border-top: 1px solid #eee; margin-top: 30px;">
            <p style="color: #999; font-size: 12px;">🤖 Andru Automation | <a href="https://andru-ai.com" style="color: #999;">andru-ai.com</a></p>
          </div>
        `
      };

    case 'content-opportunities':
      const opps = data.topOpportunities || [];
      return {
        subject: `📝 ${data.opportunities || 0} Content Opportunities - ${date}`,
        html: `
          <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 600px; margin: 0 auto;">
            <h2 style="color: #1a1a1a;">Content Engagement Opportunities</h2>
            <p style="color: #666;"><strong>Date:</strong> ${date}</p>
            <hr style="border: none; border-top: 1px solid #eee;">

            <p style="font-size: 18px;">Found <strong style="color: #1976d2;">${data.opportunities || 0}</strong> unanswered questions on Hacker News.</p>

            ${opps.length > 0 ? `
              <h3 style="color: #1a1a1a; margin-top: 24px;">Top Opportunities</h3>
              ${opps.slice(0, 5).map((opp, i) => `
                <div style="padding: 12px; background: #f8f9fa; border-radius: 6px; margin-bottom: 12px;">
                  <a href="${opp.url}" style="color: #1976d2; text-decoration: none; font-weight: 500;">${i + 1}. ${opp.title?.slice(0, 80)}${opp.title?.length > 80 ? '...' : ''}</a>
                  <div style="color: #666; font-size: 12px; margin-top: 4px;">
                    Score: ${opp.relevanceScore || 0} | Comments: ${opp.engagement || 0}
                  </div>
                </div>
              `).join('')}
            ` : ''}

            <div style="margin: 24px 0;">
              <a href="https://github.com/geter-andru/modern-platform-infra/issues?q=label%3Acontent+is%3Aopen"
                 style="background: #1976d2; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; display: inline-block;">
                View All with Suggested Answers →
              </a>
            </div>

            <hr style="border: none; border-top: 1px solid #eee; margin-top: 30px;">
            <p style="color: #999; font-size: 12px;">🤖 Andru Automation | <a href="https://andru-ai.com" style="color: #999;">andru-ai.com</a></p>
          </div>
        `
      };

    case 'pattern-analysis':
      return {
        subject: `📊 Weekly Pattern Report - ${date}`,
        html: `
          <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 600px; margin: 0 auto;">
            <h2 style="color: #1a1a1a;">Weekly Complaint Pattern Analysis</h2>
            <p style="color: #666;"><strong>Week Ending:</strong> ${date}</p>
            <hr style="border: none; border-top: 1px solid #eee;">

            <table style="border-collapse: collapse; width: 100%; margin: 20px 0;">
              <tr>
                <td style="padding: 12px; background: #f8f9fa;"><strong>Complaints Processed</strong></td>
                <td style="padding: 12px; font-size: 20px; font-weight: bold;">${data.complaintsProcessed || 0}</td>
              </tr>
              <tr>
                <td style="padding: 12px; background: #f8f9fa;"><strong>New Patterns</strong></td>
                <td style="padding: 12px; font-size: 20px; font-weight: bold; color: #4caf50;">${data.newPatterns || 0}</td>
              </tr>
              <tr>
                <td style="padding: 12px; background: #f8f9fa;"><strong>Updated Patterns</strong></td>
                <td style="padding: 12px;">${data.updatedPatterns || 0}</td>
              </tr>
            </table>

            ${data.topPattern ? `
              <h3 style="color: #1a1a1a;">Top Pattern This Week</h3>
              <blockquote style="border-left: 4px solid #1976d2; padding: 12px 16px; margin: 16px 0; background: #f8f9fa; border-radius: 0 6px 6px 0;">
                "${data.topPattern}"
              </blockquote>
            ` : ''}

            <div style="margin: 24px 0;">
              <a href="https://github.com/geter-andru/modern-platform-infra/issues?q=label%3Apattern-analysis+is%3Aopen"
                 style="background: #1976d2; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; display: inline-block;">
                View Full Report →
              </a>
            </div>

            <hr style="border: none; border-top: 1px solid #eee; margin-top: 30px;">
            <p style="color: #999; font-size: 12px;">🤖 Andru Automation | <a href="https://andru-ai.com" style="color: #999;">andru-ai.com</a></p>
          </div>
        `
      };

    default:
      return {
        subject: `🔔 Andru Workflow Notification - ${date}`,
        html: `
          <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 600px; margin: 0 auto;">
            <h2 style="color: #1a1a1a;">Workflow Notification</h2>
            <p style="color: #666;"><strong>Date:</strong> ${date}</p>
            <hr style="border: none; border-top: 1px solid #eee;">
            <pre style="background: #f5f5f5; padding: 12px; font-size: 12px; border-radius: 4px; overflow-x: auto;">${JSON.stringify(data, null, 2)}</pre>
            <hr style="border: none; border-top: 1px solid #eee; margin-top: 30px;">
            <p style="color: #999; font-size: 12px;">🤖 Andru Automation</p>
          </div>
        `
      };
  }
}

main().catch(console.error);

/**
 * Email Service
 * Handles sending emails via Brevo API (bypasses SMTP firewall issues)
 */

// Load environment variables
require('dotenv').config();

const brevo = require('@getbrevo/brevo');

// Configure Brevo API client
const initBrevoClient = () => {
    const apiKey = process.env.BREVO_API_KEY || process.env.SMTP_PASS;
    console.log('📧 Checking Brevo API configuration...');
    console.log('  Brevo API Key:', apiKey ? '***SET***' : 'NOT SET');
    console.log('  From email:', process.env.SMTP_USER || 'NOT SET');

    if (apiKey) {
        console.log('✅ Email service configured: Brevo API');
        const apiInstance = new brevo.TransactionalEmailsApi();
        apiInstance.setApiKey(brevo.TransactionalEmailsApiApiKeys.apiKey, apiKey);
        return apiInstance;
    } else {
        console.log('⚠️  Email service: DEV MODE (emails logged to console)');
        console.log('   To use real email, set BREVO_API_KEY or SMTP_PASS in .env');
        return null;
    }
};

const sendEmail = async (to, subject, htmlContent, textContent = null) => {
    const apiInstance = initBrevoClient();

    // Use SMTP_FROM (custom domain) if set, fallback to SMTP_USER (Brevo relay)
    // Strip quotes and angle brackets from SMTP_FROM if present
    let fromEmail = process.env.SMTP_FROM;
    if (fromEmail) {
        // Extract email from "Name <email@domain.com>" format
        const emailMatch = fromEmail.match(/<(.+?)>/);
        fromEmail = emailMatch ? emailMatch[1] : fromEmail.replace(/[<">]/g, '').trim();
    } else {
        fromEmail = process.env.SMTP_USER || 'siteledger@siteledger.ai';
    }
    const fromName = 'SiteLedger';

    if (!apiInstance) {
        // Dev mode - log to console
        console.log('\n📧 ===== EMAIL (DEV MODE) =====');
        console.log('To:', to);
        console.log('Subject:', subject);
        console.log('From:', `${fromName} <${fromEmail}>`);
        console.log('─────────────────────────────');
        console.log('Body Preview:');
        console.log((textContent || htmlContent.replace(/<[^>]*>/g, '')).substring(0, 300) + '...');
        console.log('================================\n');
        return { success: true, messageId: 'dev-' + Date.now() };
    }

    console.log(`📧 Sending email via Brevo API to: ${to}`);
    console.log(`📧 Subject: ${subject}`);
    console.log(`📧 From: ${fromName} <${fromEmail}>`);

    try {
        const sendSmtpEmail = new brevo.SendSmtpEmail();
        sendSmtpEmail.sender = { name: fromName, email: fromEmail };
        sendSmtpEmail.replyTo = { email: 'siteledger@siteledger.ai', name: fromName }; // Ensure replies go to our domain
        sendSmtpEmail.to = [{ email: to }];
        sendSmtpEmail.subject = subject;
        sendSmtpEmail.htmlContent = htmlContent;
        sendSmtpEmail.textContent = textContent || htmlContent.replace(/<[^>]*>/g, '');

        const result = await apiInstance.sendTransacEmail(sendSmtpEmail);
        console.log(`✅ Email sent successfully via Brevo! Message ID: ${result.messageId}`);
        return { success: true, messageId: result.messageId };
    } catch (error) {
        console.error(`❌ Email sending failed:`, error.message);
        console.error(`Full error:`, error);
        throw error;
    }
};

/**
 * Send password reset email
 */
const sendPasswordResetEmail = async (email, name, resetToken) => {
    const subject = 'Reset Your SiteLedger Password';
    const htmlContent = `
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif; line-height: 1.6; color: #333; }
                .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                .header { background: linear-gradient(135deg, #00968f, #00756f); color: white; padding: 30px; text-align: center; border-radius: 8px 8px 0 0; }
                .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 8px 8px; }
                .token-box { background: #fff; padding: 20px; border: 2px solid #00968f; border-radius: 8px; margin: 20px 0; text-align: center; }
                .token-code { font-family: 'Courier New', monospace; font-size: 18px; font-weight: bold; color: #00968f; letter-spacing: 2px; word-break: break-all; padding: 15px; background: #f0f8f7; border-radius: 4px; margin: 10px 0; }
                .instructions { background: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0; }
                .step { margin: 10px 0; padding-left: 25px; position: relative; }
                .step:before { content: "→"; position: absolute; left: 0; color: #00968f; font-weight: bold; }
                .footer { text-align: center; margin-top: 20px; color: #666; font-size: 12px; }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>🔐 Password Reset Request</h1>
                </div>
                <div class="content">
                    <p>Hi ${name || 'there'},</p>
                    <p>We received a request to reset your SiteLedger password. Use the code below to reset your password:</p>
                    
                    <div class="instructions">
                        <p style="margin: 0 0 10px 0;"><strong>📱 Steps to Reset Your Password:</strong></p>
                        <div class="step">Go to the password reset page (app or web)</div>
                        <div class="step">Enter your email address: <strong>${email}</strong></div>
                        <div class="step">Copy and paste the reset code below</div>
                        <div class="step">Enter your new password</div>
                    </div>
                    
                    <div class="token-box">
                        <p style="margin: 0 0 10px 0; font-size: 14px; color: #666;">Your Reset Code:</p>
                        <div class="token-code">${resetToken}</div>
                        <p style="margin: 10px 0 0 0; font-size: 12px; color: #666;">Tap to select and copy this code</p>
                    </div>
                    
                    <p><strong>⏰ This code will expire in 1 hour.</strong></p>
                    
                    <p>If you didn't request this password reset, you can safely ignore this email. Your password will remain unchanged.</p>
                    
                    <hr style="margin: 30px 0; border: none; border-top: 1px solid #ddd;">
                    
                    <p style="font-size: 12px; color: #666;">
                        For security reasons, this reset code can only be used once. If you need to reset your password again, please submit a new request.
                    </p>
                </div>
                <div class="footer">
                    <p>© 2025 SiteLedger. All rights reserved.</p>
                    <p>This is an automated email. Please do not reply.</p>
                </div>
            </div>
        </body>
        </html>
    `;

    return await sendEmail(email, subject, htmlContent);
};

/**
 * Send password reset email for WEB (with clickable link)
 */
const sendPasswordResetWebEmail = async (email, name, resetToken) => {
    const resetUrl = `https://siteledger.ai/reset-password?token=${resetToken}`;
    const subject = 'Reset Your SiteLedger Password';
    const htmlContent = `
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif; line-height: 1.6; color: #333; }
                .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                .header { background: linear-gradient(135deg, #00968f, #00756f); color: white; padding: 30px; text-align: center; border-radius: 8px 8px 0 0; }
                .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 8px 8px; }
                .button-container { text-align: center; margin: 30px 0; }
                .reset-button { 
                    display: inline-block;
                    background: #00968f; 
                    color: white !important; 
                    text-decoration: none; 
                    padding: 15px 40px; 
                    border-radius: 8px; 
                    font-weight: bold;
                    font-size: 16px;
                    box-shadow: 0 4px 6px rgba(0, 150, 143, 0.3);
                    transition: background 0.3s;
                }
                .reset-button:hover { background: #00756f; }
                .link-box { 
                    background: #fff; 
                    padding: 15px; 
                    border: 1px solid #ddd; 
                    border-radius: 4px; 
                    margin: 20px 0; 
                    word-break: break-all;
                    font-size: 12px;
                    color: #666;
                }
                .warning { background: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0; }
                .footer { text-align: center; margin-top: 20px; color: #666; font-size: 12px; }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>🔐 Reset Your Password</h1>
                </div>
                <div class="content">
                    <p>Hi ${name || 'there'},</p>
                    <p>We received a request to reset your SiteLedger password. Click the button below to create a new password:</p>
                    
                    <div class="button-container">
                        <a href="${resetUrl}" class="reset-button">Reset My Password</a>
                    </div>
                    
                    <p style="text-align: center; color: #666; font-size: 14px;">
                        Button not working? Copy and paste this link into your browser:
                    </p>
                    <div class="link-box">${resetUrl}</div>
                    
                    <div class="warning">
                        <p style="margin: 0;"><strong>⏰ This link will expire in 1 hour</strong></p>
                    </div>
                    
                    <p>If you didn't request this password reset, you can safely ignore this email. Your password will remain unchanged.</p>
                    
                    <hr style="margin: 30px 0; border: none; border-top: 1px solid #ddd;">
                    
                    <p style="font-size: 12px; color: #666;">
                        For security reasons, this reset link can only be used once. If you need to reset your password again, please submit a new request.
                    </p>
                </div>
                <div class="footer">
                    <p>© 2026 SiteLedger. All rights reserved.</p>
                    <p>This is an automated email. Please do not reply.</p>
                </div>
            </div>
        </body>
        </html>
    `;

    return await sendEmail(email, subject, htmlContent);
};

/**
 * Send worker invitation email
 */
const sendWorkerInvite = async (workerEmail, workerName, ownerName, tempPassword) => {
    const subject = `Welcome to SiteLedger - You've been invited by ${ownerName}`;

    const htmlContent = `
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif; line-height: 1.6; color: #333; }
                .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
                .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
                .credentials { background: white; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #667eea; }
                .button { display: inline-block; background: #667eea; color: white; padding: 12px 30px; text-decoration: none; border-radius: 6px; margin: 20px 0; }
                .footer { text-align: center; margin-top: 30px; color: #666; font-size: 14px; }
                code { background: #e8e8e8; padding: 2px 6px; border-radius: 3px; font-family: monospace; }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>🎉 Welcome to SiteLedger!</h1>
                </div>
                <div class="content">
                    <h2>Hi ${workerName},</h2>
                    <p><strong>${ownerName}</strong> has invited you to join their team on SiteLedger - the contractor management app that makes job tracking simple.</p>
                    
                    <div class="credentials">
                        <h3>📱 Your Login Credentials</h3>
                        <p><strong>Email:</strong> <code>${workerEmail}</code></p>
                        <p><strong>Temporary Password:</strong> <code>${tempPassword}</code></p>
                    </div>
                    
                    <h3>🚀 Getting Started</h3>
                    <ol>
                        <li><strong>Download the app:</strong> SiteLedger is available on the iOS App Store</li>
                        <li><strong>Sign in:</strong> Use the credentials above</li>
                        <li><strong>Change your password:</strong> We recommend changing your password after first login</li>
                        <li><strong>Start tracking:</strong> Clock in/out of jobs, submit receipts, and view your hours</li>
                    </ol>
                    
                    <div style="text-align: center;">
                        <a href="https://apps.apple.com/app/siteledger" class="button">Download SiteLedger</a>
                    </div>
                    
                    <h3>✨ What You Can Do</h3>
                    <ul>
                        <li>⏰ Clock in and out of assigned jobs with GPS tracking</li>
                        <li>📸 Upload receipts and expenses</li>
                        <li>📊 View your timesheets and hours worked</li>
                        <li>💰 Track your earnings</li>
                        <li>📄 Access job documents and details</li>
                    </ul>
                    
                    <div class="footer">
                        <p>Need help? Contact your project manager: ${ownerName}</p>
                        <p style="color: #999; font-size: 12px;">This email was sent by SiteLedger on behalf of ${ownerName}</p>
                    </div>
                </div>
            </div>
        </body>
        </html>
    `;

    const textContent = `
Hi ${workerName},

${ownerName} has invited you to join their team on SiteLedger!

YOUR LOGIN CREDENTIALS:
Email: ${workerEmail}
Temporary Password: ${tempPassword}

GETTING STARTED:
1. Download SiteLedger from the iOS App Store
2. Sign in with the credentials above
3. Change your password after first login
4. Start tracking your work!

WHAT YOU CAN DO:
- Clock in/out of jobs with GPS
- Upload receipts and expenses
- View timesheets and hours
- Track earnings
- Access job documents

Download: https://apps.apple.com/app/siteledger

Need help? Contact ${ownerName}
    `.trim();

    return await sendEmail(workerEmail, subject, htmlContent, textContent);
};

/**
 * Send password reset notification for workers
 */
const sendPasswordResetNotification = async (email, name, newPassword) => {
    const subject = 'Your SiteLedger Password Has Been Reset';

    const htmlContent = `
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif; line-height: 1.6; color: #333; }
                .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                .header { background: #667eea; color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
                .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
                .credentials { background: white; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #667eea; }
                code { background: #e8e8e8; padding: 4px 8px; border-radius: 3px; font-family: monospace; font-size: 16px; }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>🔐 Password Reset</h1>
                </div>
                <div class="content">
                    <h2>Hi ${name},</h2>
                    <p>Your SiteLedger password has been reset by your project manager.</p>
                    
                    <div class="credentials">
                        <h3>New Password</h3>
                        <p><code>${newPassword}</code></p>
                    </div>
                    
                    <p><strong>⚠️ Important:</strong> Please change this password after logging in.</p>
                    <p>You can change your password in the app settings.</p>
                </div>
            </div>
        </body>
        </html>
    `;

    const textContent = `
Hi ${name},

Your SiteLedger password has been reset by your project manager.

New Password: ${newPassword}

⚠️ IMPORTANT: Please change this password after logging in.

You can change your password in the app settings.
    `.trim();

    return await sendEmail(email, subject, htmlContent, textContent);
};

/**
 * Send job assignment notification to worker
 */
const sendJobAssignmentNotification = async (workerEmail, workerName, jobName, jobAddress) => {
    const subject = `New Job Assignment: ${jobName}`;

    const htmlContent = `
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif; line-height: 1.6; color: #333; }
                .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
                .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
                .job-details { background: white; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #667eea; }
                .footer { text-align: center; margin-top: 30px; color: #666; font-size: 14px; }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>🎯 New Job Assignment</h1>
                </div>
                <div class="content">
                    <h2>Hi ${workerName},</h2>
                    <p>You've been assigned to a new job! Check the details below:</p>
                    
                    <div class="job-details">
                        <h3>📋 Job Information</h3>
                        <p><strong>Job Name:</strong> ${jobName}</p>
                        <p><strong>Location:</strong> ${jobAddress || 'Address not provided'}</p>
                    </div>
                    
                    <p>Open the SiteLedger app to view full job details, clock in when you arrive, and track your hours.</p>
                    
                    <div class="footer">
                        <p style="color: #999; font-size: 12px;">This email was sent by SiteLedger</p>
                    </div>
                </div>
            </div>
        </body>
        </html>
    `;

    const textContent = `
Hi ${workerName},

You've been assigned to a new job!

JOB INFORMATION:
Job Name: ${jobName}
Location: ${jobAddress || 'Address not provided'}

Open the SiteLedger app to view full details and clock in when you arrive.
    `.trim();

    return await sendEmail(workerEmail, subject, htmlContent, textContent);
};

module.exports = {
    sendEmail,
    sendPasswordResetEmail,
    sendPasswordResetWebEmail,
    sendWorkerInvite,
    sendPasswordResetNotification,
    sendJobAssignmentNotification
};


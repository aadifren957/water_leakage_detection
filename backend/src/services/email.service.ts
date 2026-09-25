import nodemailer, { Transporter } from 'nodemailer';
import { env } from '../config/env';

export interface SendOtpEmailParams {
  to: string;
  fullName: string;
  otp: string;
  purpose: 'EMAIL_VERIFICATION' | 'PASSWORD_RESET';
  expiresInMinutes?: number;
}

export class EmailService {
  private static transporter: Transporter | null = null;

  private static getTransporter(): Transporter | null {
    if (this.transporter) return this.transporter;

    if (env.EMAIL_PROVIDER === 'smtp') {
      const isGmail = env.SMTP_HOST.toLowerCase().includes('gmail') || env.SMTP_USER.toLowerCase().includes('gmail.com');
      const cleanPass = env.SMTP_PASS.replace(/\s+/g, ''); // Strip any spaces from Google App Password

      if (isGmail) {
        this.transporter = nodemailer.createTransport({
          service: 'gmail',
          auth: {
            user: env.SMTP_USER,
            pass: cleanPass,
          },
        });
      } else {
        this.transporter = nodemailer.createTransport({
          host: env.SMTP_HOST,
          port: env.SMTP_PORT,
          secure: env.SMTP_SECURE || env.SMTP_PORT === 465,
          auth: {
            user: env.SMTP_USER,
            pass: cleanPass,
          },
        });
      }
      return this.transporter;
    }

    return null;
  }

  /**
   * Send email using Brevo (Sendinblue) HTTPS REST API (Port 443 - No custom domain required, sends to ANY recipient)
   */
  private static async sendViaBrevoHttp(to: string, fullName: string, subject: string, html: string, text: string): Promise<boolean> {
    const apiKey = env.BREVO_API_KEY.trim();
    if (!apiKey) {
      throw new Error('BREVO_API_KEY is not configured in environment variables.');
    }

    const senderEmail = env.BREVO_SENDER_EMAIL || env.SMTP_USER || 'rishufren@gmail.com';
    const senderName = env.BREVO_SENDER_NAME || 'WaterWatch';

    const response = await fetch('https://api.brevo.com/v3/smtp/email', {
      method: 'POST',
      headers: {
        'api-key': apiKey,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: JSON.stringify({
        sender: {
          name: senderName,
          email: senderEmail,
        },
        to: [
          {
            email: to,
            name: fullName || 'Technician',
          },
        ],
        subject,
        htmlContent: html,
        textContent: text,
      }),
    });

    const data = (await response.json()) as any;

    if (!response.ok) {
      const errorMsg = data?.message || JSON.stringify(data);
      throw new Error(`Brevo API Error (${response.status}): ${errorMsg}`);
    }

    console.log(`✉️ OTP email successfully delivered to ${to} via Brevo HTTPS API (MessageId: ${data.messageId || 'OK'})`);
    return true;
  }

  /**
   * Send email using Resend HTTPS REST API (Port 443 - Works on Render)
   */
  private static async sendViaResendHttp(to: string, subject: string, html: string, text: string): Promise<boolean> {
    const apiKey = env.RESEND_API_KEY.trim();
    if (!apiKey) {
      throw new Error('RESEND_API_KEY is not configured in environment variables.');
    }

    const response = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: env.EMAIL_FROM || 'WaterWatch <onboarding@resend.dev>',
        to: [to],
        subject,
        html,
        text,
      }),
    });

    const data = (await response.json()) as any;

    if (!response.ok) {
      const errorMsg = data?.message || JSON.stringify(data);
      throw new Error(`Resend API Error (${response.status}): ${errorMsg}`);
    }

    console.log(`✉️ OTP email successfully delivered to ${to} via Resend HTTPS API (ID: ${data.id})`);
    return true;
  }

  /**
   * Send a branded OTP verification or password reset email
   */
  static async sendOtpEmail(params: SendOtpEmailParams): Promise<boolean> {
    const { to, fullName, otp, purpose, expiresInMinutes = env.OTP_EXPIRY_MINUTES } = params;

    const isVerification = purpose === 'EMAIL_VERIFICATION';
    const subject = isVerification
      ? `💧 WaterWatch — Verify Your Email (OTP: ${otp})`
      : `💧 WaterWatch — Password Reset Code (OTP: ${otp})`;

    const actionTitle = isVerification ? 'Verify Your Email Address' : 'Password Reset Request';
    const actionDesc = isVerification
      ? 'Thank you for registering with <strong>WaterWatch</strong> Smart City Water Monitoring System. Use the 6-digit verification code below to complete your registration and activate your account.'
      : 'We received a request to reset the password for your <strong>WaterWatch</strong> account. Enter the 6-digit verification code below to set a new password.';

    const htmlContent = `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${subject}</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #F4F7FB; margin: 0; padding: 0; }
    .container { max-width: 580px; margin: 30px auto; background-color: #ffffff; border-radius: 16px; overflow: hidden; border: 1px solid #E2E8F0; box-shadow: 0 4px 16px rgba(15, 36, 62, 0.06); }
    .header { background: linear-gradient(135deg, #0F243E 0%, #1E56A0 100%); padding: 32px 24px; text-align: center; color: #ffffff; }
    .header h1 { margin: 0; font-size: 26px; font-weight: 800; letter-spacing: -0.5px; }
    .header p { margin: 6px 0 0 0; font-size: 13px; color: #93C5FD; font-weight: 500; }
    .body { padding: 32px 28px; color: #0F172A; }
    .greeting { font-size: 16px; font-weight: 600; margin-bottom: 14px; }
    .text { font-size: 14px; line-height: 1.6; color: #475569; margin-bottom: 24px; }
    .otp-box { background: #F8FAFC; border: 2px dashed #3B82F6; border-radius: 12px; padding: 20px; text-align: center; margin: 28px 0; }
    .otp-label { font-size: 12px; font-weight: 700; text-transform: uppercase; letter-spacing: 1px; color: #1E56A0; margin-bottom: 8px; }
    .otp-code { font-size: 36px; font-weight: 800; letter-spacing: 8px; color: #0F243E; font-family: 'Courier New', Courier, monospace; margin: 0; }
    .expiry { font-size: 12px; color: #64748B; margin-top: 10px; }
    .notice { font-size: 12px; color: #94A3B8; line-height: 1.5; border-top: 1px solid #E2E8F0; padding-top: 20px; margin-top: 28px; }
    .footer { background-color: #F8FAFC; padding: 20px 24px; text-align: center; font-size: 11.5px; color: #94A3B8; border-top: 1px solid #E2E8F0; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div style="font-size: 32px; margin-bottom: 6px;">💧</div>
      <h1>WaterWatch</h1>
      <p>Smart City Water Leakage Detection & Monitoring</p>
    </div>
    <div class="body">
      <div class="greeting">Hello, ${fullName || 'Field Technician'}!</div>
      <div class="text">
        <h3>${actionTitle}</h3>
        <p>${actionDesc}</p>
      </div>

      <div class="otp-box">
        <div class="otp-label">Your One-Time Password (OTP)</div>
        <div class="otp-code">${otp}</div>
        <div class="expiry">⏱️ This code will expire in <strong>${expiresInMinutes} minutes</strong>.</div>
      </div>

      <div class="text">
        Enter this code on your mobile device screen to proceed. Do not share this OTP with anyone. WaterWatch staff will never ask for your verification code.
      </div>

      <div class="notice">
        🔒 If you did not create a WaterWatch account or request this action, you can safely ignore this email.
      </div>
    </div>
    <div class="footer">
      &copy; ${new Date().getFullYear()} WaterWatch Smart City Infrastructure. All rights reserved.
    </div>
  </div>
</body>
</html>
    `;

    const plainText = `Hello ${fullName},\n\nYour WaterWatch verification code is: ${otp}\n\nThis code expires in ${expiresInMinutes} minutes.\n\nWaterWatch Smart City Team`;

    // 1. Console / Development mode
    if (env.EMAIL_PROVIDER === 'console' || (!env.BREVO_API_KEY && !env.RESEND_API_KEY && !env.SMTP_USER && !env.SMTP_HOST)) {
      console.log(`
📧 ========================================================
   [DEV/CONSOLE EMAIL SERVICE]
   To:      ${to} (${fullName})
   Subject: ${subject}
   Purpose: ${purpose}
   🔑 OTP:   [ ${otp} ] (Valid for ${expiresInMinutes} mins)
========================================================
      `);
      return true;
    }

    // 2. Brevo HTTPS REST API (Port 443 - Recommended: sends to ANY email without custom domain)
    if (env.EMAIL_PROVIDER === 'brevo') {
      try {
        return await this.sendViaBrevoHttp(to, fullName, subject, htmlContent, plainText);
      } catch (error: any) {
        console.error(`❌ Brevo HTTP Error for ${to}:`, error.message || error);
        console.log(`
🔑 ========================================================
   [FALLBACK OTP CODE]
   To:  ${to}
   OTP: [ ${otp} ] (Valid for ${expiresInMinutes} mins)
========================================================
        `);
        throw {
          statusCode: 502,
          message: error.message || 'Could not deliver email via Brevo API.',
          code: 'EMAIL_DELIVERY_FAILED',
        };
      }
    }

    // 3. Resend HTTPS API (Port 443)
    if (env.EMAIL_PROVIDER === 'resend') {
      try {
        return await this.sendViaResendHttp(to, subject, htmlContent, plainText);
      } catch (error: any) {
        console.error(`❌ Resend HTTP Error for ${to}:`, error.message || error);
        console.log(`
🔑 ========================================================
   [FALLBACK OTP CODE]
   To:  ${to}
   OTP: [ ${otp} ] (Valid for ${expiresInMinutes} mins)
========================================================
        `);
        throw {
          statusCode: 502,
          message: error.message || 'Could not deliver email via Resend API.',
          code: 'EMAIL_DELIVERY_FAILED',
        };
      }
    }

    // 4. SMTP Mode (Nodemailer)
    try {
      const transporter = this.getTransporter();
      if (!transporter) {
        console.warn('⚠️ No email transporter configured. Printing OTP to console:');
        console.log(`🔑 OTP for ${to}: [ ${otp} ]`);
        return true;
      }

      const info = await transporter.sendMail({
        from: env.EMAIL_FROM,
        to,
        subject,
        html: htmlContent,
        text: plainText,
      });

      console.log(`✉️ OTP email successfully delivered to ${to} via SMTP (MessageId: ${info.messageId})`);
      return true;
    } catch (error: any) {
      console.error(`❌ Failed to send email to ${to}:`, error.message || error);
      if (error.response) {
        console.error(`[SMTP SERVER RESPONSE]: ${error.response}`);
      }
      // Log OTP in server console as fallback so the developer/user isn't completely blocked
      console.log(`
🔑 ========================================================
   [FALLBACK OTP CODE]
   To:  ${to}
   OTP: [ ${otp} ] (Valid for ${expiresInMinutes} mins)
   Note: Real email delivery failed. Check your SMTP credentials.
========================================================
      `);
      throw {
        statusCode: 502,
        message: 'Could not deliver verification email. Please verify your email settings or try again.',
        code: 'EMAIL_DELIVERY_FAILED',
      };
    }
  }
}

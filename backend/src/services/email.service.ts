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

    if (env.EMAIL_PROVIDER === 'resend') {
      // Resend SMTP endpoint
      this.transporter = nodemailer.createTransport({
        host: 'smtp.resend.com',
        port: 465,
        secure: true,
        auth: {
          user: 'resend',
          pass: env.RESEND_API_KEY.trim(),
        },
      });
      return this.transporter;
    }

    return null;
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

    // Console / Development mode
    if (env.EMAIL_PROVIDER === 'console' || (!env.RESEND_API_KEY && !env.SMTP_HOST)) {
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

    try {
      const transporter = this.getTransporter();
      if (!transporter) {
        console.warn('⚠️ No email transporter configured. Email not sent.');
        return false;
      }

      const info = await transporter.sendMail({
        from: env.EMAIL_FROM,
        to,
        subject,
        html: htmlContent,
        text: `Hello ${fullName},\n\nYour WaterWatch verification code is: ${otp}\n\nThis code expires in ${expiresInMinutes} minutes.\n\nWaterWatch Smart City Team`,
      });

      console.log(`✉️ OTP email sent to ${to}: MessageId=${info.messageId}`);
      return true;
    } catch (error: any) {
      console.error(`❌ Failed to send email to ${to}:`, error.message || error);
      // If live sending fails, log OTP in server console as fallback so the developer/user isn't completely blocked
      console.log(`[FALLBACK LOG] OTP for ${to} is: ${otp}`);
      throw {
        statusCode: 502,
        message: 'Could not deliver verification email. Please check your email address or try again in a few moments.',
        code: 'EMAIL_DELIVERY_FAILED',
      };
    }
  }
}

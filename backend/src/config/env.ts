import dotenv from 'dotenv';
import path from 'path';

// Load .env from backend directory
dotenv.config({ path: path.resolve(__dirname, '../../.env') });

export const env = {
  PORT: parseInt(process.env.PORT || '5001', 10),
  NODE_ENV: process.env.NODE_ENV || 'development',
  DATABASE_URL: process.env.DATABASE_URL || '',
  JWT_SECRET: process.env.JWT_SECRET || 'waterwatch_default_dev_secret_key_change_me_32chars',
  JWT_EXPIRES_IN: process.env.JWT_EXPIRES_IN || '7d',
  CORS_ORIGIN: process.env.CORS_ORIGIN || '*',
  IOT_API_KEY: process.env.IOT_API_KEY || 'waterwatch_iot_esp8266_node_ingest_key_2026',
  INITIAL_OFFICER_NAME: process.env.INITIAL_OFFICER_NAME || 'Rajesh Varma',
  INITIAL_OFFICER_EMAIL: process.env.INITIAL_OFFICER_EMAIL || 'officer@demo.com',
  INITIAL_OFFICER_PASSWORD: process.env.INITIAL_OFFICER_PASSWORD || 'Officer@123',
  INITIAL_OFFICER_DEPARTMENT: process.env.INITIAL_OFFICER_DEPARTMENT || 'Municipal Water Supply & Sewerage Board',
  INITIAL_OFFICER_PHONE: process.env.INITIAL_OFFICER_PHONE || '+91 98765 43210',
  INITIAL_OFFICER_ZONE: process.env.INITIAL_OFFICER_ZONE || 'Central City Zone',

  // Email Service Configuration
  EMAIL_PROVIDER: (process.env.EMAIL_PROVIDER || 'console').toLowerCase().trim(), // 'resend' | 'smtp' | 'console'
  RESEND_API_KEY: (process.env.RESEND_API_KEY || '').trim(),
  SMTP_HOST: (process.env.SMTP_HOST || (process.env.SMTP_USER?.includes('gmail') ? 'smtp.gmail.com' : '')).trim(),
  SMTP_PORT: parseInt(process.env.SMTP_PORT || '587', 10),
  SMTP_USER: (process.env.SMTP_USER || '').trim(),
  SMTP_PASS: (process.env.SMTP_PASS || '').trim(),
  SMTP_SECURE: process.env.SMTP_SECURE === 'true' || process.env.SMTP_PORT === '465',
  EMAIL_FROM: (process.env.EMAIL_FROM || (process.env.SMTP_USER ? `WaterWatch <${process.env.SMTP_USER.trim()}>` : 'WaterWatch <onboarding@resend.dev>')).trim(),

  // OTP Configuration
  OTP_EXPIRY_MINUTES: parseInt(process.env.OTP_EXPIRY_MINUTES || '10', 10),
  OTP_RESEND_COOLDOWN_SECONDS: parseInt(process.env.OTP_RESEND_COOLDOWN_SECONDS || '60', 10),
  OTP_MAX_ATTEMPTS: parseInt(process.env.OTP_MAX_ATTEMPTS || '5', 10),
};

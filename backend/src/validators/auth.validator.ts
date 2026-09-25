import { z } from 'zod';

export const loginSchema = z.object({
  email: z.string().email('Please provide a valid email address').trim().toLowerCase(),
  password: z.string().min(6, 'Password must be at least 6 characters long'),
});

export const registerWorkerSchema = z.object({
  fullName: z.string().min(2, 'Full name must be at least 2 characters').trim(),
  email: z.string().email('Please provide a valid email address').trim().toLowerCase(),
  password: z.string().min(6, 'Password must be at least 6 characters long'),
  phoneNumber: z.string().optional(),
  department: z.string().optional().default('Field Engineering & Maintenance'),
  workerId: z.string().optional(), // Auto-generated if omitted, or formatted e.g. WRK-005
  zone: z.string().optional().default('Central City Zone'),
  // Reject any attempt by client to pass role as OFFICER
  role: z.enum(['WORKER', 'fieldWorker']).optional().default('WORKER'),
});

export const verifyEmailSchema = z.object({
  email: z.string().email('Please provide a valid email address').trim().toLowerCase(),
  otp: z.string().length(6, 'OTP must be a 6-digit numeric code').regex(/^\d{6}$/, 'OTP must contain only digits'),
});

export const resendOtpSchema = z.object({
  email: z.string().email('Please provide a valid email address').trim().toLowerCase(),
});

export const forgotPasswordSchema = z.object({
  email: z.string().email('Please provide a valid email address').trim().toLowerCase(),
});

export const resetPasswordSchema = z.object({
  email: z.string().email('Please provide a valid email address').trim().toLowerCase(),
  otp: z.string().length(6, 'OTP must be a 6-digit numeric code').regex(/^\d{6}$/, 'OTP must contain only digits'),
  newPassword: z.string().min(6, 'New password must be at least 6 characters long'),
});

export type LoginInput = z.infer<typeof loginSchema>;
export type RegisterWorkerInput = z.infer<typeof registerWorkerSchema>;
export type VerifyEmailInput = z.infer<typeof verifyEmailSchema>;
export type ResendOtpInput = z.infer<typeof resendOtpSchema>;
export type ForgotPasswordInput = z.infer<typeof forgotPasswordSchema>;
export type ResetPasswordInput = z.infer<typeof resetPasswordSchema>;


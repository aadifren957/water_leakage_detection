import { Router } from 'express';
import { AuthController } from '../controllers/auth.controller';
import { validate } from '../middleware/validate.middleware';
import {
  loginSchema,
  registerWorkerSchema,
  verifyEmailSchema,
  resendOtpSchema,
  forgotPasswordSchema,
  resetPasswordSchema,
} from '../validators/auth.validator';
import { authenticate } from '../middleware/auth.middleware';
import {
  authLimiter,
  otpVerifyLimiter,
  otpResendLimiter,
  passwordResetLimiter,
} from '../middleware/rate-limiter.middleware';

const router = Router();

// Authentication & Registration
router.post('/login', authLimiter, validate(loginSchema), AuthController.login);
router.post('/register', authLimiter, validate(registerWorkerSchema), AuthController.registerWorker);

// Email OTP Verification
router.post('/verify-email', otpVerifyLimiter, validate(verifyEmailSchema), AuthController.verifyEmail);
router.post('/resend-otp', otpResendLimiter, validate(resendOtpSchema), AuthController.resendOtp);

// Password Recovery
router.post('/forgot-password', passwordResetLimiter, validate(forgotPasswordSchema), AuthController.forgotPassword);
router.post('/reset-password', passwordResetLimiter, validate(resetPasswordSchema), AuthController.resetPassword);

// Profile & Session
router.get('/me', authenticate, AuthController.getMe);
router.post('/logout', authenticate, AuthController.logout);

export default router;

import { Role, AccountStatus, VerificationPurpose } from '@prisma/client';
import { prisma } from '../config/db';
import { comparePassword, hashPassword } from '../utils/password';
import { generateToken } from '../utils/jwt';
import { OtpUtil } from '../utils/otp';
import { EmailService } from './email.service';
import {
  LoginInput,
  RegisterWorkerInput,
  VerifyEmailInput,
  ResendOtpInput,
  ForgotPasswordInput,
  ResetPasswordInput,
} from '../validators/auth.validator';
import { env } from '../config/env';

export class AuthService {
  /**
   * Authenticate a user by email & password
   */
  static async login(input: LoginInput) {
    const email = input.email.toLowerCase().trim();
    const user = await prisma.user.findUnique({
      where: { email },
    });

    if (!user) {
      throw { statusCode: 401, message: 'Invalid email or password credentials.', code: 'INVALID_CREDENTIALS' };
    }

    const isMatch = await comparePassword(input.password, user.passwordHash);
    if (!isMatch) {
      throw { statusCode: 401, message: 'Invalid email or password credentials.', code: 'INVALID_CREDENTIALS' };
    }

    // Check email verification and account status
    if (user.accountStatus === AccountStatus.PENDING_VERIFICATION) {
      throw {
        statusCode: 403,
        message: 'Your email address is not verified yet. Please enter the OTP sent to your inbox to activate your account.',
        code: 'UNVERIFIED_EMAIL',
        data: { email: user.email, requiresVerification: true },
      };
    }

    if (user.accountStatus === AccountStatus.SUSPENDED || !user.isActive) {
      throw {
        statusCode: 403,
        message: 'This account has been deactivated or suspended. Please contact municipal administration.',
        code: 'ACCOUNT_DISABLED',
      };
    }

    if (user.accountStatus === AccountStatus.PENDING_APPROVAL) {
      throw {
        statusCode: 403,
        message: 'Your account is currently awaiting administrative approval.',
        code: 'PENDING_APPROVAL',
      };
    }

    const token = generateToken({
      userId: user.id,
      email: user.email,
      role: user.role,
      accountStatus: user.accountStatus,
      workerId: user.workerId,
      fullName: user.fullName,
    });

    return {
      token,
      user: {
        id: user.id,
        name: user.fullName,
        email: user.email,
        role: user.role === Role.OFFICER ? 'municipalOfficer' : 'fieldWorker',
        accountStatus: user.accountStatus,
        isEmailVerified: !!user.emailVerifiedAt,
        department: user.department || (user.role === Role.OFFICER ? 'Municipal Water Board' : 'Field Maintenance'),
        workerId: user.workerId,
        phoneNumber: user.phoneNumber,
        zone: user.zone,
        isActive: user.isActive,
      },
    };
  }

  /**
   * Register a new Field Worker (Workers only, Officer registration is strictly protected)
   */
  static async registerWorker(input: RegisterWorkerInput) {
    const email = input.email.toLowerCase().trim();
    const existing = await prisma.user.findUnique({
      where: { email },
    });

    let user;

    if (existing) {
      // If user already active and verified, reject
      if (existing.accountStatus === AccountStatus.ACTIVE) {
        throw { statusCode: 409, message: 'An active account with this email address already exists. Please log in.', code: 'EMAIL_EXISTS' };
      }

      // If pending verification, update password and details
      const passwordHash = await hashPassword(input.password);
      user = await prisma.user.update({
        where: { id: existing.id },
        data: {
          fullName: input.fullName.trim(),
          passwordHash,
          phoneNumber: input.phoneNumber,
          department: input.department || 'Field Engineering & Maintenance',
          zone: input.zone || 'Central City Zone',
        },
      });
    } else {
      // Auto-assign or validate workerId
      let workerId = input.workerId?.toUpperCase().trim();
      if (workerId) {
        const existingWorkerId = await prisma.user.findUnique({
          where: { workerId },
        });
        if (existingWorkerId) {
          throw { statusCode: 409, message: `Worker ID "${workerId}" is already assigned to another technician.`, code: 'WORKER_ID_EXISTS' };
        }
      } else {
        const count = await prisma.user.count({ where: { role: Role.WORKER } });
        workerId = `WRK-${String(count + 101).padStart(3, '0')}`;
      }

      const passwordHash = await hashPassword(input.password);

      user = await prisma.user.create({
        data: {
          fullName: input.fullName.trim(),
          email,
          passwordHash,
          role: Role.WORKER,
          accountStatus: AccountStatus.PENDING_VERIFICATION,
          emailVerifiedAt: null,
          phoneNumber: input.phoneNumber,
          department: input.department || 'Field Engineering & Maintenance',
          workerId,
          zone: input.zone || 'Central City Zone',
          isActive: true,
        },
      });
    }

    // Invalidate prior active verification tokens
    await prisma.verificationToken.updateMany({
      where: {
        email,
        purpose: VerificationPurpose.EMAIL_VERIFICATION,
        consumedAt: null,
      },
      data: { consumedAt: new Date() },
    });

    // Generate secure 6-digit OTP
    const otp = OtpUtil.generateOtp(6);
    const tokenHash = OtpUtil.hashOtp(otp);
    const expiresAt = new Date(Date.now() + env.OTP_EXPIRY_MINUTES * 60 * 1000);

    await prisma.verificationToken.create({
      data: {
        userId: user.id,
        email,
        tokenHash,
        purpose: VerificationPurpose.EMAIL_VERIFICATION,
        expiresAt,
        attempts: 0,
      },
    });

    // Deliver OTP via Email
    await EmailService.sendOtpEmail({
      to: email,
      fullName: user.fullName,
      otp,
      purpose: 'EMAIL_VERIFICATION',
      expiresInMinutes: env.OTP_EXPIRY_MINUTES,
    });

    return {
      message: `Verification code sent to ${email}. Please verify your email to activate your account.`,
      email,
      requiresVerification: true,
      expiresInMinutes: env.OTP_EXPIRY_MINUTES,
    };
  }

  /**
   * Verify email address with 6-digit OTP
   */
  static async verifyEmail(input: VerifyEmailInput) {
    const email = input.email.toLowerCase().trim();
    const otp = input.otp.trim();

    const user = await prisma.user.findUnique({
      where: { email },
    });

    if (!user) {
      throw { statusCode: 404, message: 'No registration record found for this email.', code: 'USER_NOT_FOUND' };
    }

    if (user.accountStatus === AccountStatus.ACTIVE && user.emailVerifiedAt) {
      // User is already verified, return session directly
      const token = generateToken({
        userId: user.id,
        email: user.email,
        role: user.role,
        accountStatus: user.accountStatus,
        workerId: user.workerId,
        fullName: user.fullName,
      });

      return {
        token,
        user: {
          id: user.id,
          name: user.fullName,
          email: user.email,
          role: user.role === Role.OFFICER ? 'municipalOfficer' : 'fieldWorker',
          accountStatus: user.accountStatus,
          isEmailVerified: true,
          department: user.department || '',
          workerId: user.workerId,
          phoneNumber: user.phoneNumber,
          zone: user.zone,
          isActive: user.isActive,
        },
      };
    }

    // Find latest active verification token
    const tokenRecord = await prisma.verificationToken.findFirst({
      where: {
        email,
        purpose: VerificationPurpose.EMAIL_VERIFICATION,
        consumedAt: null,
      },
      orderBy: { createdAt: 'desc' },
    });

    if (!tokenRecord) {
      throw {
        statusCode: 400,
        message: 'No active verification code found. Please request a new OTP.',
        code: 'INVALID_OTP',
      };
    }

    if (tokenRecord.expiresAt < new Date()) {
      throw {
        statusCode: 400,
        message: 'Verification code has expired. Please request a fresh OTP.',
        code: 'OTP_EXPIRED',
      };
    }

    if (tokenRecord.attempts >= env.OTP_MAX_ATTEMPTS) {
      throw {
        statusCode: 429,
        message: 'Too many incorrect attempts. This code is locked. Please request a new OTP.',
        code: 'MAX_ATTEMPTS_EXCEEDED',
      };
    }

    // Verify OTP
    const isValid = OtpUtil.verifyOtp(otp, tokenRecord.tokenHash);
    if (!isValid) {
      await prisma.verificationToken.update({
        where: { id: tokenRecord.id },
        data: { attempts: { increment: 1 } },
      });

      const remaining = env.OTP_MAX_ATTEMPTS - (tokenRecord.attempts + 1);
      throw {
        statusCode: 400,
        message: `Invalid verification code. ${remaining > 0 ? `${remaining} attempts remaining.` : 'Please request a new code.'}`,
        code: 'INVALID_OTP',
      };
    }

    // Activate user & consume token in transaction
    const now = new Date();
    const updatedUser = await prisma.$transaction(async (tx) => {
      await tx.verificationToken.update({
        where: { id: tokenRecord.id },
        data: { consumedAt: now },
      });

      return tx.user.update({
        where: { id: user.id },
        data: {
          accountStatus: AccountStatus.ACTIVE,
          emailVerifiedAt: now,
          isActive: true,
        },
      });
    });

    const sessionToken = generateToken({
      userId: updatedUser.id,
      email: updatedUser.email,
      role: updatedUser.role,
      accountStatus: updatedUser.accountStatus,
      workerId: updatedUser.workerId,
      fullName: updatedUser.fullName,
    });

    return {
      token: sessionToken,
      user: {
        id: updatedUser.id,
        name: updatedUser.fullName,
        email: updatedUser.email,
        role: updatedUser.role === Role.OFFICER ? 'municipalOfficer' : 'fieldWorker',
        accountStatus: updatedUser.accountStatus,
        isEmailVerified: true,
        department: updatedUser.department || '',
        workerId: updatedUser.workerId,
        phoneNumber: updatedUser.phoneNumber,
        zone: updatedUser.zone,
        isActive: updatedUser.isActive,
      },
    };
  }

  /**
   * Resend a fresh OTP with cooldown protection
   */
  static async resendOtp(input: ResendOtpInput) {
    const email = input.email.toLowerCase().trim();
    const user = await prisma.user.findUnique({
      where: { email },
    });

    // Prevent account enumeration by always returning generic message
    if (!user || user.accountStatus === AccountStatus.ACTIVE) {
      return {
        success: true,
        message: 'If an unverified registration exists for this email, a new verification code has been sent.',
      };
    }

    // Check cooldown from latest token
    const lastToken = await prisma.verificationToken.findFirst({
      where: {
        email,
        purpose: VerificationPurpose.EMAIL_VERIFICATION,
      },
      orderBy: { createdAt: 'desc' },
    });

    if (lastToken) {
      const elapsedSeconds = Math.floor((Date.now() - lastToken.createdAt.getTime()) / 1000);
      if (elapsedSeconds < env.OTP_RESEND_COOLDOWN_SECONDS) {
        const remaining = env.OTP_RESEND_COOLDOWN_SECONDS - elapsedSeconds;
        throw {
          statusCode: 429,
          message: `Please wait ${remaining} seconds before requesting another code.`,
          code: 'RESEND_COOLDOWN',
          data: { remainingSeconds: remaining },
        };
      }
    }

    // Invalidate prior active tokens
    await prisma.verificationToken.updateMany({
      where: {
        email,
        purpose: VerificationPurpose.EMAIL_VERIFICATION,
        consumedAt: null,
      },
      data: { consumedAt: new Date() },
    });

    // Generate and store new OTP
    const otp = OtpUtil.generateOtp(6);
    const tokenHash = OtpUtil.hashOtp(otp);
    const expiresAt = new Date(Date.now() + env.OTP_EXPIRY_MINUTES * 60 * 1000);

    await prisma.verificationToken.create({
      data: {
        userId: user.id,
        email,
        tokenHash,
        purpose: VerificationPurpose.EMAIL_VERIFICATION,
        expiresAt,
        attempts: 0,
      },
    });

    // Send email
    await EmailService.sendOtpEmail({
      to: email,
      fullName: user.fullName,
      otp,
      purpose: 'EMAIL_VERIFICATION',
      expiresInMinutes: env.OTP_EXPIRY_MINUTES,
    });

    return {
      success: true,
      message: 'A fresh verification code has been sent to your email.',
    };
  }

  /**
   * Request password recovery OTP
   */
  static async forgotPassword(input: ForgotPasswordInput) {
    const email = input.email.toLowerCase().trim();
    const user = await prisma.user.findUnique({
      where: { email },
    });

    // Generic response against user enumeration
    if (!user || user.accountStatus !== AccountStatus.ACTIVE) {
      return {
        success: true,
        message: 'If an active account with that email exists, password reset instructions have been sent.',
      };
    }

    // Invalidate prior reset tokens
    await prisma.verificationToken.updateMany({
      where: {
        email,
        purpose: VerificationPurpose.PASSWORD_RESET,
        consumedAt: null,
      },
      data: { consumedAt: new Date() },
    });

    const otp = OtpUtil.generateOtp(6);
    const tokenHash = OtpUtil.hashOtp(otp);
    const expiresAt = new Date(Date.now() + env.OTP_EXPIRY_MINUTES * 60 * 1000);

    await prisma.verificationToken.create({
      data: {
        userId: user.id,
        email,
        tokenHash,
        purpose: VerificationPurpose.PASSWORD_RESET,
        expiresAt,
        attempts: 0,
      },
    });

    await EmailService.sendOtpEmail({
      to: email,
      fullName: user.fullName,
      otp,
      purpose: 'PASSWORD_RESET',
      expiresInMinutes: env.OTP_EXPIRY_MINUTES,
    });

    return {
      success: true,
      message: 'If an active account with that email exists, password reset instructions have been sent.',
    };
  }

  /**
   * Reset password with valid OTP
   */
  static async resetPassword(input: ResetPasswordInput) {
    const email = input.email.toLowerCase().trim();
    const otp = input.otp.trim();

    const user = await prisma.user.findUnique({
      where: { email },
    });

    if (!user) {
      throw { statusCode: 404, message: 'User account not found.', code: 'USER_NOT_FOUND' };
    }

    const tokenRecord = await prisma.verificationToken.findFirst({
      where: {
        email,
        purpose: VerificationPurpose.PASSWORD_RESET,
        consumedAt: null,
      },
      orderBy: { createdAt: 'desc' },
    });

    if (!tokenRecord) {
      throw { statusCode: 400, message: 'Invalid or expired password reset request. Please try again.', code: 'INVALID_RESET_REQUEST' };
    }

    if (tokenRecord.expiresAt < new Date()) {
      throw { statusCode: 400, message: 'Password reset code has expired. Please request a new one.', code: 'OTP_EXPIRED' };
    }

    if (tokenRecord.attempts >= env.OTP_MAX_ATTEMPTS) {
      throw { statusCode: 429, message: 'Too many incorrect attempts. Please request a fresh reset code.', code: 'MAX_ATTEMPTS_EXCEEDED' };
    }

    const isValid = OtpUtil.verifyOtp(otp, tokenRecord.tokenHash);
    if (!isValid) {
      await prisma.verificationToken.update({
        where: { id: tokenRecord.id },
        data: { attempts: { increment: 1 } },
      });

      const remaining = env.OTP_MAX_ATTEMPTS - (tokenRecord.attempts + 1);
      throw {
        statusCode: 400,
        message: `Invalid reset code. ${remaining > 0 ? `${remaining} attempts remaining.` : 'Please request a new code.'}`,
        code: 'INVALID_OTP',
      };
    }

    const passwordHash = await hashPassword(input.newPassword);

    await prisma.$transaction([
      prisma.verificationToken.update({
        where: { id: tokenRecord.id },
        data: { consumedAt: new Date() },
      }),
      prisma.user.update({
        where: { id: user.id },
        data: {
          passwordHash,
          accountStatus: AccountStatus.ACTIVE,
          isActive: true,
        },
      }),
    ]);

    return {
      success: true,
      message: 'Your password has been reset successfully. You can now log in with your new password.',
    };
  }

  /**
   * Get current authenticated user profile
   */
  static async getMe(userId: string) {
    const user = await prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      throw { statusCode: 404, message: 'User profile not found.', code: 'USER_NOT_FOUND' };
    }

    return {
      id: user.id,
      name: user.fullName,
      email: user.email,
      role: user.role === Role.OFFICER ? 'municipalOfficer' : 'fieldWorker',
      accountStatus: user.accountStatus,
      isEmailVerified: !!user.emailVerifiedAt,
      department: user.department || '',
      workerId: user.workerId,
      phoneNumber: user.phoneNumber,
      zone: user.zone,
      isActive: user.isActive,
    };
  }

  /**
   * Initialize or verify initial Municipal Officer account safely
   */
  static async ensureInitialOfficer() {
    const officerEmail = env.INITIAL_OFFICER_EMAIL.toLowerCase().trim();
    const existing = await prisma.user.findUnique({
      where: { email: officerEmail },
    });

    if (!existing) {
      const passwordHash = await hashPassword(env.INITIAL_OFFICER_PASSWORD);
      await prisma.user.create({
        data: {
          fullName: env.INITIAL_OFFICER_NAME,
          email: officerEmail,
          passwordHash,
          role: Role.OFFICER,
          accountStatus: AccountStatus.ACTIVE,
          emailVerifiedAt: new Date(),
          department: env.INITIAL_OFFICER_DEPARTMENT,
          phoneNumber: env.INITIAL_OFFICER_PHONE,
          zone: env.INITIAL_OFFICER_ZONE,
          isActive: true,
        },
      });
      console.log(`🛡️ Initial Municipal Officer account provisioned: ${officerEmail}`);
    } else if (existing.accountStatus !== AccountStatus.ACTIVE || !existing.emailVerifiedAt) {
      await prisma.user.update({
        where: { id: existing.id },
        data: {
          accountStatus: AccountStatus.ACTIVE,
          emailVerifiedAt: new Date(),
          isActive: true,
        },
      });
    }
  }
}

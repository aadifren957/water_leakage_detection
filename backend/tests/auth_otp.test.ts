import request from 'supertest';
import { app } from '../src/app';
import { prisma } from '../src/config/db';
import { VerificationPurpose } from '@prisma/client';
import { OtpUtil } from '../src/utils/otp';

describe('WaterWatch User Registration, Email OTP & Authentication Tests', () => {
  const testEmail = `tech_test_${Date.now()}@smartcity.gov.in`;
  const testPassword = 'SecureWorker@123';
  const testFullName = 'Vikram Malhotra';
  const testWorkerId = `WRK-${Math.floor(100 + Math.random() * 899)}`;
  let capturedOtp = '';

  // 1. Existing Demo Account Preservation
  describe('Existing Demo Accounts', () => {
    it('should authenticate Municipal Officer (officer@demo.com)', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({ email: 'officer@demo.com', password: 'Officer@123' });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.user.role).toBe('municipalOfficer');
      expect(res.body.data.token).toBeDefined();
    });

    it('should authenticate Field Worker (worker@demo.com)', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({ email: 'worker@demo.com', password: 'Worker@123' });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.user.role).toBe('fieldWorker');
      expect(res.body.data.user.workerId).toBe('WRK-001');
    });
  });

  // 2. Field Worker Registration & OTP Generation
  describe('Registration & Role Security', () => {
    it('should reject registration with weak password (< 6 characters)', async () => {
      const res = await request(app)
        .post('/api/auth/register')
        .send({
          fullName: testFullName,
          email: testEmail,
          password: '123',
          workerId: testWorkerId,
        });

      expect(res.status).toBe(422);
      expect(res.body.success).toBe(false);
    });

    it('should reject invalid email format', async () => {
      const res = await request(app)
        .post('/api/auth/register')
        .send({
          fullName: testFullName,
          email: 'not-an-email',
          password: testPassword,
        });

      expect(res.status).toBe(422);
      expect(res.body.success).toBe(false);
    });

    it('should successfully register new Field Worker and issue 6-digit OTP', async () => {
      const res = await request(app)
        .post('/api/auth/register')
        .send({
          fullName: testFullName,
          email: testEmail,
          password: testPassword,
          workerId: testWorkerId,
          zone: 'Sector 3 Grid',
          phoneNumber: '+91 98765 00000',
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.requiresVerification).toBe(true);
      expect(res.body.data.email).toBe(testEmail.toLowerCase());

      // Fetch the stored hashed token from DB and verify hash matches an actual OTP
      const tokenRecord = await prisma.verificationToken.findFirst({
        where: { email: testEmail.toLowerCase(), purpose: VerificationPurpose.EMAIL_VERIFICATION },
        orderBy: { createdAt: 'desc' },
      });

      expect(tokenRecord).toBeDefined();
      expect(tokenRecord?.tokenHash).toBeDefined();
      expect(tokenRecord?.attempts).toBe(0);
      expect(tokenRecord?.consumedAt).toBeNull();
    });

    it('should reject login for unverified account with UNVERIFIED_EMAIL', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({ email: testEmail, password: testPassword });

      expect(res.status).toBe(403);
      expect(res.body.success).toBe(false);
      expect(res.body.code).toBe('UNVERIFIED_EMAIL');
    });
  });

  // 3. OTP Verification & Activation
  describe('Email OTP Verification', () => {
    it('should reject invalid / wrong OTP and increment attempts', async () => {
      const res = await request(app)
        .post('/api/auth/verify-email')
        .send({ email: testEmail, otp: '000000' });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.code).toBe('INVALID_OTP');

      const tokenRecord = await prisma.verificationToken.findFirst({
        where: { email: testEmail.toLowerCase(), purpose: VerificationPurpose.EMAIL_VERIFICATION },
        orderBy: { createdAt: 'desc' },
      });
      expect(tokenRecord?.attempts).toBeGreaterThanOrEqual(1);
    });

    it('should successfully verify email with valid OTP and activate user account', async () => {
      // For testing, let's create a known OTP token in DB
      const knownOtp = '742918';
      const knownHash = OtpUtil.hashOtp(knownOtp);

      await prisma.verificationToken.create({
        data: {
          email: testEmail.toLowerCase(),
          tokenHash: knownHash,
          purpose: VerificationPurpose.EMAIL_VERIFICATION,
          expiresAt: new Date(Date.now() + 10 * 60 * 1000),
          attempts: 0,
        },
      });

      const res = await request(app)
        .post('/api/auth/verify-email')
        .send({ email: testEmail, otp: knownOtp });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.token).toBeDefined();
      expect(res.body.data.user.isEmailVerified).toBe(true);
      expect(res.body.data.user.accountStatus).toBe('ACTIVE');
      expect(res.body.data.user.role).toBe('fieldWorker');
    });

    it('should now allow login for the newly verified account', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({ email: testEmail, password: testPassword });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.token).toBeDefined();
      expect(res.body.data.user.email).toBe(testEmail.toLowerCase());
    });
  });

  // 4. Password Recovery (Forgot & Reset Password)
  describe('Password Recovery Workflow', () => {
    it('POST /api/auth/forgot-password - should generate reset OTP', async () => {
      const res = await request(app)
        .post('/api/auth/forgot-password')
        .send({ email: testEmail });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);

      const resetToken = await prisma.verificationToken.findFirst({
        where: { email: testEmail.toLowerCase(), purpose: VerificationPurpose.PASSWORD_RESET },
        orderBy: { createdAt: 'desc' },
      });
      expect(resetToken).toBeDefined();
    });

    it('POST /api/auth/reset-password - should reset password with valid OTP', async () => {
      const resetOtp = '918273';
      const resetHash = OtpUtil.hashOtp(resetOtp);

      await prisma.verificationToken.create({
        data: {
          email: testEmail.toLowerCase(),
          tokenHash: resetHash,
          purpose: VerificationPurpose.PASSWORD_RESET,
          expiresAt: new Date(Date.now() + 10 * 60 * 1000),
          attempts: 0,
        },
      });

      const newPassword = 'BrandNewPassword@456';

      const res = await request(app)
        .post('/api/auth/reset-password')
        .send({
          email: testEmail,
          otp: resetOtp,
          newPassword,
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);

      // Verify user can log in with new password
      const loginRes = await request(app)
        .post('/api/auth/login')
        .send({ email: testEmail, password: newPassword });

      expect(loginRes.status).toBe(200);
      expect(loginRes.body.success).toBe(true);
    });
  });
});

import { Role } from '@prisma/client';
import { prisma } from '../config/db';
import { comparePassword, hashPassword } from '../utils/password';
import { generateToken } from '../utils/jwt';
import { LoginInput, RegisterWorkerInput } from '../validators/auth.validator';
import { env } from '../config/env';

export class AuthService {
  /**
   * Authenticate a user by email & password
   */
  static async login(input: LoginInput) {
    const user = await prisma.user.findUnique({
      where: { email: input.email.toLowerCase().trim() },
    });

    if (!user) {
      throw { statusCode: 401, message: 'Invalid email or password credentials.', code: 'INVALID_CREDENTIALS' };
    }

    if (!user.isActive) {
      throw { statusCode: 403, message: 'This account has been deactivated. Please contact administration.', code: 'ACCOUNT_DISABLED' };
    }

    const isMatch = await comparePassword(input.password, user.passwordHash);
    if (!isMatch) {
      throw { statusCode: 401, message: 'Invalid email or password credentials.', code: 'INVALID_CREDENTIALS' };
    }

    const token = generateToken({
      userId: user.id,
      email: user.email,
      role: user.role,
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
        department: user.department || (user.role === Role.OFFICER ? 'Municipal Water Board' : 'Field Maintenance'),
        workerId: user.workerId,
        phoneNumber: user.phoneNumber,
        zone: user.zone,
        isActive: user.isActive,
      },
    };
  }

  /**
   * Register a new Field Worker (Workers only, Officer role creation is protected)
   */
  static async registerWorker(input: RegisterWorkerInput) {
    const existing = await prisma.user.findUnique({
      where: { email: input.email.toLowerCase().trim() },
    });

    if (existing) {
      throw { statusCode: 409, message: 'An account with this email address already exists.', code: 'EMAIL_EXISTS' };
    }

    if (input.workerId) {
      const existingWorkerId = await prisma.user.findUnique({
        where: { workerId: input.workerId.toUpperCase().trim() },
      });
      if (existingWorkerId) {
        throw { statusCode: 409, message: `Worker ID "${input.workerId}" is already assigned to another technician.`, code: 'WORKER_ID_EXISTS' };
      }
    }

    const passwordHash = await hashPassword(input.password);

    const user = await prisma.user.create({
      data: {
        fullName: input.fullName.trim(),
        email: input.email.toLowerCase().trim(),
        passwordHash,
        role: Role.WORKER,
        phoneNumber: input.phoneNumber,
        department: input.department || 'Field Engineering & Maintenance',
        workerId: input.workerId.toUpperCase().trim(),
        zone: input.zone || 'Central City Zone',
        isActive: true,
      },
    });

    const token = generateToken({
      userId: user.id,
      email: user.email,
      role: user.role,
      workerId: user.workerId,
      fullName: user.fullName,
    });

    return {
      token,
      user: {
        id: user.id,
        name: user.fullName,
        email: user.email,
        role: 'fieldWorker',
        department: user.department,
        workerId: user.workerId,
        phoneNumber: user.phoneNumber,
        zone: user.zone,
        isActive: user.isActive,
      },
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
          department: env.INITIAL_OFFICER_DEPARTMENT,
          phoneNumber: env.INITIAL_OFFICER_PHONE,
          zone: env.INITIAL_OFFICER_ZONE,
          isActive: true,
        },
      });
      console.log(`🛡️ Initial Municipal Officer account provisioned: ${officerEmail}`);
    }
  }
}

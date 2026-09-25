import { Request } from 'express';
import { Role, AccountStatus } from '@prisma/client';

export interface JwtPayload {
  userId: string;
  email: string;
  role: Role;
  accountStatus: AccountStatus;
  workerId?: string | null;
  fullName: string;
}

export interface AuthenticatedRequest extends Request {
  user?: JwtPayload;
}

export interface ApiResponse<T = any> {
  success: boolean;
  message: string;
  data?: T;
  code?: string;
  errors?: any;
}

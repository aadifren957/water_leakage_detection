import { Response, NextFunction } from 'express';
import { Role } from '@prisma/client';
import { AuthenticatedRequest } from '../types';
import { verifyToken } from '../utils/jwt';
import { sendError } from '../utils/response';
import { prisma } from '../config/db';

export async function authenticate(
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
): Promise<void> {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    sendError(res, 'Authentication token required. Please log in.', 401, 'UNAUTHORIZED');
    return;
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = verifyToken(token);
    
    // Verify user still exists and is active in DB
    const user = await prisma.user.findUnique({
      where: { id: decoded.userId },
      select: { id: true, email: true, role: true, workerId: true, fullName: true, isActive: true },
    });

    if (!user || !user.isActive) {
      sendError(res, 'Account is inactive or does not exist.', 401, 'ACCOUNT_INACTIVE');
      return;
    }

    req.user = {
      userId: user.id,
      email: user.email,
      role: user.role,
      workerId: user.workerId,
      fullName: user.fullName,
    };

    next();
  } catch (error) {
    sendError(res, 'Invalid or expired session token. Please log in again.', 401, 'TOKEN_INVALID');
  }
}

export function requireRole(...roles: Role[]) {
  return (req: AuthenticatedRequest, res: Response, next: NextFunction): void => {
    if (!req.user) {
      sendError(res, 'Authentication required.', 401, 'UNAUTHORIZED');
      return;
    }

    if (!roles.includes(req.user.role)) {
      sendError(
        res,
        `Access denied. This action requires ${roles.join(' or ')} privileges.`,
        403,
        'FORBIDDEN'
      );
      return;
    }

    next();
  };
}

import { Request, Response, NextFunction } from 'express';
import { sendError } from '../utils/response';
import { env } from '../config/env';

export function errorHandler(
  err: any,
  req: Request,
  res: Response,
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  next: NextFunction
): Response {
  if (env.NODE_ENV !== 'test') {
    console.error('Unhandled Server Error:', err);
  }

  // Handle known error types
  if (err.name === 'UnauthorizedError' || err.name === 'JsonWebTokenError') {
    return sendError(res, 'Invalid or expired authentication token.', 401, 'UNAUTHORIZED');
  }

  if (err.code === 'P2002') {
    return sendError(res, 'A record with this unique field already exists.', 409, 'DUPLICATE_RESOURCE');
  }

  if (err.code === 'P2025') {
    return sendError(res, 'The requested resource was not found.', 404, 'NOT_FOUND');
  }

  const statusCode = err.statusCode || 500;
  const message = statusCode === 500 && env.NODE_ENV === 'production'
    ? 'An unexpected internal server error occurred.'
    : err.message || 'Internal Server Error';

  return sendError(res, message, statusCode, err.code || 'INTERNAL_ERROR');
}

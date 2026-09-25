import { Response } from 'express';
import { ApiResponse } from '../types';

export function sendSuccess<T>(
  res: Response,
  message: string,
  data?: T,
  statusCode = 200
): Response {
  const body: ApiResponse<T> = {
    success: true,
    message,
    ...(data !== undefined && { data }),
  };
  return res.status(statusCode).json(body);
}

export function sendError(
  res: Response,
  message: string,
  statusCode = 400,
  code?: string,
  dataOrErrors?: any
): Response {
  const body: ApiResponse = {
    success: false,
    message,
    ...(code && { code }),
    ...(dataOrErrors && { data: dataOrErrors, errors: dataOrErrors }),
  };
  return res.status(statusCode).json(body);
}

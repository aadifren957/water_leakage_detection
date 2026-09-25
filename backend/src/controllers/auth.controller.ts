import { Response } from 'express';
import { AuthenticatedRequest } from '../types';
import { AuthService } from '../services/auth.service';
import { sendSuccess, sendError } from '../utils/response';

export class AuthController {
  static async login(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const result = await AuthService.login(req.body);
      sendSuccess(res, 'Login successful', result);
    } catch (error: any) {
      sendError(res, error.message || 'Login failed', error.statusCode || 400, error.code);
    }
  }

  static async registerWorker(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const result = await AuthService.registerWorker(req.body);
      sendSuccess(res, 'Field worker registered successfully', result, 201);
    } catch (error: any) {
      sendError(res, error.message || 'Registration failed', error.statusCode || 400, error.code);
    }
  }

  static async getMe(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Not authenticated', 401, 'UNAUTHORIZED');
        return;
      }
      const user = await AuthService.getMe(req.user.userId);
      sendSuccess(res, 'User profile retrieved', user);
    } catch (error: any) {
      sendError(res, error.message || 'Failed to fetch user profile', error.statusCode || 500, error.code);
    }
  }

  static async logout(req: AuthenticatedRequest, res: Response): Promise<void> {
    sendSuccess(res, 'Logged out successfully');
  }
}

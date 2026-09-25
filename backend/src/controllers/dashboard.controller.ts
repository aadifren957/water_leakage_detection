import { Response } from 'express';
import { AuthenticatedRequest } from '../types';
import { DashboardService } from '../services/dashboard.service';
import { sendSuccess, sendError } from '../utils/response';

export class DashboardController {
  static async getOfficerDashboard(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const data = await DashboardService.getOfficerDashboard(req.user!.userId);
      sendSuccess(res, 'Officer dashboard data retrieved', data);
    } catch (error: any) {
      sendError(res, error.message || 'Failed to fetch officer dashboard', error.statusCode || 500, error.code);
    }
  }

  static async getWorkerDashboard(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const data = await DashboardService.getWorkerDashboard(req.user!.userId);
      sendSuccess(res, 'Worker dashboard data retrieved', data);
    } catch (error: any) {
      sendError(res, error.message || 'Failed to fetch worker dashboard', error.statusCode || 500, error.code);
    }
  }
}

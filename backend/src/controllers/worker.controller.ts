import { Response } from 'express';
import { AuthenticatedRequest } from '../types';
import { WorkerService } from '../services/worker.service';
import { sendSuccess, sendError } from '../utils/response';

export class WorkerController {
  static async getWorkers(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const workers = await WorkerService.getWorkers();
      sendSuccess(res, 'Field workers retrieved', workers);
    } catch (error: any) {
      sendError(res, error.message || 'Failed to fetch workers', error.statusCode || 500, error.code);
    }
  }

  static async getWorkerById(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const id = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
      const worker = await WorkerService.getWorkerById(id);
      sendSuccess(res, 'Worker profile retrieved', worker);
    } catch (error: any) {
      sendError(res, error.message || 'Failed to fetch worker', error.statusCode || 404, error.code);
    }
  }

  static async getMyTasks(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const tasks = await WorkerService.getMyTasks(req.user!.userId);
      sendSuccess(res, 'Assigned tasks retrieved', tasks);
    } catch (error: any) {
      sendError(res, error.message || 'Failed to fetch tasks', error.statusCode || 500, error.code);
    }
  }

  static async getMySummary(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const summary = await WorkerService.getMySummary(req.user!.userId);
      sendSuccess(res, 'Worker summary metrics retrieved', summary);
    } catch (error: any) {
      sendError(res, error.message || 'Failed to fetch summary', error.statusCode || 500, error.code);
    }
  }
}

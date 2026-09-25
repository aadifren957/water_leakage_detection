import { Response } from 'express';
import { AuthenticatedRequest } from '../types';
import { IncidentService } from '../services/incident.service';
import { sendSuccess, sendError } from '../utils/response';

export class IncidentController {
  static async getIncidents(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const incidents = await IncidentService.getIncidents(req.user!, req.query as any);
      sendSuccess(res, 'Incidents retrieved successfully', incidents);
    } catch (error: any) {
      sendError(res, error.message || 'Failed to fetch incidents', error.statusCode || 500, error.code);
    }
  }

  static async getIncidentById(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const id = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
      const incident = await IncidentService.getIncidentById(id, req.user!);
      sendSuccess(res, 'Incident details retrieved', incident);
    } catch (error: any) {
      sendError(res, error.message || 'Failed to fetch incident', error.statusCode || 404, error.code);
    }
  }

  static async createIncident(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const incident = await IncidentService.createIncident(req.body, req.user);
      sendSuccess(res, 'Incident recorded successfully', incident, 201);
    } catch (error: any) {
      sendError(res, error.message || 'Failed to create incident', error.statusCode || 400, error.code);
    }
  }

  static async acknowledgeIncident(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const id = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
      const incident = await IncidentService.acknowledgeIncident(id, req.user!);
      sendSuccess(res, 'Incident acknowledged successfully', incident);
    } catch (error: any) {
      sendError(res, error.message || 'Failed to acknowledge incident', error.statusCode || 400, error.code);
    }
  }

  static async assignWorker(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const id = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
      const incident = await IncidentService.assignWorker(
        id,
        req.body.workerId,
        req.user!
      );
      sendSuccess(res, 'Field technician assigned successfully', incident);
    } catch (error: any) {
      sendError(res, error.message || 'Failed to assign worker', error.statusCode || 400, error.code);
    }
  }

  static async resolveIncident(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const id = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
      const incident = await IncidentService.resolveIncident(
        id,
        req.body.repairNotes,
        req.user!
      );
      sendSuccess(res, 'Incident marked as resolved successfully', incident);
    } catch (error: any) {
      sendError(res, error.message || 'Failed to resolve incident', error.statusCode || 400, error.code);
    }
  }

  static async getIncidentHistory(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const id = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
      const history = await IncidentService.getIncidentHistory(id, req.user!);
      sendSuccess(res, 'Incident history timeline retrieved', history);
    } catch (error: any) {
      sendError(res, error.message || 'Failed to fetch history', error.statusCode || 404, error.code);
    }
  }
}

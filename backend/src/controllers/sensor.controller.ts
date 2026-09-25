import { Request, Response } from 'express';
import { SensorService } from '../services/sensor.service';
import { sendSuccess, sendError } from '../utils/response';

export class SensorController {
  static async getAllSensors(req: Request, res: Response): Promise<void> {
    try {
      const sensors = await SensorService.getAllSensors();
      sendSuccess(res, 'Sensors telemetry list retrieved', sensors);
    } catch (error: any) {
      sendError(res, error.message || 'Failed to fetch sensors', error.statusCode || 500, error.code);
    }
  }

  static async getSensorByDeviceId(req: Request, res: Response): Promise<void> {
    try {
      const deviceId = Array.isArray(req.params.deviceId) ? req.params.deviceId[0] : req.params.deviceId;
      const sensor = await SensorService.getSensorByDeviceId(deviceId);
      if (!sensor) {
        sendError(res, `Sensor device "${deviceId}" not found`, 404, 'NOT_FOUND');
        return;
      }
      sendSuccess(res, 'Sensor device reading retrieved', sensor);
    } catch (error: any) {
      sendError(res, error.message || 'Failed to fetch sensor reading', error.statusCode || 500, error.code);
    }
  }
}

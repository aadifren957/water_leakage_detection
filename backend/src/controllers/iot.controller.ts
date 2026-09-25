import { Request, Response } from 'express';
import { SensorService } from '../services/sensor.service';
import { sendSuccess, sendError } from '../utils/response';
import { env } from '../config/env';

export class IotController {
  static async ingestReading(req: Request, res: Response): Promise<void> {
    const apiKey = req.headers['x-api-key'] || req.headers['x-iot-key'] || (req.headers.authorization?.startsWith('Bearer ') ? req.headers.authorization.split(' ')[1] : null);

    if (!apiKey || apiKey !== env.IOT_API_KEY) {
      sendError(res, 'Unauthorized IoT device credential. Ingestion rejected.', 401, 'INVALID_DEVICE_CREDENTIAL');
      return;
    }

    try {
      const reading = await SensorService.ingestReading(req.body);
      sendSuccess(res, 'Telemetry reading ingested successfully', reading, 201);
    } catch (error: any) {
      sendError(res, error.message || 'Failed to ingest telemetry reading', error.statusCode || 400, error.code);
    }
  }
}

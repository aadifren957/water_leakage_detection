import { Router } from 'express';
import { IotController } from '../controllers/iot.controller';
import { validate } from '../middleware/validate.middleware';
import { iotReadingSchema } from '../validators/sensor.validator';

const router = Router();

// Device telemetry ingestion (Uses X-API-Key authentication)
router.post('/readings', validate(iotReadingSchema), IotController.ingestReading);

export default router;

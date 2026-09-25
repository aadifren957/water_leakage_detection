import { Router } from 'express';
import { SensorController } from '../controllers/sensor.controller';
import { authenticate } from '../middleware/auth.middleware';

const router = Router();

router.use(authenticate);

router.get('/readings', SensorController.getAllSensors);
router.get('/devices', SensorController.getAllSensors);
router.get('/devices/:deviceId/readings', SensorController.getSensorByDeviceId);

export default router;

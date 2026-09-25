import { Router } from 'express';
import authRoutes from './auth.routes';
import incidentRoutes from './incident.routes';
import workerRoutes from './worker.routes';
import dashboardRoutes from './dashboard.routes';
import sensorRoutes from './sensor.routes';
import notificationRoutes from './notification.routes';
import iotRoutes from './iot.routes';

const router = Router();

router.use('/auth', authRoutes);
router.use('/incidents', incidentRoutes);
router.use('/workers', workerRoutes);
router.use('/dashboard', dashboardRoutes);
router.use('/sensors', sensorRoutes);
router.use('/notifications', notificationRoutes);
router.use('/iot', iotRoutes);

export default router;

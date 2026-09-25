import { Router } from 'express';
import { Role } from '@prisma/client';
import { DashboardController } from '../controllers/dashboard.controller';
import { authenticate, requireRole } from '../middleware/auth.middleware';

const router = Router();

router.use(authenticate);

router.get('/officer', requireRole(Role.OFFICER), DashboardController.getOfficerDashboard);
router.get('/worker', requireRole(Role.WORKER), DashboardController.getWorkerDashboard);

export default router;

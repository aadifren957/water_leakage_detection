import { Router } from 'express';
import { Role } from '@prisma/client';
import { WorkerController } from '../controllers/worker.controller';
import { authenticate, requireRole } from '../middleware/auth.middleware';

const router = Router();

router.use(authenticate);

// Officer-only: Get all workers with active workload
router.get('/', requireRole(Role.OFFICER), WorkerController.getWorkers);

// Worker-only: Get logged-in worker's tasks and summary
router.get('/me/tasks', requireRole(Role.WORKER), WorkerController.getMyTasks);
router.get('/me/summary', requireRole(Role.WORKER), WorkerController.getMySummary);

// Get worker profile by ID
router.get('/:id', WorkerController.getWorkerById);

export default router;

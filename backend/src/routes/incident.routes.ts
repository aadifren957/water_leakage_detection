import { Router } from 'express';
import { Role } from '@prisma/client';
import { IncidentController } from '../controllers/incident.controller';
import { authenticate, requireRole } from '../middleware/auth.middleware';
import { validate } from '../middleware/validate.middleware';
import {
  createIncidentSchema,
  assignWorkerSchema,
  resolveIncidentSchema,
} from '../validators/incident.validator';

const router = Router();

// All incident routes require authentication
router.use(authenticate);

router.get('/', IncidentController.getIncidents);
router.get('/:id', IncidentController.getIncidentById);
router.get('/:id/history', IncidentController.getIncidentHistory);

// Create incident (Officers or internal system)
router.post('/', requireRole(Role.OFFICER), validate(createIncidentSchema), IncidentController.createIncident);

// Acknowledge incident (Officer only)
router.patch('/:id/acknowledge', requireRole(Role.OFFICER), IncidentController.acknowledgeIncident);

// Assign worker to incident (Officer only)
router.patch(
  '/:id/assign',
  requireRole(Role.OFFICER),
  validate(assignWorkerSchema),
  IncidentController.assignWorker
);

// Resolve incident (Assigned Worker only)
router.patch(
  '/:id/resolve',
  requireRole(Role.WORKER),
  validate(resolveIncidentSchema),
  IncidentController.resolveIncident
);

export default router;

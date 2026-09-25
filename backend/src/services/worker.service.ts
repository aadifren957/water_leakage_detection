import { IncidentStatus, Role } from '@prisma/client';
import { prisma } from '../config/db';
import { IncidentService } from './incident.service';

export class WorkerService {
  /**
   * Format DB worker user to Flutter WorkerModel format
   */
  static formatWorker(worker: any) {
    const activeTasks = worker._count?.assignedIncidents ?? 0;
    const maxCapacity = 3;
    const isAvailable = worker.isActive && activeTasks < maxCapacity;

    return {
      id: worker.workerId || `WRK-${worker.id.slice(0, 4)}`,
      userId: worker.id,
      name: worker.fullName,
      email: worker.email,
      phone: worker.phoneNumber || '+91 98765 00000',
      zone: worker.zone || 'Central City Zone',
      isAvailable,
      activeTaskCount: activeTasks,
      maxCapacity,
      skills: ['Pipeline Fitting', 'Joint Sealing', 'Pressure Testing', 'Valve Servicing'],
    };
  }

  /**
   * Get all active workers with calculated workloads (Officer only)
   */
  static async getWorkers() {
    const workers = await prisma.user.findMany({
      where: { role: Role.WORKER, isActive: true },
      include: {
        _count: {
          select: {
            assignedIncidents: {
              where: { status: IncidentStatus.ASSIGNED },
            },
          },
        },
      },
      orderBy: { fullName: 'asc' },
    });

    return workers.map(this.formatWorker);
  }

  /**
   * Get worker by ID
   */
  static async getWorkerById(workerIdentifier: string) {
    const worker = await prisma.user.findFirst({
      where: {
        role: Role.WORKER,
        OR: [{ id: workerIdentifier }, { workerId: workerIdentifier.toUpperCase() }],
      },
      include: {
        _count: {
          select: {
            assignedIncidents: {
              where: { status: IncidentStatus.ASSIGNED },
            },
          },
        },
      },
    });

    if (!worker) {
      throw { statusCode: 404, message: `Worker "${workerIdentifier}" not found.`, code: 'NOT_FOUND' };
    }

    return this.formatWorker(worker);
  }

  /**
   * Get tasks assigned to currently authenticated worker
   */
  static async getMyTasks(workerUserId: string) {
    const incidents = await prisma.incident.findMany({
      where: { assignedWorkerId: workerUserId },
      include: {
        assignedWorker: { select: { id: true, fullName: true, workerId: true, zone: true } },
        history: {
          orderBy: { createdAt: 'asc' },
          include: { actor: { select: { fullName: true, role: true } } },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    return incidents.map(IncidentService.formatIncident);
  }

  /**
   * Get summary task statistics for logged-in worker
   */
  static async getMySummary(workerUserId: string) {
    const [assigned, resolved] = await Promise.all([
      prisma.incident.count({
        where: { assignedWorkerId: workerUserId, status: IncidentStatus.ASSIGNED },
      }),
      prisma.incident.count({
        where: { assignedWorkerId: workerUserId, status: IncidentStatus.RESOLVED },
      }),
    ]);

    return {
      newAssignments: assigned,
      inProgress: assigned,
      completed: resolved,
    };
  }
}

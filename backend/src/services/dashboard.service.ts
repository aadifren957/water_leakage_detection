import { IncidentStatus, Role, Severity } from '@prisma/client';
import { prisma } from '../config/db';
import { IncidentService } from './incident.service';
import { SensorService } from './sensor.service';
import { NotificationService } from './notification.service';
import { WorkerService } from './worker.service';

export class DashboardService {
  /**
   * Aggregate statistics and recent items for Municipal Officer Dashboard
   */
  static async getOfficerDashboard(officerUserId: string) {
    const [
      totalCount,
      identifiedCount,
      acknowledgedCount,
      assignedCount,
      resolvedCount,
      criticalCount,
      activeWorkersCount,
      recentIncidents,
      notifications,
      sensors,
    ] = await Promise.all([
      prisma.incident.count(),
      prisma.incident.count({ where: { status: IncidentStatus.IDENTIFIED } }),
      prisma.incident.count({ where: { status: IncidentStatus.ACKNOWLEDGED } }),
      prisma.incident.count({ where: { status: IncidentStatus.ASSIGNED } }),
      prisma.incident.count({ where: { status: IncidentStatus.RESOLVED } }),
      prisma.incident.count({
        where: {
          severity: Severity.CRITICAL,
          status: { in: [IncidentStatus.IDENTIFIED, IncidentStatus.ACKNOWLEDGED, IncidentStatus.ASSIGNED] },
        },
      }),
      prisma.user.count({ where: { role: Role.WORKER, isActive: true } }),
      prisma.incident.findMany({
        take: 6,
        orderBy: { createdAt: 'desc' },
        include: {
          assignedWorker: { select: { id: true, fullName: true, workerId: true, zone: true } },
          history: {
            orderBy: { createdAt: 'asc' },
            include: { actor: { select: { fullName: true, role: true } } },
          },
        },
      }),
      NotificationService.getUserNotifications(officerUserId),
      SensorService.getAllSensors(),
    ]);

    return {
      stats: {
        totalActive: identifiedCount + acknowledgedCount + assignedCount,
        identifiedCount,
        acknowledgedCount,
        assignedCount,
        resolvedTodayCount: resolvedCount,
        criticalCount,
        totalIncidents: totalCount,
        activeWorkers: activeWorkersCount,
      },
      recentIncidents: recentIncidents.map(IncidentService.formatIncident),
      notifications: notifications.slice(0, 10),
      sensors,
    };
  }

  /**
   * Aggregate statistics and task spotlight for Field Worker Dashboard
   */
  static async getWorkerDashboard(workerUserId: string) {
    const [summary, myTasks, notifications, sensors] = await Promise.all([
      WorkerService.getMySummary(workerUserId),
      WorkerService.getMyTasks(workerUserId),
      NotificationService.getUserNotifications(workerUserId),
      SensorService.getAllSensors(),
    ]);

    const activeTasks = myTasks.filter((t) => t.status === 'assigned');
    const completedTasks = myTasks.filter((t) => t.status === 'resolved');

    return {
      stats: summary,
      spotlightTask: activeTasks.length > 0 ? activeTasks[0] : null,
      activeTasks,
      completedTasks,
      notifications: notifications.slice(0, 10),
      sensors,
    };
  }
}

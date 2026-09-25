import { IncidentStatus, NotificationType, Role, Severity } from '@prisma/client';
import { prisma } from '../config/db';
import { NotificationService } from './notification.service';
import { CreateIncidentInput, IncidentQueryInput } from '../validators/incident.validator';
import { JwtPayload } from '../types';

export class IncidentService {
  /**
   * Format DB incident to Flutter model format
   */
  static formatIncident(inc: any) {
    const timeline = (inc.history || []).map((h: any) => {
      let eventType = 'detected';
      if (h.action === 'ACKNOWLEDGED' || h.newStatus === IncidentStatus.ACKNOWLEDGED) {
        eventType = 'acknowledged';
      } else if (h.action === 'ASSIGNED' || h.newStatus === IncidentStatus.ASSIGNED) {
        eventType = 'assigned';
      } else if (h.action === 'RESOLVED' || h.newStatus === IncidentStatus.RESOLVED) {
        eventType = 'resolved';
      }

      return {
        id: h.id,
        title: h.note || (h.action === 'DETECTED' ? 'Leakage Detected' : h.action),
        description: h.metadata?.description || h.note || 'Status updated',
        timestamp: h.createdAt.toISOString(),
        actorName: h.actorName || (h.actor ? h.actor.fullName : undefined),
        actorRole: h.actorRole || (h.actor?.role === Role.OFFICER ? 'Municipal Officer' : h.actor?.role === Role.WORKER ? 'Field Worker' : undefined),
        type: eventType,
      };
    });

    return {
      id: inc.incidentCode || inc.id,
      deviceId: inc.deviceId || 'WLS-001',
      location: inc.location,
      zone: inc.zone,
      flowRate: inc.flowRate,
      totalVolume: inc.totalLiters,
      isLeakageDetected: inc.leakageDetected,
      isPumpOn: inc.pumpStatus,
      status: inc.status.toLowerCase(), // identified, acknowledged, assigned, resolved
      priority: inc.severity.toLowerCase(), // low, medium, high, critical
      detectedAt: inc.createdAt.toISOString(),
      acknowledgedAt: inc.acknowledgedAt ? inc.acknowledgedAt.toISOString() : null,
      acknowledgedBy: inc.acknowledgedBy || null,
      assignedWorkerId: inc.assignedWorker?.workerId || null,
      assignedWorkerUserId: inc.assignedWorkerId || null,
      assignedWorkerName: inc.assignedWorker ? inc.assignedWorker.fullName : null,
      assignedAt: inc.assignedAt ? inc.assignedAt.toISOString() : null,
      resolvedAt: inc.resolvedAt ? inc.resolvedAt.toISOString() : null,
      resolvedBy: inc.resolvedBy || null,
      repairNotes: inc.resolutionNote || null,
      timeline,
    };
  }

  /**
   * Get incidents with RBAC & filtering
   */
  static async getIncidents(user: JwtPayload, query: IncidentQueryInput) {
    const where: any = {};

    // Role-based visibility
    if (user.role === Role.WORKER) {
      where.assignedWorkerId = user.userId;
    }

    if (query.status) {
      where.status = query.status;
    }

    if (query.severity) {
      where.severity = query.severity;
    }

    if (query.zone) {
      where.zone = { contains: query.zone, mode: 'insensitive' };
    }

    if (query.search) {
      where.OR = [
        { incidentCode: { contains: query.search, mode: 'insensitive' } },
        { location: { contains: query.search, mode: 'insensitive' } },
        { zone: { contains: query.search, mode: 'insensitive' } },
        { deviceId: { contains: query.search, mode: 'insensitive' } },
      ];
    }

    const incidents = await prisma.incident.findMany({
      where,
      include: {
        assignedWorker: { select: { id: true, fullName: true, workerId: true, zone: true } },
        history: {
          orderBy: { createdAt: 'asc' },
          include: { actor: { select: { fullName: true, role: true } } },
        },
      },
      orderBy: { createdAt: 'desc' },
      skip: ((query.page || 1) - 1) * (query.limit || 50),
      take: query.limit || 50,
    });

    return incidents.map(this.formatIncident);
  }

  /**
   * Get incident by ID (UUID or incidentCode)
   */
  static async getIncidentById(id: string, user: JwtPayload) {
    const incident = await prisma.incident.findFirst({
      where: {
        OR: [{ id }, { incidentCode: id }],
      },
      include: {
        assignedWorker: { select: { id: true, fullName: true, workerId: true, zone: true } },
        history: {
          orderBy: { createdAt: 'asc' },
          include: { actor: { select: { fullName: true, role: true } } },
        },
      },
    });

    if (!incident) {
      throw { statusCode: 404, message: `Incident "${id}" not found.`, code: 'NOT_FOUND' };
    }

    // Role check: Worker can only view incidents assigned to them
    if (user.role === Role.WORKER && incident.assignedWorkerId !== user.userId) {
      throw { statusCode: 403, message: 'You are not authorized to view this incident.', code: 'FORBIDDEN' };
    }

    return this.formatIncident(incident);
  }

  /**
   * Create a new incident (System / IoT / Officer)
   */
  static async createIncident(input: CreateIncidentInput, creatorUser?: JwtPayload) {
    // Generate human-readable code e.g. INC-2026-001
    const count = await prisma.incident.count();
    const currentYear = new Date().getFullYear();
    const incidentCode = `INC-${currentYear}-${(count + 1).toString().padStart(3, '0')}`;

    const incident = await prisma.$transaction(async (tx) => {
      const inc = await tx.incident.create({
        data: {
          incidentCode,
          title: input.title,
          description: input.description,
          location: input.location,
          zone: input.zone,
          latitude: input.latitude,
          longitude: input.longitude,
          deviceId: input.deviceId || 'WLS-001',
          flowRate: input.flowRate,
          totalLiters: input.totalLiters,
          leakageDetected: input.leakageDetected,
          pumpStatus: input.pumpStatus,
          severity: input.severity,
          status: IncidentStatus.IDENTIFIED,
          createdById: creatorUser?.userId,
        },
      });

      // Add detection history entry
      await tx.incidentHistory.create({
        data: {
          incidentId: inc.id,
          actorId: creatorUser?.userId,
          actorName: creatorUser?.fullName || 'IoT Telemetry Engine',
          actorRole: creatorUser?.role === Role.OFFICER ? 'Municipal Officer' : 'IoT Sensor Node',
          action: 'DETECTED',
          newStatus: IncidentStatus.IDENTIFIED,
          note: 'Leakage Detected',
          metadata: {
            description: `Sensor anomaly detected at ${input.location} (${input.flowRate.toFixed(2)} L/min). Automatic safety shutoff active.`,
          },
        },
      });

      return inc;
    });

    // Notify Municipal Officers
    await NotificationService.notifyAllOfficers({
      title: `New Leakage Detected: ${incidentCode}`,
      message: `Flow anomaly ${input.flowRate.toFixed(2)} L/min detected at ${input.location}. Action required.`,
      type: NotificationType.LEAK_DETECTED,
      incidentId: incident.id,
    });

    return this.getIncidentById(incident.id, creatorUser || { userId: '', email: '', role: Role.OFFICER, fullName: 'System' });
  }

  /**
   * Acknowledge incident (Officer only)
   * Valid transition: IDENTIFIED -> ACKNOWLEDGED
   */
  static async acknowledgeIncident(id: string, user: JwtPayload) {
    if (user.role !== Role.OFFICER) {
      throw { statusCode: 403, message: 'Only Municipal Officers can acknowledge incidents.', code: 'FORBIDDEN' };
    }

    const incident = await prisma.incident.findFirst({
      where: { OR: [{ id }, { incidentCode: id }] },
    });

    if (!incident) {
      throw { statusCode: 404, message: `Incident "${id}" not found.`, code: 'NOT_FOUND' };
    }

    if (incident.status !== IncidentStatus.IDENTIFIED) {
      throw {
        statusCode: 409,
        message: `Cannot acknowledge incident in "${incident.status}" status. Only "IDENTIFIED" incidents can be acknowledged.`,
        code: 'INVALID_TRANSITION',
      };
    }

    const now = new Date();

    await prisma.$transaction(async (tx) => {
      await tx.incident.update({
        where: { id: incident.id },
        data: {
          status: IncidentStatus.ACKNOWLEDGED,
          acknowledgedAt: now,
          acknowledgedBy: user.fullName,
        },
      });

      await tx.incidentHistory.create({
        data: {
          incidentId: incident.id,
          actorId: user.userId,
          actorName: user.fullName,
          actorRole: 'Municipal Officer',
          action: 'ACKNOWLEDGED',
          previousStatus: IncidentStatus.IDENTIFIED,
          newStatus: IncidentStatus.ACKNOWLEDGED,
          note: 'Acknowledged by Municipal Officer',
          metadata: {
            description: `Officer ${user.fullName} reviewed sensor anomaly and confirmed field technician dispatch.`,
          },
        },
      });
    });

    // Notification for officer record
    await NotificationService.createNotification({
      recipientId: user.userId,
      recipientRole: Role.OFFICER,
      title: 'Incident Acknowledged',
      message: `You acknowledged ${incident.incidentCode} at ${incident.location}. Ready for worker assignment.`,
      type: NotificationType.ACKNOWLEDGED,
      incidentId: incident.id,
    });

    return this.getIncidentById(incident.id, user);
  }

  /**
   * Assign Field Worker (Officer only)
   * Valid transition: ACKNOWLEDGED -> ASSIGNED
   */
  static async assignWorker(incidentId: string, workerIdentifier: string, user: JwtPayload) {
    if (user.role !== Role.OFFICER) {
      throw { statusCode: 403, message: 'Only Municipal Officers can assign field workers.', code: 'FORBIDDEN' };
    }

    const incident = await prisma.incident.findFirst({
      where: { OR: [{ id: incidentId }, { incidentCode: incidentId }] },
    });

    if (!incident) {
      throw { statusCode: 404, message: `Incident "${incidentId}" not found.`, code: 'NOT_FOUND' };
    }

    if (incident.status !== IncidentStatus.ACKNOWLEDGED) {
      throw {
        statusCode: 409,
        message: `Cannot assign worker to an incident with status "${incident.status}". The incident must be "ACKNOWLEDGED" first.`,
        code: 'INVALID_TRANSITION',
      };
    }

    // Find worker by userId or workerId (e.g. WRK-001)
    const worker = await prisma.user.findFirst({
      where: {
        role: Role.WORKER,
        isActive: true,
        OR: [{ id: workerIdentifier }, { workerId: workerIdentifier.toUpperCase() }],
      },
      include: {
        _count: {
          select: { assignedIncidents: { where: { status: IncidentStatus.ASSIGNED } } },
        },
      },
    });

    if (!worker) {
      throw { statusCode: 404, message: `Active field worker "${workerIdentifier}" not found.`, code: 'WORKER_NOT_FOUND' };
    }

    // Workload check: max 3 active assignments
    const activeTasks = worker._count.assignedIncidents;
    if (activeTasks >= 3) {
      throw {
        statusCode: 409,
        message: `Worker ${worker.fullName} (${worker.workerId}) is currently at capacity (${activeTasks}/3 active tasks).`,
        code: 'WORKER_BUSY',
      };
    }

    const now = new Date();

    await prisma.$transaction(async (tx) => {
      await tx.incident.update({
        where: { id: incident.id },
        data: {
          status: IncidentStatus.ASSIGNED,
          assignedWorkerId: worker.id,
          assignedAt: now,
        },
      });

      await tx.incidentHistory.create({
        data: {
          incidentId: incident.id,
          actorId: user.userId,
          actorName: user.fullName,
          actorRole: 'Municipal Officer',
          action: 'ASSIGNED',
          previousStatus: IncidentStatus.ACKNOWLEDGED,
          newStatus: IncidentStatus.ASSIGNED,
          note: `Assigned to ${worker.fullName}`,
          metadata: {
            description: `Officer ${user.fullName} assigned technician ${worker.fullName} (${worker.workerId}) for on-site pipeline fault repair.`,
          },
        },
      });
    });

    // Targeted notification strictly to the assigned worker
    await NotificationService.createNotification({
      recipientId: worker.id,
      recipientRole: Role.WORKER,
      title: `New Task Assigned: ${incident.incidentCode}`,
      message: `Officer ${user.fullName} assigned you to ${incident.severity} priority leak at ${incident.location}.`,
      type: NotificationType.WORKER_ASSIGNED,
      incidentId: incident.id,
    });

    return this.getIncidentById(incident.id, user);
  }

  /**
   * Resolve incident (Assigned worker only)
   * Valid transition: ASSIGNED -> RESOLVED
   */
  static async resolveIncident(incidentId: string, repairNotes: string, user: JwtPayload) {
    if (user.role !== Role.WORKER) {
      throw { statusCode: 403, message: 'Only assigned field technicians can resolve tasks.', code: 'FORBIDDEN' };
    }

    const incident = await prisma.incident.findFirst({
      where: { OR: [{ id: incidentId }, { incidentCode: incidentId }] },
      include: { assignedWorker: true },
    });

    if (!incident) {
      throw { statusCode: 404, message: `Incident "${incidentId}" not found.`, code: 'NOT_FOUND' };
    }

    if (incident.status !== IncidentStatus.ASSIGNED) {
      throw {
        statusCode: 409,
        message: `Cannot resolve incident in "${incident.status}" status. The incident must be in "ASSIGNED" status.`,
        code: 'INVALID_TRANSITION',
      };
    }

    // Security check: Only the assigned worker can resolve
    if (incident.assignedWorkerId !== user.userId) {
      throw {
        statusCode: 403,
        message: `Unauthorized: This task is assigned to "${incident.assignedWorker?.fullName}". You cannot resolve tasks assigned to other technicians.`,
        code: 'UNAUTHORIZED_WORKER',
      };
    }

    const now = new Date();
    const notes = repairNotes.trim();

    await prisma.$transaction(async (tx) => {
      await tx.incident.update({
        where: { id: incident.id },
        data: {
          status: IncidentStatus.RESOLVED,
          resolvedAt: now,
          resolvedBy: user.fullName,
          resolutionNote: notes,
          leakageDetected: false,
          pumpStatus: true, // Pump back online after repair
        },
      });

      await tx.incidentHistory.create({
        data: {
          incidentId: incident.id,
          actorId: user.userId,
          actorName: user.fullName,
          actorRole: 'Field Worker',
          action: 'RESOLVED',
          previousStatus: IncidentStatus.ASSIGNED,
          newStatus: IncidentStatus.RESOLVED,
          note: `Marked Resolved by ${user.fullName}`,
          metadata: {
            description: `Technician ${user.fullName} filed repair notes: "${notes}"`,
          },
        },
      });
    });

    // Notify Municipal Officers about completion
    await NotificationService.notifyAllOfficers({
      title: `Incident Resolved: ${incident.incidentCode}`,
      message: `${user.fullName} completed repairs at ${incident.location}. Notes: ${notes}`,
      type: NotificationType.TASK_RESOLVED,
      incidentId: incident.id,
    });

    return this.getIncidentById(incident.id, user);
  }

  /**
   * Get incident chronological history
   */
  static async getIncidentHistory(incidentId: string, user: JwtPayload) {
    const incident = await this.getIncidentById(incidentId, user);
    return incident.timeline;
  }
}

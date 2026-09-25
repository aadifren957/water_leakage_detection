import { NotificationType, Role } from '@prisma/client';
import { prisma } from '../config/db';

export class NotificationService {
  /**
   * Dispatch a notification to a specific user with deduplication
   */
  static async createNotification(params: {
    recipientId: string;
    recipientRole: Role;
    title: string;
    message: string;
    type: NotificationType;
    incidentId?: string;
  }) {
    // Deduplication check: Avoid inserting identical notification for same incident within 15 seconds
    if (params.incidentId) {
      const recent = await prisma.notification.findFirst({
        where: {
          recipientId: params.recipientId,
          incidentId: params.incidentId,
          type: params.type,
          createdAt: {
            gte: new Date(Date.now() - 15 * 1000),
          },
        },
      });

      if (recent) {
        return recent;
      }
    }

    return prisma.notification.create({
      data: {
        recipientId: params.recipientId,
        recipientRole: params.recipientRole,
        title: params.title,
        message: params.message,
        type: params.type,
        incidentId: params.incidentId,
        isRead: false,
      },
    });
  }

  /**
   * Notify all active Municipal Officers
   */
  static async notifyAllOfficers(params: {
    title: string;
    message: string;
    type: NotificationType;
    incidentId?: string;
  }) {
    const officers = await prisma.user.findMany({
      where: { role: Role.OFFICER, isActive: true },
      select: { id: true },
    });

    for (const officer of officers) {
      await this.createNotification({
        recipientId: officer.id,
        recipientRole: Role.OFFICER,
        title: params.title,
        message: params.message,
        type: params.type,
        incidentId: params.incidentId,
      });
    }
  }

  /**
   * Get notifications for a specific user
   */
  static async getUserNotifications(userId: string) {
    const notifs = await prisma.notification.findMany({
      where: { recipientId: userId },
      orderBy: { createdAt: 'desc' },
      take: 100,
    });

    return notifs.map(this.formatNotification);
  }

  /**
   * Get unread notification count
   */
  static async getUnreadCount(userId: string) {
    return prisma.notification.count({
      where: { recipientId: userId, isRead: false },
    });
  }

  /**
   * Mark a notification as read (ensuring ownership)
   */
  static async markAsRead(notificationId: string, userId: string) {
    const notif = await prisma.notification.findUnique({
      where: { id: notificationId },
    });

    if (!notif) {
      throw { statusCode: 404, message: 'Notification not found.', code: 'NOT_FOUND' };
    }

    if (notif.recipientId !== userId) {
      throw { statusCode: 403, message: 'Unauthorized to modify this notification.', code: 'FORBIDDEN' };
    }

    const updated = await prisma.notification.update({
      where: { id: notificationId },
      data: { isRead: true, readAt: new Date() },
    });

    return this.formatNotification(updated);
  }

  /**
   * Mark all notifications as read for a user
   */
  static async markAllAsRead(userId: string) {
    await prisma.notification.updateMany({
      where: { recipientId: userId, isRead: false },
      data: { isRead: true, readAt: new Date() },
    });

    return { success: true, message: 'All notifications marked as read' };
  }

  private static formatNotification(n: any) {
    let typeName = 'system';
    switch (n.type) {
      case NotificationType.LEAK_DETECTED:
        typeName = 'leakDetected';
        break;
      case NotificationType.ACKNOWLEDGED:
        typeName = 'acknowledged';
        break;
      case NotificationType.WORKER_ASSIGNED:
        typeName = 'workerAssigned';
        break;
      case NotificationType.TASK_RESOLVED:
        typeName = 'taskResolved';
        break;
      default:
        typeName = 'system';
    }

    return {
      id: n.id,
      recipientId: n.recipientId,
      recipientRole: n.recipientRole === Role.OFFICER ? 'municipalOfficer' : 'fieldWorker',
      title: n.title,
      message: n.message,
      incidentId: n.incidentId || undefined,
      timestamp: n.createdAt.toISOString(),
      isRead: n.isRead,
      type: typeName,
    };
  }
}

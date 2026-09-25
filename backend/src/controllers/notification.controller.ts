import { Response } from 'express';
import { AuthenticatedRequest } from '../types';
import { NotificationService } from '../services/notification.service';
import { sendSuccess, sendError } from '../utils/response';

export class NotificationController {
  static async getUserNotifications(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const notifications = await NotificationService.getUserNotifications(req.user!.userId);
      sendSuccess(res, 'Notifications retrieved', notifications);
    } catch (error: any) {
      sendError(res, error.message || 'Failed to fetch notifications', error.statusCode || 500, error.code);
    }
  }

  static async getUnreadCount(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const count = await NotificationService.getUnreadCount(req.user!.userId);
      sendSuccess(res, 'Unread notification count retrieved', { unreadCount: count });
    } catch (error: any) {
      sendError(res, error.message || 'Failed to fetch unread count', error.statusCode || 500, error.code);
    }
  }

  static async markAsRead(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const id = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
      const updated = await NotificationService.markAsRead(id, req.user!.userId);
      sendSuccess(res, 'Notification marked as read', updated);
    } catch (error: any) {
      sendError(res, error.message || 'Failed to mark notification as read', error.statusCode || 400, error.code);
    }
  }

  static async markAllAsRead(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const result = await NotificationService.markAllAsRead(req.user!.userId);
      sendSuccess(res, 'All notifications marked as read', result);
    } catch (error: any) {
      sendError(res, error.message || 'Failed to mark notifications as read', error.statusCode || 500, error.code);
    }
  }
}

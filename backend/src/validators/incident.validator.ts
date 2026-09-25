import { z } from 'zod';
import { Severity, IncidentStatus } from '@prisma/client';

export const createIncidentSchema = z.object({
  title: z.string().min(3, 'Title is required').trim(),
  description: z.string().min(5, 'Description is required').trim(),
  location: z.string().min(3, 'Location is required').trim(),
  zone: z.string().min(2, 'Zone is required').trim(),
  latitude: z.number().optional(),
  longitude: z.number().optional(),
  deviceId: z.string().optional(),
  flowRate: z.number().nonnegative().default(0.0),
  totalLiters: z.number().nonnegative().default(0.0),
  leakageDetected: z.boolean().default(true),
  pumpStatus: z.boolean().default(false),
  severity: z.nativeEnum(Severity).default(Severity.MEDIUM),
});

export const assignWorkerSchema = z.object({
  workerId: z.string().min(1, 'workerId (user UUID or WRK code) is required'),
});

export const resolveIncidentSchema = z.object({
  repairNotes: z.string().min(3, 'Please provide repair notes describing the resolution').trim(),
});

export const incidentQuerySchema = z.object({
  status: z.nativeEnum(IncidentStatus).optional(),
  severity: z.nativeEnum(Severity).optional(),
  zone: z.string().optional(),
  search: z.string().optional(),
  page: z.string().regex(/^\d+$/).transform(Number).optional().default('1'),
  limit: z.string().regex(/^\d+$/).transform(Number).optional().default('50'),
});

export type CreateIncidentInput = z.infer<typeof createIncidentSchema>;
export type AssignWorkerInput = z.infer<typeof assignWorkerSchema>;
export type ResolveIncidentInput = z.infer<typeof resolveIncidentSchema>;
export type IncidentQueryInput = z.infer<typeof incidentQuerySchema>;

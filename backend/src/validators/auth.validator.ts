import { z } from 'zod';

export const loginSchema = z.object({
  email: z.string().email('Please provide a valid email address').trim().toLowerCase(),
  password: z.string().min(6, 'Password must be at least 6 characters long'),
});

export const registerWorkerSchema = z.object({
  fullName: z.string().min(2, 'Full name must be at least 2 characters').trim(),
  email: z.string().email('Please provide a valid email address').trim().toLowerCase(),
  password: z.string().min(6, 'Password must be at least 6 characters long'),
  phoneNumber: z.string().optional(),
  department: z.string().optional().default('Field Engineering & Maintenance'),
  workerId: z.string().min(2, 'Worker ID is required (e.g. WRK-001)').trim().toUpperCase(),
  zone: z.string().optional().default('North & Central Distribution Grid'),
});

export type LoginInput = z.infer<typeof loginSchema>;
export type RegisterWorkerInput = z.infer<typeof registerWorkerSchema>;

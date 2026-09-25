import { z } from 'zod';

export const updateWorkerProfileSchema = z.object({
  fullName: z.string().min(2).optional(),
  phoneNumber: z.string().optional(),
  zone: z.string().optional(),
  isActive: z.boolean().optional(),
});

export type UpdateWorkerProfileInput = z.infer<typeof updateWorkerProfileSchema>;

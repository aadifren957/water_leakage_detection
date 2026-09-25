import { z } from 'zod';

export const iotReadingSchema = z.preprocess((val: any) => {
  if (typeof val === 'object' && val !== null) {
    return {
      deviceId: val.deviceId || 'WLS-ESP-001',
      deviceName: val.deviceName || 'Main Pipeline Flow Node',
      location: val.location || 'Sector 4, Main Pipeline Junction',
      flowRate: val.flowRate ?? 0.0,
      totalLiters: val.totalLiters ?? val.totalVolume ?? val.totalWater ?? 0.0,
      normalBaselineFlowRate: val.normalBaselineFlowRate ?? 3.5,
      leakageDetected: val.leakageDetected ?? val.isLeakageDetected ?? false,
      pumpStatus: val.pumpStatus ?? val.pumpRunning ?? val.isPumpOn ?? true,
      isOnline: val.isOnline ?? true,
      idempotencyKey: val.idempotencyKey,
    };
  }
  return val;
}, z.object({
  deviceId: z.string().min(2, 'deviceId is required').trim(),
  deviceName: z.string().default('Main Pipeline Flow Node'),
  location: z.string().default('Sector 4, Main Pipeline Junction'),
  flowRate: z.number().nonnegative(),
  totalLiters: z.number().nonnegative().default(0),
  normalBaselineFlowRate: z.number().nonnegative().default(3.5),
  leakageDetected: z.boolean().default(false),
  pumpStatus: z.boolean().default(true),
  isOnline: z.boolean().default(true),
  idempotencyKey: z.string().optional(),
}));

export type IotReadingInput = z.infer<typeof iotReadingSchema>;


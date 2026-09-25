import { Request, Response, NextFunction } from 'express';
import { AnyZodObject, ZodSchema, ZodError } from 'zod';
import { sendError } from '../utils/response';

export function validate(schema: ZodSchema | AnyZodObject) {
  return async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      req.body = await schema.parseAsync(req.body);
      next();
    } catch (error) {
      if (error instanceof ZodError) {
        const errors = error.errors.map((err) => ({
          field: err.path.join('.'),
          message: err.message,
        }));
        sendError(res, 'Validation error: please check your input fields.', 422, 'VALIDATION_ERROR', errors);
        return;
      }
      sendError(res, 'Invalid request data.', 400, 'BAD_REQUEST');
    }
  };
}

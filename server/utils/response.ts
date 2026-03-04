import type { Response } from "express";

export function sendSuccess(res: Response, data: any, statusCode = 200) {
  return res.status(statusCode).json(data);
}

export function sendCreated(res: Response, data: any) {
  return sendSuccess(res, data, 201);
}

export function sendOk(res: Response) {
  return res.json({ success: true });
}

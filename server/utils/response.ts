import type { Response } from "express";

export function sendSuccess(res: Response, data: any, statusCode = 200) {
  return res.status(statusCode).json({ success: true, data });
}

export function sendCreated(res: Response, data: any) {
  return sendSuccess(res, data, 201);
}

export function sendOk(res: Response) {
  return res.json({ success: true });
}

export function sendError(res: Response, message: string, statusCode = 400, code = "BAD_REQUEST") {
  return res.status(statusCode).json({ success: false, message, code });
}

import type { Request, Response, NextFunction } from "express";
import { AppError } from "../utils/AppError";

export function errorHandler(err: any, _req: Request, res: Response, _next: NextFunction) {
  if (res.headersSent) return;

  if (err instanceof AppError) {
    return res.status(err.statusCode).json({
      success: false,
      message: err.message,
      code: err.code,
    });
  }

  if (err.name === "MulterError") {
    return res.status(400).json({
      success: false,
      message: err.message,
      code: "UPLOAD_ERROR",
    });
  }

  if (err.message && (err.message.includes("Only") || err.message.includes("not supported") || err.message.includes("not allowed"))) {
    return res.status(400).json({
      success: false,
      message: err.message,
      code: "VALIDATION_ERROR",
    });
  }

  console.error("Unhandled error:", err);
  res.status(500).json({
    success: false,
    message: "Internal server error",
    code: "INTERNAL_ERROR",
  });
}

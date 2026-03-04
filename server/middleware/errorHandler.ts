import type { Request, Response, NextFunction } from "express";
import { AppError } from "../utils/AppError";

export function errorHandler(err: any, _req: Request, res: Response, _next: NextFunction) {
  if (res.headersSent) return;

  if (err instanceof AppError) {
    return res.status(err.statusCode).json({ message: err.message });
  }

  if (err.name === "MulterError") {
    return res.status(400).json({ message: err.message });
  }

  if (err.message && (err.message.includes("Only") || err.message.includes("not supported") || err.message.includes("not allowed"))) {
    return res.status(400).json({ message: err.message });
  }

  console.error("Unhandled error:", err);
  res.status(500).json({ message: "Internal server error" });
}

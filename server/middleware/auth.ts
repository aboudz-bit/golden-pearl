import type { Request, Response, NextFunction } from "express";
import { storage } from "../storage";

declare module "express-session" {
  interface SessionData {
    userId?: number;
  }
}

export async function isAdmin(req: Request, res: Response, next: NextFunction) {
  const userId = req.session?.userId;
  if (!userId) return res.status(401).json({ success: false, message: "Authentication required", code: "UNAUTHORIZED" });
  const user = await storage.getUserById(userId);
  if (!user || user.role !== "admin") return res.status(403).json({ success: false, message: "Admin access required", code: "FORBIDDEN" });
  next();
}

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
  if (!user.isActive) return res.status(403).json({ success: false, message: "Account disabled", code: "ACCOUNT_DISABLED" });
  (req as any).currentUser = user;
  next();
}

export async function isStaffOrAdmin(req: Request, res: Response, next: NextFunction) {
  const userId = req.session?.userId;
  if (!userId) return res.status(401).json({ success: false, message: "Authentication required", code: "UNAUTHORIZED" });
  const user = await storage.getUserById(userId);
  if (!user) return res.status(401).json({ success: false, message: "Authentication required", code: "UNAUTHORIZED" });
  if (!user.isActive) return res.status(403).json({ success: false, message: "Account disabled", code: "ACCOUNT_DISABLED" });
  if (user.role !== "admin" && user.role !== "staff") {
    return res.status(403).json({ success: false, message: "Admin or staff access required", code: "FORBIDDEN" });
  }
  (req as any).currentUser = user;
  next();
}

export function requirePermission(...permissions: string[]) {
  return async (req: Request, res: Response, next: NextFunction) => {
    const userId = req.session?.userId;
    if (!userId) return res.status(401).json({ success: false, message: "Authentication required", code: "UNAUTHORIZED" });

    const user = (req as any).currentUser || await storage.getUserById(userId);
    if (!user) return res.status(401).json({ success: false, message: "Authentication required", code: "UNAUTHORIZED" });
    if (!user.isActive) return res.status(403).json({ success: false, message: "Account disabled", code: "ACCOUNT_DISABLED" });

    if (user.role === "admin") {
      (req as any).currentUser = user;
      return next();
    }

    if (user.role !== "staff") {
      return res.status(403).json({ success: false, message: "Access denied", code: "FORBIDDEN" });
    }

    const userPerms = (user.permissions as Record<string, Record<string, boolean>>) || {};

    for (const perm of permissions) {
      const [module, action] = perm.split(".");
      if (!userPerms[module]?.[action]) {
        return res.status(403).json({ success: false, message: `Permission denied: ${perm}`, code: "PERMISSION_DENIED" });
      }
    }

    (req as any).currentUser = user;
    next();
  };
}

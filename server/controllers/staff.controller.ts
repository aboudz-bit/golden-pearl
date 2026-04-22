import type { Request, Response } from "express";
import bcrypt from "bcrypt";
import { storage } from "../storage";
import { AppError } from "../utils/AppError";

const DEFAULT_PERMISSIONS = {
  dashboard: { view: false },
  orders: { view: false, updateStatus: false },
  products: { view: false, create: false, edit: false, delete: false },
  categories: { view: false, edit: false },
  banners: { view: false, edit: false },
  customers: { view: false, export: false },
  notifications: { view: false, send: false, delete: false },
  discountCodes: { view: false, create: false, edit: false, delete: false },
};

export async function listStaff(_req: Request, res: Response) {
  const staffUsers = await storage.getStaffUsers();
  const safe = staffUsers.map(({ passwordHash, ...u }) => u);
  res.json(safe);
}

export async function createStaff(req: Request, res: Response) {
  const { email, password, name, phone, permissions, isActive } = req.body;

  if (!email || !password || !name) {
    throw AppError.badRequest("Email, password, and name are required");
  }

  if (password.length < 6) {
    throw AppError.badRequest("Password must be at least 6 characters");
  }

  const existing = await storage.getUserByEmail(email.toLowerCase());
  if (existing) throw AppError.conflict("Email already registered");

  const passwordHash = await bcrypt.hash(password, 10);
  const mergedPermissions = { ...DEFAULT_PERMISSIONS, ...(permissions || {}) };

  const user = await storage.createUser({
    email: email.toLowerCase(),
    passwordHash,
    name,
    phone: phone || null,
    role: "staff",
    isActive: isActive !== false,
    permissions: mergedPermissions,
  });

  const { passwordHash: _, ...safeUser } = user;
  res.status(201).json(safeUser);
}

export async function updateStaff(req: Request, res: Response) {
  const id = parseInt(req.params.id);
  if (isNaN(id)) throw AppError.badRequest("Invalid staff ID");

  const user = await storage.getUserById(id);
  if (!user || user.role !== "staff") throw AppError.notFound("Staff user not found");

  const { name, email, phone, isActive } = req.body;
  const updates: Record<string, any> = {};

  if (name !== undefined) updates.name = name;
  if (phone !== undefined) updates.phone = phone;
  if (isActive !== undefined) updates.isActive = isActive;

  if (email !== undefined && email.toLowerCase() !== user.email) {
    const existing = await storage.getUserByEmail(email.toLowerCase());
    if (existing) throw AppError.conflict("Email already registered");
    updates.email = email.toLowerCase();
  }

  if (req.body.password) {
    if (req.body.password.length < 6) throw AppError.badRequest("Password must be at least 6 characters");
    updates.passwordHash = await bcrypt.hash(req.body.password, 10);
  }

  const updated = await storage.updateUser(id, updates);
  if (!updated) throw AppError.notFound("Staff user not found");

  const { passwordHash: _, ...safeUser } = updated;
  res.json(safeUser);
}

export async function updateStaffPermissions(req: Request, res: Response) {
  const id = parseInt(req.params.id);
  if (isNaN(id)) throw AppError.badRequest("Invalid staff ID");

  const user = await storage.getUserById(id);
  if (!user || user.role !== "staff") throw AppError.notFound("Staff user not found");

  const { permissions } = req.body;
  if (!permissions || typeof permissions !== "object") {
    throw AppError.badRequest("Permissions object is required");
  }

  const updated = await storage.updateUser(id, { permissions });
  if (!updated) throw AppError.notFound("Staff user not found");

  const { passwordHash: _, ...safeUser } = updated;
  res.json(safeUser);
}

export async function deleteStaff(req: Request, res: Response) {
  const id = parseInt(req.params.id);
  if (isNaN(id)) throw AppError.badRequest("Invalid staff ID");

  const user = await storage.getUserById(id);
  if (!user || user.role !== "staff") throw AppError.notFound("Staff user not found");

  await storage.updateUser(id, { isActive: false });
  res.json({ success: true, message: "Staff user disabled" });
}

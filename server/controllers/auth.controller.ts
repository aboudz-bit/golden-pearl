import type { Request, Response } from "express";
import bcrypt from "bcrypt";
import { z } from "zod";
import { storage } from "../storage";
import { AppError } from "../utils/AppError";
import { sendSuccess, sendOk } from "../utils/response";

const registerSchema = z.object({
  email: z.string().email().max(255),
  password: z.string().min(6).max(128),
  name: z.string().min(1).max(100),
  phone: z.string().max(20).optional(),
});

const loginSchema = z.object({
  email: z.string().email().max(255),
  password: z.string().min(1).max(128),
});

function safeUser(user: any) {
  const { passwordHash, ...safe } = user;
  return safe;
}

export async function register(req: Request, res: Response) {
  const parsed = registerSchema.safeParse(req.body);
  if (!parsed.success) {
    throw AppError.badRequest(parsed.error.issues.map(i => i.message).join(", "));
  }
  const { email, password, name, phone } = parsed.data;

  const existing = await storage.getUserByEmail(email.toLowerCase());
  if (existing) throw AppError.conflict("Email already registered");

  const passwordHash = await bcrypt.hash(password, 10);
  const user = await storage.createUser({ email: email.toLowerCase(), passwordHash, name, phone });
  req.session!.userId = user.id;

  sendSuccess(res, { user: safeUser(user) }, 201);
}

export async function login(req: Request, res: Response) {
  const parsed = loginSchema.safeParse(req.body);
  if (!parsed.success) {
    throw AppError.badRequest("Email and password are required");
  }
  const { email, password } = parsed.data;

  const user = await storage.getUserByEmail(email.toLowerCase());
  if (!user) throw AppError.unauthorized("Invalid email or password");

  if (!user.isActive) {
    throw AppError.forbidden("Account disabled. Please contact the administrator.");
  }

  const valid = await bcrypt.compare(password, user.passwordHash);
  if (!valid) throw AppError.unauthorized("Invalid email or password");

  req.session!.userId = user.id;
  sendSuccess(res, { user: safeUser(user) });
}

export async function logout(req: Request, res: Response) {
  delete req.session!.userId;
  sendOk(res);
}

export async function me(req: Request, res: Response) {
  const userId = req.session?.userId;
  if (!userId) return sendSuccess(res, { user: null });
  const user = await storage.getUserById(userId);
  if (!user) return sendSuccess(res, { user: null });
  if (!user.isActive) return sendSuccess(res, { user: null });
  sendSuccess(res, { user: safeUser(user) });
}

export async function mergeCart(req: Request, res: Response) {
  const userId = req.session?.userId;
  if (!userId) throw AppError.unauthorized("Must be logged in to merge");
  const sessionId = req.session!.id;
  await storage.migrateCartToUser(sessionId, userId);
  const items = await storage.getCartItemsByUserId(userId);
  sendSuccess(res, { cartItems: items });
}

export async function deleteAccount(req: Request, res: Response) {
  const userId = req.session?.userId;
  if (!userId) throw AppError.unauthorized("Must be logged in to delete account");

  const user = await storage.getUserById(userId);
  if (!user) throw AppError.notFound("User not found");

  if (user.role === "admin") {
    throw AppError.forbidden("Admin accounts cannot be self-deleted");
  }

  await storage.deleteUserAndData(userId);
  delete req.session!.userId;
  sendOk(res);
}

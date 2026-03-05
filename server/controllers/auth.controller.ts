import type { Request, Response } from "express";
import bcrypt from "bcrypt";
import { storage } from "../storage";
import { AppError } from "../utils/AppError";

function safeUser(user: any) {
  const { passwordHash, ...safe } = user;
  return safe;
}

export async function register(req: Request, res: Response) {
  const { email, password, name, phone } = req.body;
  if (!email || !password || !name) {
    throw AppError.badRequest("Email, password, and name are required");
  }
  const existing = await storage.getUserByEmail(email);
  if (existing) throw AppError.conflict("Email already registered");

  const passwordHash = await bcrypt.hash(password, 10);
  const user = await storage.createUser({ email: email.toLowerCase(), passwordHash, name, phone });
  req.session!.userId = user.id;

  res.json({ user: safeUser(user) });
}

export async function login(req: Request, res: Response) {
  const { email, password } = req.body;
  if (!email || !password) throw AppError.badRequest("Email and password are required");

  const user = await storage.getUserByEmail(email);
  if (!user) throw AppError.unauthorized("Invalid email or password");

  if (!user.isActive) {
    throw AppError.forbidden("Account disabled. Please contact the administrator.");
  }

  const valid = await bcrypt.compare(password, user.passwordHash);
  if (!valid) throw AppError.unauthorized("Invalid email or password");

  req.session!.userId = user.id;
  res.json({ user: safeUser(user) });
}

export async function logout(req: Request, res: Response) {
  delete req.session!.userId;
  res.json({ success: true });
}

export async function me(req: Request, res: Response) {
  const userId = req.session?.userId;
  if (!userId) return res.json({ user: null });
  const user = await storage.getUserById(userId);
  if (!user) return res.json({ user: null });
  if (!user.isActive) return res.json({ user: null });
  res.json({ user: safeUser(user) });
}

export async function mergeCart(req: Request, res: Response) {
  const userId = req.session?.userId;
  if (!userId) throw AppError.unauthorized("Must be logged in to merge");
  const sessionId = req.session!.id;
  await storage.migrateCartToUser(sessionId, userId);
  const items = await storage.getCartItemsByUserId(userId);
  res.json({ success: true, cartItems: items });
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
  res.json({ success: true });
}

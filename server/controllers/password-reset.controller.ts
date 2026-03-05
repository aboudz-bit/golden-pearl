import type { Request, Response } from "express";
import { createHash, randomBytes } from "crypto";
import bcrypt from "bcrypt";
import { z } from "zod";
import { storage } from "../storage";
import { AppError } from "../utils/AppError";

const OTP_EXPIRY_MINUTES = 10;
const TOKEN_EXPIRY_MINUTES = 15;
const MAX_OTP_ATTEMPTS = 5;
const RATE_LIMIT_WINDOW_MINUTES = 15;
const RATE_LIMIT_MAX_REQUESTS = 3;

function generateOtp(): string {
  const num = Math.floor(100000 + Math.random() * 900000);
  return String(num);
}

function hashOtp(otp: string): string {
  return createHash("sha256").update(otp).digest("hex");
}

function normalizePhone(phone: string): string {
  let p = phone.replace(/[\s\-\(\)]/g, "");
  if (p.startsWith("00966")) p = "+" + p.slice(2);
  if (p.startsWith("0")) p = "+966" + p.slice(1);
  if (p.startsWith("966") && !p.startsWith("+")) p = "+" + p;
  if (!p.startsWith("+")) p = "+966" + p;
  return p;
}

const requestSchema = z.object({
  channel: z.enum(["email", "phone"]),
  email: z.string().email().optional(),
  phone: z.string().min(6).optional(),
});

const verifySchema = z.object({
  channel: z.enum(["email", "phone"]),
  email: z.string().email().optional(),
  phone: z.string().min(6).optional(),
  otp: z.string().length(6),
});

const confirmSchema = z.object({
  resetToken: z.string().min(10),
  newPassword: z.string().min(6),
});

export async function requestOtp(req: Request, res: Response) {
  const parsed = requestSchema.safeParse(req.body);
  if (!parsed.success) throw AppError.badRequest("Invalid request data");

  const { channel, email, phone } = parsed.data;
  const target = channel === "email" ? email?.toLowerCase() : phone ? normalizePhone(phone) : undefined;
  if (!target) throw AppError.badRequest(`${channel} is required`);

  const recentCount = await storage.countRecentOtps(target, RATE_LIMIT_WINDOW_MINUTES);
  if (recentCount >= RATE_LIMIT_MAX_REQUESTS) {
    return res.json({ success: true, message: "If an account exists, a code has been sent" });
  }

  let user;
  if (channel === "email") {
    user = await storage.getUserByEmail(target);
  } else {
    user = await storage.getUserByPhone(target);
    if (!user) {
      user = await storage.getUserByPhone(phone!);
    }
  }

  if (!user) {
    return res.json({ success: true, message: "If an account exists, a code has been sent" });
  }

  if (!user.isActive) {
    return res.json({ success: true, message: "If an account exists, a code has been sent" });
  }

  const otp = generateOtp();
  const otpHashed = hashOtp(otp);
  const expiresAt = new Date(Date.now() + OTP_EXPIRY_MINUTES * 60 * 1000);

  await storage.createOtp({
    userId: user.id,
    channel,
    target,
    otpHash: otpHashed,
    expiresAt,
  });

  if (channel === "email") {
    console.log(`[password-reset] OTP for ${target}: ${otp} (email delivery pending — configure email provider)`);
  } else {
    console.log(`[password-reset] OTP for ${target}: ${otp} (SMS delivery pending — configure SMS provider)`);
  }

  console.log(`[audit] Password reset requested: userId=${user.id}, channel=${channel}, target=${target}`);

  res.json({ success: true, message: "If an account exists, a code has been sent" });
}

export async function verifyOtp(req: Request, res: Response) {
  const parsed = verifySchema.safeParse(req.body);
  if (!parsed.success) throw AppError.badRequest("Invalid request data");

  const { channel, email, phone, otp } = parsed.data;
  const target = channel === "email" ? email?.toLowerCase() : phone ? normalizePhone(phone) : undefined;
  if (!target) throw AppError.badRequest(`${channel} is required`);

  let user;
  if (channel === "email") {
    user = await storage.getUserByEmail(target);
  } else {
    user = await storage.getUserByPhone(target);
    if (!user) user = await storage.getUserByPhone(phone!);
  }

  if (!user) throw AppError.badRequest("Invalid or expired code");

  const activeOtp = await storage.getActiveOtp(user.id, channel);
  if (!activeOtp) throw AppError.badRequest("Invalid or expired code");

  if (activeOtp.attempts >= MAX_OTP_ATTEMPTS) {
    await storage.deleteOtpsForUser(user.id);
    throw AppError.badRequest("Too many attempts. Please request a new code");
  }

  const otpHashed = hashOtp(otp);
  if (otpHashed !== activeOtp.otpHash) {
    await storage.incrementOtpAttempts(activeOtp.id);
    throw AppError.badRequest("Invalid or expired code");
  }

  const rawToken = randomBytes(32).toString("hex");
  const tokenHash = createHash("sha256").update(rawToken).digest("hex");
  const tokenExpiry = new Date(Date.now() + TOKEN_EXPIRY_MINUTES * 60 * 1000);

  await storage.createResetToken({
    userId: user.id,
    tokenHash,
    expiresAt: tokenExpiry,
  });

  await storage.deleteOtpsForUser(user.id);

  console.log(`[audit] Password reset OTP verified: userId=${user.id}, channel=${channel}`);

  res.json({
    success: true,
    resetToken: rawToken,
    expiresIn: TOKEN_EXPIRY_MINUTES * 60,
  });
}

export async function confirmReset(req: Request, res: Response) {
  const parsed = confirmSchema.safeParse(req.body);
  if (!parsed.success) throw AppError.badRequest("Invalid request data");

  const { resetToken, newPassword } = parsed.data;
  const tokenHash = createHash("sha256").update(resetToken).digest("hex");

  const token = await storage.getResetTokenByHash(tokenHash);
  if (!token) throw AppError.badRequest("Invalid or expired reset token");

  const passwordHash = await bcrypt.hash(newPassword, 10);
  await storage.updateUser(token.userId, { passwordHash });

  await storage.markResetTokenUsed(token.id);
  await storage.deleteResetTokensForUser(token.userId);
  await storage.deleteOtpsForUser(token.userId);

  console.log(`[audit] Password reset completed: userId=${token.userId}`);

  res.json({ success: true, message: "Password has been reset successfully" });
}

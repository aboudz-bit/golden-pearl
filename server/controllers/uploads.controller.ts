import type { Request, Response } from "express";
import multer from "multer";
import sharp from "sharp";
import path from "path";
import fs from "fs";
import { randomUUID } from "crypto";
import { AppError } from "../utils/AppError";

const uploadsDir = path.resolve(process.cwd(), "uploads");
if (!fs.existsSync(uploadsDir)) fs.mkdirSync(uploadsDir, { recursive: true });

const IMAGE_MIMES = new Set(["image/jpeg", "image/jpg", "image/png", "image/webp"]);
const VIDEO_MIMES = new Set(["video/mp4"]);
const IMAGE_EXTS = new Set([".jpg", ".jpeg", ".png", ".webp"]);
const VIDEO_EXTS = new Set([".mp4"]);
const HEIC_MIMES = new Set(["image/heic", "image/heif"]);
const HEIC_EXTS = new Set([".heic", ".heif"]);

function classifyFile(mime: string, ext: string): "image" | "video" | "heic" | null {
  if (HEIC_MIMES.has(mime) || HEIC_EXTS.has(ext)) return "heic";
  if (IMAGE_MIMES.has(mime) || IMAGE_EXTS.has(ext)) return "image";
  if (VIDEO_MIMES.has(mime) || VIDEO_EXTS.has(ext)) return "video";
  return null;
}

export const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 50 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase();
    const kind = classifyFile(file.mimetype, ext);
    if (kind === "image" || kind === "video") {
      cb(null, true);
    } else if (kind === "heic") {
      cb(new Error("HEIC/HEIF images are not supported. Please convert to JPG or PNG before uploading."));
    } else {
      cb(new Error("Only jpg, png, webp images and mp4 videos are allowed"));
    }
  },
});

export async function uploadFile(req: Request, res: Response) {
  if (!req.file) throw AppError.badRequest("No file uploaded");

  const ext = path.extname(req.file.originalname).toLowerCase();
  const kind = classifyFile(req.file.mimetype, ext);
  const isImage = kind === "image";
  const sanitizedName = randomUUID();
  const outExt = isImage ? ".jpg" : ".mp4";
  const filename = `${sanitizedName}${outExt}`;
  const filepath = path.join(uploadsDir, filename);

  if (isImage) {
    await sharp(req.file.buffer)
      .resize(1200, undefined, { withoutEnlargement: true })
      .jpeg({ quality: 80 })
      .toFile(filepath);
  } else {
    fs.writeFileSync(filepath, req.file.buffer);
  }

  res.json({ success: true, url: `/uploads/${filename}`, type: isImage ? "image" : "video" });
}

export async function deleteFile(req: Request, res: Response) {
  const { url } = req.body;
  if (!url || typeof url !== "string" || !url.startsWith("/uploads/")) {
    throw AppError.badRequest("Invalid URL");
  }

  const basename = path.basename(url);
  if (basename.includes("..") || basename.includes("/") || basename.includes("\\")) {
    throw AppError.badRequest("Invalid filename");
  }

  const filepath = path.join(uploadsDir, basename);
  if (fs.existsSync(filepath)) fs.unlinkSync(filepath);
  res.json({ success: true });
}

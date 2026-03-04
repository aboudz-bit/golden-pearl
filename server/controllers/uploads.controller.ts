import type { Request, Response } from "express";
import multer from "multer";
import sharp from "sharp";
import path from "path";
import fs from "fs";
import { randomUUID } from "crypto";
import { AppError } from "../utils/AppError";

const uploadsDir = path.resolve(process.cwd(), "uploads");
if (!fs.existsSync(uploadsDir)) fs.mkdirSync(uploadsDir, { recursive: true });

const ALLOWED_IMAGE_MIMES = ["image/jpeg", "image/jpg", "image/png", "image/webp"];
const ALLOWED_VIDEO_MIMES = ["video/mp4"];
const ALLOWED_IMAGE_EXTS = [".jpg", ".jpeg", ".png", ".webp"];
const ALLOWED_VIDEO_EXTS = [".mp4"];

export const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 50 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase();
    const isImage = ALLOWED_IMAGE_MIMES.includes(file.mimetype) && ALLOWED_IMAGE_EXTS.includes(ext);
    const isVideo = ALLOWED_VIDEO_MIMES.includes(file.mimetype) && ALLOWED_VIDEO_EXTS.includes(ext);
    if (isImage || isVideo) {
      cb(null, true);
    } else {
      cb(new Error("Only jpg, png, webp images and mp4 videos are allowed"));
    }
  },
});

export async function uploadFile(req: Request, res: Response) {
  if (!req.file) throw AppError.badRequest("No file uploaded");

  const sanitizedName = randomUUID();
  const isImage = req.file.mimetype.startsWith("image/");
  const ext = isImage ? ".jpg" : ".mp4";
  const filename = `${sanitizedName}${ext}`;
  const filepath = path.join(uploadsDir, filename);

  if (isImage) {
    await sharp(req.file.buffer)
      .resize(1200, undefined, { withoutEnlargement: true })
      .jpeg({ quality: 80 })
      .toFile(filepath);
  } else {
    fs.writeFileSync(filepath, req.file.buffer);
  }

  res.json({ url: `/uploads/${filename}`, type: isImage ? "image" : "video" });
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

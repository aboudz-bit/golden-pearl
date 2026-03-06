import { type ClassValue, clsx } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

export function formatDate(date: string | Date | null | undefined): string {
  if (!date) return "—";
  return new Date(date).toLocaleDateString("en-US", {
    month: "short",
    day: "numeric",
    year: "numeric",
  });
}

export function formatRelativeTime(date: string | Date | null | undefined): string {
  if (!date) return "—";
  const now = new Date();
  const d = new Date(date);
  const diffMs = now.getTime() - d.getTime();
  const diffMins = Math.floor(diffMs / 60000);
  const diffHours = Math.floor(diffMs / 3600000);
  const diffDays = Math.floor(diffMs / 86400000);

  if (diffMins < 1) return "just now";
  if (diffMins < 60) return `${diffMins}m ago`;
  if (diffHours < 24) return `${diffHours}h ago`;
  if (diffDays < 7) return `${diffDays}d ago`;
  return formatDate(date);
}

export function getStatusColor(status: string): string {
  switch (status) {
    case "published": return "bg-emerald-500/20 text-emerald-400 border-emerald-500/30";
    case "ready": return "bg-blue-500/20 text-blue-400 border-blue-500/30";
    case "draft": return "bg-zinc-500/20 text-zinc-400 border-zinc-500/30";
    case "archived": return "bg-amber-500/20 text-amber-400 border-amber-500/30";
    case "active": return "bg-emerald-500/20 text-emerald-400 border-emerald-500/30";
    default: return "bg-zinc-500/20 text-zinc-400 border-zinc-500/30";
  }
}

export function getExperienceTypeLabel(type: string): string {
  switch (type) {
    case "product_viewer": return "3D Viewer";
    case "surface_ar": return "Surface AR";
    case "image_target": return "Image Target";
    case "qr_launch": return "QR Launch";
    case "embed_viewer": return "Embed";
    default: return type;
  }
}

export function getExperienceTypeIcon(type: string): string {
  switch (type) {
    case "product_viewer": return "🎯";
    case "surface_ar": return "📱";
    case "image_target": return "🖼️";
    case "qr_launch": return "📲";
    case "embed_viewer": return "🔗";
    default: return "✨";
  }
}

export function truncate(str: string, len: number): string {
  if (str.length <= len) return str;
  return str.slice(0, len) + "…";
}

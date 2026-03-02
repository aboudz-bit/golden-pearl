import { clsx, type ClassValue } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

/** Format halalas as SAR currency string. */
export function formatSAR(halalas: number): string {
  return `SAR ${(halalas / 100).toFixed(2)}`;
}

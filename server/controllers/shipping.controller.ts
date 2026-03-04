import type { Request, Response } from "express";
import { shipping } from "../shipping";
import { AppError } from "../utils/AppError";

export async function quoteShipping(req: Request, res: Response) {
  const { destinationCity, destinationCountry, itemCount, subtotal } = req.body;
  if (!destinationCity || !destinationCountry) {
    throw AppError.badRequest("destinationCity and destinationCountry are required");
  }
  res.json(await shipping.quoteShipping({
    destinationCity,
    destinationCountry,
    itemCount: itemCount ?? 1,
    subtotal: subtotal ?? 0,
  }));
}

export async function createShipment(req: Request, res: Response) {
  res.json(await shipping.createShipment(req.body));
}

export async function trackShipment(req: Request, res: Response) {
  res.json(await shipping.trackShipment(req.params.trackingNumber));
}

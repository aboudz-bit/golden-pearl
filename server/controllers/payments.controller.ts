import type { Request, Response } from "express";
import { payments } from "../payments";
import { AppError } from "../utils/AppError";

export async function createPaymentStub(req: Request, res: Response) {
  const { orderId, amount, method } = req.body;
  if (!orderId || !amount) throw AppError.badRequest("orderId and amount are required");
  res.json({
    id: `pay_stub_${Date.now()}`,
    status: "initiated",
    amount,
    currency: "SAR",
    method: method || "applepay",
    orderId,
    message: "Moyasar integration pending — API key required",
  });
}

export async function moyasarWebhook(req: Request, res: Response) {
  console.log("Moyasar webhook received (stub):", JSON.stringify(req.body).substring(0, 200));
  res.json({ received: true });
}

export async function createPaymentSession(req: Request, res: Response) {
  const { orderId, amount, method } = req.body;
  if (!orderId || !amount || !method) throw AppError.badRequest("orderId, amount, and method are required");
  res.json(await payments.createPaymentSession({ orderId, amount, method, currency: "SAR" }));
}

export async function confirmPayment(req: Request, res: Response) {
  res.json(await payments.confirmPayment(req.params.sessionId));
}

export async function refundPayment(req: Request, res: Response) {
  const { amount, reason } = req.body;
  res.json(await payments.refundPayment({ sessionId: req.params.sessionId, amount, reason }));
}

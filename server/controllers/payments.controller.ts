import type { Request, Response } from "express";
import { createHmac } from "crypto";
import { payments } from "../payments";
import { storage } from "../storage";
import { AppError } from "../utils/AppError";

function verifyMoyasarSignature(req: Request): boolean {
  const secret = process.env.MOYASAR_WEBHOOK_SECRET;
  if (!secret) {
    console.warn("[webhook] MOYASAR_WEBHOOK_SECRET not set — skipping signature verification in dev mode");
    return !process.env.MOYASAR_API_KEY;
  }

  const signature = req.headers["x-moyasar-signature"] as string;
  if (!signature) {
    console.error("[webhook] Missing x-moyasar-signature header");
    return false;
  }

  const rawBody = (req as any).rawBody;
  if (!rawBody) {
    console.error("[webhook] Missing raw body for signature verification");
    return false;
  }

  const expected = createHmac("sha256", secret).update(rawBody).digest("hex");
  return signature === expected;
}

async function confirmOrderFromPayment(orderId: number, paymentId: string) {
  try {
    const order = await storage.updateOrderStatus(orderId, "confirmed");
    if (order) {
      console.log(`[payments] Order #${orderId} confirmed via payment ${paymentId}`);
    } else {
      console.error(`[payments] Order #${orderId} not found when confirming payment ${paymentId}`);
    }
  } catch (err) {
    console.error(`[payments] Failed to confirm order #${orderId} from payment ${paymentId}:`, err);
  }
}

export async function createPaymentStub(req: Request, res: Response) {
  const { orderId, amount, method } = req.body;
  if (!orderId || !amount) throw AppError.badRequest("orderId and amount are required");
  const session = await payments.createPaymentSession({
    orderId,
    amount,
    method: method || "visa",
    currency: "SAR",
    returnUrl: req.body.returnUrl,
  });
  res.json(session);
}

export async function moyasarWebhook(req: Request, res: Response) {
  if (!verifyMoyasarSignature(req)) {
    console.error("[webhook] Invalid or missing signature — rejecting");
    return res.status(401).json({ success: false, message: "Invalid signature" });
  }

  const { id, status, metadata } = req.body;
  console.log("[webhook] Moyasar:", JSON.stringify({ id, status, metadata }).substring(0, 300));

  if (id && (status === "paid" || status === "captured") && metadata?.orderId) {
    const orderId = parseInt(metadata.orderId);
    if (!isNaN(orderId)) {
      await confirmOrderFromPayment(orderId, id);
    } else {
      console.error(`[webhook] Invalid orderId in metadata: ${metadata.orderId}`);
    }
  }

  res.json({ received: true });
}

export async function createPaymentSession(req: Request, res: Response) {
  const { orderId, amount, method, returnUrl } = req.body;
  if (!orderId || !amount || !method) throw AppError.badRequest("orderId, amount, and method are required");
  const session = await payments.createPaymentSession({ orderId, amount, method, currency: "SAR", returnUrl });
  res.json(session);
}

export async function confirmPayment(req: Request, res: Response) {
  const session = await payments.confirmPayment(req.params.sessionId);
  if ((session.status === "captured" || session.status === "authorized") && session.metadata?.orderId) {
    await confirmOrderFromPayment(Number(session.metadata.orderId), session.id);
  }
  res.json(session);
}

export async function refundPayment(req: Request, res: Response) {
  const { amount, reason } = req.body;
  res.json(await payments.refundPayment({ sessionId: req.params.sessionId, amount, reason }));
}

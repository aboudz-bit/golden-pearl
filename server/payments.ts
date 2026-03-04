/**
 * Payment Abstraction Layer
 *
 * Vendor-agnostic payment interface supporting Apple Pay, Mada, Visa/MC.
 * Production provider: Moyasar (KSA-focused PSP with Apple Pay support).
 * Fallback: Mock provider for development/testing.
 */

export interface PaymentSession {
  id: string;
  amount: number; // halalas
  currency: string;
  status: "pending" | "authorized" | "captured" | "failed" | "refunded";
  provider: string;
  providerRef?: string;
  checkoutUrl?: string;
  metadata?: Record<string, unknown>;
  createdAt: Date;
}

export interface CreatePaymentInput {
  orderId: number;
  amount: number; // halalas
  currency?: string; // default SAR
  method: "apple_pay" | "mada" | "visa" | "mastercard" | "cod";
  returnUrl?: string;
  metadata?: Record<string, unknown>;
}

export interface RefundInput {
  sessionId: string;
  amount?: number; // partial refund in halalas; omit for full refund
  reason?: string;
}

export interface PaymentProvider {
  readonly name: string;
  createPaymentSession(input: CreatePaymentInput): Promise<PaymentSession>;
  confirmPayment(sessionId: string): Promise<PaymentSession>;
  refundPayment(input: RefundInput): Promise<PaymentSession>;
}

// ---------------------------------------------------------------------------
// Moyasar Provider — Production payment gateway for KSA
// Docs: https://docs.moyasar.com/
// ---------------------------------------------------------------------------

class MoyasarProvider implements PaymentProvider {
  readonly name = "moyasar";
  private apiKey: string;
  private baseUrl = "https://api.moyasar.com/v1";

  constructor(apiKey: string) {
    this.apiKey = apiKey;
  }

  private authHeader() {
    return "Basic " + Buffer.from(this.apiKey + ":").toString("base64");
  }

  async createPaymentSession(input: CreatePaymentInput): Promise<PaymentSession> {
    const amountHalalas = input.amount;
    const sourceType = input.method === "apple_pay" ? "applepay"
      : input.method === "mada" ? "creditcard"
      : "creditcard";

    const body: Record<string, any> = {
      amount: amountHalalas,
      currency: input.currency ?? "SAR",
      description: `Golden Pearl Order #${input.orderId}`,
      callback_url: input.returnUrl || `${process.env.APP_URL || ""}/api/webhooks/moyasar`,
      source: { type: sourceType },
      metadata: { orderId: String(input.orderId), method: input.method },
    };

    const res = await fetch(`${this.baseUrl}/payments`, {
      method: "POST",
      headers: {
        "Authorization": this.authHeader(),
        "Content-Type": "application/json",
      },
      body: JSON.stringify(body),
    });

    if (!res.ok) {
      const err = await res.text();
      console.error("[moyasar] create payment error:", err);
      throw new Error(`Payment creation failed: ${res.status}`);
    }

    const data = await res.json() as any;

    return {
      id: data.id,
      amount: data.amount,
      currency: data.currency,
      status: this.mapStatus(data.status),
      provider: this.name,
      providerRef: data.id,
      checkoutUrl: data.source?.transaction_url || undefined,
      metadata: { orderId: input.orderId, method: input.method },
      createdAt: new Date(data.created_at),
    };
  }

  async confirmPayment(sessionId: string): Promise<PaymentSession> {
    const res = await fetch(`${this.baseUrl}/payments/${sessionId}`, {
      headers: { "Authorization": this.authHeader() },
    });

    if (!res.ok) throw new Error(`Payment fetch failed: ${res.status}`);
    const data = await res.json() as any;

    return {
      id: data.id,
      amount: data.amount,
      currency: data.currency,
      status: this.mapStatus(data.status),
      provider: this.name,
      providerRef: data.id,
      metadata: data.metadata,
      createdAt: new Date(data.created_at),
    };
  }

  async refundPayment(input: RefundInput): Promise<PaymentSession> {
    const body: Record<string, any> = {};
    if (input.amount) body.amount = input.amount;
    if (input.reason) body.description = input.reason;

    const res = await fetch(`${this.baseUrl}/payments/${input.sessionId}/refund`, {
      method: "POST",
      headers: {
        "Authorization": this.authHeader(),
        "Content-Type": "application/json",
      },
      body: JSON.stringify(body),
    });

    if (!res.ok) throw new Error(`Refund failed: ${res.status}`);
    const data = await res.json() as any;

    return {
      id: data.id,
      amount: data.amount,
      currency: data.currency,
      status: "refunded",
      provider: this.name,
      providerRef: data.id,
      metadata: data.metadata,
      createdAt: new Date(data.created_at),
    };
  }

  private mapStatus(moyasarStatus: string): PaymentSession["status"] {
    switch (moyasarStatus) {
      case "initiated":
      case "pending": return "pending";
      case "authorized": return "authorized";
      case "paid":
      case "captured": return "captured";
      case "refunded": return "refunded";
      case "failed":
      case "expired":
      case "voided": return "failed";
      default: return "pending";
    }
  }
}

// ---------------------------------------------------------------------------
// Mock Provider — for development and testing
// ---------------------------------------------------------------------------

class MockPaymentProvider implements PaymentProvider {
  readonly name = "mock";
  private sessions = new Map<string, PaymentSession>();

  async createPaymentSession(input: CreatePaymentInput): Promise<PaymentSession> {
    const session: PaymentSession = {
      id: `pay_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`,
      amount: input.amount,
      currency: input.currency ?? "SAR",
      status: "pending",
      provider: this.name,
      metadata: { orderId: input.orderId, method: input.method, ...input.metadata },
      createdAt: new Date(),
    };
    this.sessions.set(session.id, session);
    return session;
  }

  async confirmPayment(sessionId: string): Promise<PaymentSession> {
    const session = this.sessions.get(sessionId);
    if (!session) throw new Error(`Payment session ${sessionId} not found`);
    session.status = "captured";
    return session;
  }

  async refundPayment(input: RefundInput): Promise<PaymentSession> {
    const session = this.sessions.get(input.sessionId);
    if (!session) throw new Error(`Payment session ${input.sessionId} not found`);
    if (session.status !== "captured") throw new Error("Can only refund captured payments");
    session.status = "refunded";
    return session;
  }
}

// ---------------------------------------------------------------------------
// Provider initialization — auto-selects based on MOYASAR_API_KEY env var
// ---------------------------------------------------------------------------

const moyasarKey = process.env.MOYASAR_API_KEY;

let _provider: PaymentProvider = moyasarKey
  ? new MoyasarProvider(moyasarKey)
  : new MockPaymentProvider();

if (moyasarKey) {
  console.log("[payments] Using Moyasar payment provider");
} else {
  console.log("[payments] No MOYASAR_API_KEY found — using mock payment provider");
}

export function getPaymentProvider(): PaymentProvider {
  return _provider;
}

export function setPaymentProvider(provider: PaymentProvider): void {
  _provider = provider;
}

export const payments = {
  createPaymentSession: (input: CreatePaymentInput) => _provider.createPaymentSession(input),
  confirmPayment: (sessionId: string) => _provider.confirmPayment(sessionId),
  refundPayment: (input: RefundInput) => _provider.refundPayment(input),
};

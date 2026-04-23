import axios from "axios";
import * as crypto from "crypto";

const PAYSTACK_BASE = "https://api.paystack.co";

function paystackHeaders() {
  const secret = process.env.PAYSTACK_SECRET_KEY;
  if (!secret) throw new Error("PAYSTACK_SECRET_KEY env var not set");
  return {
    Authorization: `Bearer ${secret}`,
    "Content-Type": "application/json",
  };
}

export interface InitializePaymentParams {
  email: string;
  amountInKobo: number;
  reference: string;
  metadata?: Record<string, unknown>;
  callbackUrl?: string;
}

export interface InitializePaymentResult {
  authorization_url: string;
  access_code: string;
  reference: string;
}

export async function initializeTransaction(
  params: InitializePaymentParams
): Promise<InitializePaymentResult> {
  const { data } = await axios.post(
    `${PAYSTACK_BASE}/transaction/initialize`,
    {
      email: params.email,
      amount: params.amountInKobo,
      reference: params.reference,
      metadata: params.metadata ?? {},
      callback_url: params.callbackUrl,
    },
    { headers: paystackHeaders() }
  );

  if (!data.status) {
    throw new Error(`Paystack init failed: ${data.message}`);
  }

  return data.data as InitializePaymentResult;
}

export interface VerifyTransactionResult {
  status: "success" | "failed" | "abandoned" | "pending";
  reference: string;
  amount: number; // kobo
  paidAt: string;
  metadata: Record<string, unknown>;
}

export async function verifyTransaction(
  reference: string
): Promise<VerifyTransactionResult> {
  const { data } = await axios.get(
    `${PAYSTACK_BASE}/transaction/verify/${encodeURIComponent(reference)}`,
    { headers: paystackHeaders() }
  );

  if (!data.status) {
    throw new Error(`Paystack verify failed: ${data.message}`);
  }

  return {
    status: data.data.status,
    reference: data.data.reference,
    amount: data.data.amount,
    paidAt: data.data.paid_at,
    metadata: data.data.metadata ?? {},
  };
}

/** Validates the X-Paystack-Signature header against the raw request body. */
export function validateWebhookSignature(
  rawBody: string,
  signature: string
): boolean {
  const secret = process.env.PAYSTACK_SECRET_KEY;
  if (!secret) return false;
  const hash = crypto
    .createHmac("sha512", secret)
    .update(rawBody)
    .digest("hex");
  return hash === signature;
}

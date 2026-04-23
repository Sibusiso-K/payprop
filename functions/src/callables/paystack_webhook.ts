import { https } from "firebase-functions/v2";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { validateWebhookSignature } from "../services/paystack";
import * as express from "express";

const db = () => getFirestore();

/**
 * HTTPS endpoint: paystackWebhook
 *
 * Paystack POSTs events here (charge.success, charge.failed, etc.).
 * Verifies the HMAC-SHA512 signature before processing.
 *
 * Register this URL in your Paystack dashboard:
 *   https://<region>-<project-id>.cloudfunctions.net/paystackWebhook
 */
export const paystackWebhook = https.onRequest(
  { invoker: "public" },
  async (req: express.Request, res: express.Response) => {
    // Only accept POST
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    const signature = req.headers["x-paystack-signature"] as string;
    const rawBody = JSON.stringify(req.body);

    if (!validateWebhookSignature(rawBody, signature)) {
      console.warn("Invalid Paystack webhook signature");
      res.status(401).send("Unauthorized");
      return;
    }

    const event = req.body as {
      event: string;
      data: {
        reference: string;
        status: string;
        amount: number;
        paid_at: string;
        metadata?: { paymentId?: string };
      };
    };

    console.log(`Paystack event received: ${event.event}`);

    try {
      await handlePaystackEvent(event);
      res.status(200).send("OK");
    } catch (err) {
      console.error("Webhook handler error:", err);
      // Still return 200 so Paystack doesn't retry indefinitely
      res.status(200).send("OK");
    }
  }
);

async function handlePaystackEvent(event: {
  event: string;
  data: {
    reference: string;
    status: string;
    amount: number;
    paid_at: string;
    metadata?: { paymentId?: string };
  };
}): Promise<void> {
  const { reference, amount, paid_at, metadata } = event.data;

  // Find the payment by Paystack reference
  const snap = await db()
    .collection("payments")
    .where("paystackReference", "==", reference)
    .limit(1)
    .get();

  if (snap.empty) {
    console.warn(`No payment found for reference: ${reference}`);
    return;
  }

  const paymentRef = snap.docs[0].ref;

  switch (event.event) {
    case "charge.success":
      await paymentRef.update({
        status: "completed",
        paidAt: paid_at
          ? new Date(paid_at)
          : FieldValue.serverTimestamp(),
        // Paystack amount is in kobo — convert to Rand for consistency check
        verifiedAmount: amount / 100,
        webhookVerified: true,
        updatedAt: FieldValue.serverTimestamp(),
      });
      console.log(`Payment ${paymentRef.id} marked completed via webhook`);
      break;

    case "charge.failed":
      await paymentRef.update({
        status: "failed",
        updatedAt: FieldValue.serverTimestamp(),
      });
      console.log(`Payment ${paymentRef.id} marked failed via webhook`);
      break;

    default:
      console.log(`Unhandled Paystack event: ${event.event}`);
  }
}

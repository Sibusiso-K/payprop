import { https } from "firebase-functions/v2";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { v4 as uuidv4 } from "uuid";
import {
  initializeTransaction,
  verifyTransaction,
} from "../services/paystack";

const db = () => getFirestore();

/**
 * Callable: initializePaystackPayment
 *
 * Called by the Flutter app before redirecting the user to Paystack.
 * Creates a pending payment document and returns the authorization_url.
 *
 * Expected input:
 *   { paymentId, tenantId, email, amountInKobo }
 */
export const initializePaystackPayment = https.onCall(
  { enforceAppCheck: false },
  async (request) => {
    if (!request.auth) {
      throw new https.HttpsError("unauthenticated", "Sign in required.");
    }

    const { paymentId, email, amountInKobo } = request.data as {
      paymentId: string;
      tenantId: string;
      email: string;
      amountInKobo: number;
    };

    if (!paymentId || !email || !amountInKobo) {
      throw new https.HttpsError(
        "invalid-argument",
        "paymentId, email and amountInKobo are required."
      );
    }

    // Generate a unique Paystack reference tied to this payment document
    const reference = `propal_${paymentId}_${uuidv4().substring(0, 8)}`;

    const result = await initializeTransaction({
      email,
      amountInKobo,
      reference,
      metadata: { paymentId, uid: request.auth.uid },
      callbackUrl: `https://propal.app/payment/callback`,
    });

    // Persist the reference so the webhook can match it back
    await db().collection("payments").doc(paymentId).update({
      paystackReference: reference,
      paystackAuthUrl: result.authorization_url,
      updatedAt: FieldValue.serverTimestamp(),
    });

    return {
      authorization_url: result.authorization_url,
      reference: result.reference,
      access_code: result.access_code,
    };
  }
);

/**
 * Callable: verifyPaystackPayment
 *
 * Called by the Flutter app after the WebView redirect completes.
 * Verifies with Paystack and returns the current status.
 *
 * Expected input: { reference }
 */
export const verifyPaystackPayment = https.onCall(
  { enforceAppCheck: false },
  async (request) => {
    if (!request.auth) {
      throw new https.HttpsError("unauthenticated", "Sign in required.");
    }

    const { reference } = request.data as { reference: string };
    if (!reference) {
      throw new https.HttpsError("invalid-argument", "reference is required.");
    }

    const result = await verifyTransaction(reference);

    // If success, update the payment document (webhook may already have done this)
    if (result.status === "success") {
      const snap = await db()
        .collection("payments")
        .where("paystackReference", "==", reference)
        .limit(1)
        .get();

      if (!snap.empty) {
        await snap.docs[0].ref.update({
          status: "completed",
          paidAt: FieldValue.serverTimestamp(),
        });
      }
    }

    return { status: result.status };
  }
);

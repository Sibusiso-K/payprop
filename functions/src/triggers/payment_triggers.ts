import { firestore } from "firebase-functions/v2";
import {
  getFirestore,
  FieldValue,
  Timestamp,
} from "firebase-admin/firestore";
import { notifyUsers } from "../services/fcm";

const db = () => getFirestore();

/**
 * Fires when a payment document is written.
 * When status transitions to "completed":
 *   1. Creates a receipt document in the documents collection.
 *   2. Notifies tenant, agent and homeowner.
 */
export const onPaymentWritten = firestore
  .onDocumentWritten("payments/{paymentId}", async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();

    if (!after) return; // document deleted — nothing to do

    const statusChanged = before?.status !== after.status;
    const isCompleted = after.status === "completed";

    if (!statusChanged || !isCompleted) return;

    const paymentId = event.params.paymentId;

    // 1. Generate receipt document
    await db()
      .collection("documents")
      .doc(`receipt_${paymentId}`)
      .set({
        type: "receipt",
        title: `Rent Receipt — ${after.month}`,
        url: "", // populated later when PDF generation is added
        uploadedBy: "system",
        relatedId: paymentId,
        visibleTo: [after.tenantId, after.agentId, after.ownerId],
        createdAt: FieldValue.serverTimestamp(),
        expiresAt: null,
      });

    // 2. Notify all parties
    const amount = new Intl.NumberFormat("en-ZA", {
      style: "currency",
      currency: "ZAR",
    }).format(after.amount);

    await notifyUsers(
      [after.tenantId, after.agentId, after.ownerId],
      {
        title: "Payment Received ✅",
        body: `${amount} rent payment for ${after.month} has been confirmed.`,
        data: {
          type: "payment_completed",
          paymentId,
          propertyId: after.propertyId,
        },
      }
    );

    console.log(`Payment ${paymentId} completed — receipt created, notifications sent`);
  });

/**
 * Fires when a payment document is written.
 * When status transitions to "failed": notifies the tenant.
 */
export const onPaymentFailed = firestore
  .onDocumentWritten("payments/{paymentId}", async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();

    if (!after) return;
    if (before?.status === after.status) return;
    if (after.status !== "failed") return;

    await notifyUsers([after.tenantId], {
      title: "Payment Failed ❌",
      body: "Your rent payment could not be processed. Please try again.",
      data: {
        type: "payment_failed",
        paymentId: event.params.paymentId,
      },
    });
  });

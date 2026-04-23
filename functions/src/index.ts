import { initializeApp } from "firebase-admin/app";

// Initialise Firebase Admin once for the whole functions package
initializeApp();

// ─── Auth Triggers ────────────────────────────────────────────────────────────
export { onUserCreated, onUserDeleted } from "./triggers/auth_triggers";

// ─── Firestore Triggers ───────────────────────────────────────────────────────
export {
  onPaymentWritten,
  onPaymentFailed,
} from "./triggers/payment_triggers";

export {
  onMaintenanceCreated,
  onMaintenanceUpdated,
} from "./triggers/maintenance_triggers";

// ─── HTTPS Callables (called from Flutter) ────────────────────────────────────
export {
  initializePaystackPayment,
  verifyPaystackPayment,
} from "./callables/paystack_callables";

// ─── HTTPS Webhook (called by Paystack) ───────────────────────────────────────
export { paystackWebhook } from "./callables/paystack_webhook";

// ─── Scheduled Functions ─────────────────────────────────────────────────────
export { sendRentReminders } from "./scheduled/rent_reminders";
export { checkExpiringLeases } from "./scheduled/lease_checker";

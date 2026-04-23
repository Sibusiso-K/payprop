import { scheduler } from "firebase-functions/v2";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { notifyUser } from "../services/fcm";

const db = () => getFirestore();

/**
 * Scheduled: sendRentReminders
 * Runs every day at 08:00 SAST (UTC+2 = 06:00 UTC).
 *
 * Finds all pending rent payments due within the next 3 days
 * and sends a push notification to each tenant.
 */
export const sendRentReminders = scheduler.onSchedule(
  {
    schedule: "0 6 * * *", // daily 06:00 UTC = 08:00 SAST
    timeZone: "Africa/Johannesburg",
  },
  async () => {
    const now = new Date();
    const in3Days = new Date(now.getTime() + 3 * 24 * 60 * 60 * 1000);

    const snap = await db()
      .collection("payments")
      .where("status", "==", "pending")
      .where("type", "==", "rent")
      .where("dueDate", ">=", Timestamp.fromDate(now))
      .where("dueDate", "<=", Timestamp.fromDate(in3Days))
      .get();

    if (snap.empty) {
      console.log("No rent reminders to send today.");
      return;
    }

    const notifications = snap.docs.map(async (doc) => {
      const payment = doc.data();
      const dueDate = (payment.dueDate as Timestamp).toDate();
      const daysUntilDue = Math.ceil(
        (dueDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24)
      );

      const amount = new Intl.NumberFormat("en-ZA", {
        style: "currency",
        currency: "ZAR",
      }).format(payment.amount);

      const bodyText =
        daysUntilDue === 0
          ? `Your rent of ${amount} is due today.`
          : `Your rent of ${amount} is due in ${daysUntilDue} day${daysUntilDue > 1 ? "s" : ""}.`;

      await notifyUser(payment.tenantId, {
        title: "Rent Reminder 🏠",
        body: bodyText,
        data: {
          type: "rent_reminder",
          paymentId: doc.id,
          dueDate: dueDate.toISOString(),
        },
      });
    });

    await Promise.allSettled(notifications);
    console.log(`Sent ${snap.size} rent reminder(s).`);
  }
);

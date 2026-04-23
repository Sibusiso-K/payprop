import { scheduler } from "firebase-functions/v2";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { notifyUsers } from "../services/fcm";

const db = () => getFirestore();

/**
 * Scheduled: checkExpiringLeases
 * Runs every day at 08:00 SAST.
 *
 * Alerts agents and homeowners when a lease expires in exactly 30 or 7 days,
 * giving them enough time to arrange a renewal or new tenant.
 */
export const checkExpiringLeases = scheduler.onSchedule(
  {
    schedule: "0 6 * * *",
    timeZone: "Africa/Johannesburg",
  },
  async () => {
    const now = new Date();

    const alertDays = [30, 7];
    let totalAlerts = 0;

    for (const days of alertDays) {
      // Target: leases whose leaseEnd falls within a 24-hour window
      const windowStart = new Date(now.getTime() + days * 24 * 60 * 60 * 1000);
      const windowEnd = new Date(
        windowStart.getTime() + 24 * 60 * 60 * 1000
      );

      const snap = await db()
        .collection("tenancies")
        .where("status", "==", "active")
        .where("leaseEnd", ">=", Timestamp.fromDate(windowStart))
        .where("leaseEnd", "<", Timestamp.fromDate(windowEnd))
        .get();

      if (snap.empty) continue;

      const alerts = snap.docs.map(async (doc) => {
        const tenancy = doc.data();
        const leaseEnd = (tenancy.leaseEnd as Timestamp)
          .toDate()
          .toLocaleDateString("en-ZA");

        await notifyUsers([tenancy.agentId, tenancy.ownerId], {
          title: `Lease Expiring in ${days} Days`,
          body: `A tenancy at property ${tenancy.propertyId} expires on ${leaseEnd}. Consider renewal.`,
          data: {
            type: "lease_expiring",
            tenancyId: doc.id,
            propertyId: tenancy.propertyId,
            daysLeft: String(days),
          },
        });
      });

      await Promise.allSettled(alerts);
      totalAlerts += snap.size;
    }

    console.log(`Lease expiry check complete — ${totalAlerts} alert(s) sent.`);
  }
);

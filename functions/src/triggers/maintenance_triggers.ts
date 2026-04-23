import { firestore } from "firebase-functions/v2";
import { getFirestore } from "firebase-admin/firestore";
import { notifyUser, notifyUsers } from "../services/fcm";

const db = () => getFirestore();

/**
 * Fires when a new maintenance request is created.
 * Notifies the assigned agent immediately.
 */
export const onMaintenanceCreated = firestore
  .onDocumentCreated("maintenance/{requestId}", async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const { agentId, category, description, propertyId } = data;

    // Fetch property name for context
    const propertySnap = await db()
      .collection("properties")
      .doc(propertyId)
      .get();
    const propertyName = propertySnap.data()?.name ?? "a property";

    const categoryLabel =
      (category as string)[0].toUpperCase() +
      (category as string).slice(1);

    await notifyUser(agentId, {
      title: `New Maintenance Request — ${categoryLabel}`,
      body: `${propertyName}: ${description}`.substring(0, 120),
      data: {
        type: "maintenance_created",
        requestId: event.params.requestId,
        propertyId,
      },
    });

    console.log(
      `Maintenance ${event.params.requestId} created — agent ${agentId} notified`
    );
  });

/**
 * Fires when a maintenance request is updated.
 * Notifies the tenant when their request status changes.
 */
export const onMaintenanceUpdated = firestore
  .onDocumentUpdated("maintenance/{requestId}", async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();

    if (!before || !after) return;
    if (before.status === after.status) return;

    const statusMessages: Record<string, string> = {
      assigned: "A vendor has been assigned to your request.",
      inProgress: "Work on your maintenance request has started.",
      completed: "Your maintenance request has been resolved. ✅",
      rejected: "Your maintenance request was not approved.",
    };

    const msg = statusMessages[after.status as string];
    if (!msg) return;

    await notifyUser(after.tenantId, {
      title: "Maintenance Update",
      body: msg,
      data: {
        type: "maintenance_updated",
        requestId: event.params.requestId,
        status: after.status,
      },
    });

    // Also notify owner when a quote is awaiting their approval
    if (after.status === "assigned" && after.quote) {
      await notifyUser(after.ownerId, {
        title: "Quote Awaiting Approval",
        body: `A maintenance quote of R${after.quote} requires your approval.`,
        data: {
          type: "quote_pending",
          requestId: event.params.requestId,
        },
      });
    }
  });

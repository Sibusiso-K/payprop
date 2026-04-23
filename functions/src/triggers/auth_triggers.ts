import { auth } from "firebase-functions/v2";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

const db = () => getFirestore();

/**
 * Fires when a new Firebase Auth user is created.
 * Creates the corresponding Firestore user document.
 */
export const onUserCreated = auth.user().onCreate(async (user) => {
  const { uid, email, displayName, phoneNumber } = user;

  const userDoc = {
    uid,
    email: email ?? "",
    phone: phoneNumber ?? null,
    displayName: displayName ?? email?.split("@")[0] ?? "User",
    // Role is set during registration via the Flutter app before this trigger
    // fires — but we default to tenant as a safety fallback.
    role: "tenant",
    profileComplete: false,
    photoUrl: user.photoURL ?? null,
    fcmToken: null,
    createdAt: FieldValue.serverTimestamp(),
  };

  await db().collection("users").doc(uid).set(userDoc, { merge: true });

  console.log(`User doc created for ${uid} (${email})`);
});

/**
 * Fires when a Firebase Auth user is deleted.
 * Marks their Firestore document as deleted (soft delete).
 */
export const onUserDeleted = auth.user().onDelete(async (user) => {
  await db().collection("users").doc(user.uid).update({
    deleted: true,
    deletedAt: FieldValue.serverTimestamp(),
  });

  console.log(`User ${user.uid} marked as deleted`);
});

import { getMessaging } from "firebase-admin/messaging";
import { getFirestore } from "firebase-admin/firestore";

const db = () => getFirestore();

/** Fetch the FCM token stored on a user document. */
async function getToken(uid: string): Promise<string | null> {
  const snap = await db().collection("users").doc(uid).get();
  return (snap.data()?.fcmToken as string) ?? null;
}

/** Fetch tokens for multiple users, filtering out nulls. */
async function getTokens(uids: string[]): Promise<string[]> {
  const tokens = await Promise.all(uids.map(getToken));
  return tokens.filter((t): t is string => t !== null);
}

export interface PushPayload {
  title: string;
  body: string;
  data?: Record<string, string>;
}

/** Send a push notification to a single user. */
export async function notifyUser(
  uid: string,
  payload: PushPayload
): Promise<void> {
  const token = await getToken(uid);
  if (!token) return;

  await getMessaging().send({
    token,
    notification: { title: payload.title, body: payload.body },
    data: payload.data ?? {},
    android: { priority: "high" },
    apns: { payload: { aps: { sound: "default" } } },
  });
}

/** Send a push notification to multiple users. */
export async function notifyUsers(
  uids: string[],
  payload: PushPayload
): Promise<void> {
  const tokens = await getTokens(uids);
  if (tokens.length === 0) return;

  // Batch in groups of 500 (FCM multicast limit)
  const chunks = [];
  for (let i = 0; i < tokens.length; i += 500) {
    chunks.push(tokens.slice(i, i + 500));
  }

  await Promise.all(
    chunks.map((chunk) =>
      getMessaging().sendEachForMulticast({
        tokens: chunk,
        notification: { title: payload.title, body: payload.body },
        data: payload.data ?? {},
        android: { priority: "high" },
        apns: { payload: { aps: { sound: "default" } } },
      })
    )
  );
}

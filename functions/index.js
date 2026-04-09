const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.deleteUser = functions.https.onCall(async (data, context) => {
  const {uid} = data; // ✅ cleaned spacing

  if (!context.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated",
        "Only authenticated users can call this function.",
    );
  }

  if (!uid) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "UID is required",
    );
  }

  try {
    // 🔥 Delete from Auth
    await admin.auth().deleteUser(uid);

    // 🔥 Delete from Firestore
    await admin.firestore().collection("users").doc(uid).delete();

    return {success: true, message: `User ${uid} deleted successfully 🚀`};
  } catch (error) {
    console.error("Error deleting user:", error);
    throw new functions.https.HttpsError(
        "unknown",
        "Failed to delete user",
        error.message,
    );
  }
});

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalResultSyncManager {
  static const String _queueKey = 'offline_results_queue';

  /// Saves a completed exam into the local offline SQLite/SharedPrefs queue
  static Future<void> queueResultOffline(Map<String, dynamic> resultData, String docId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> rawQueue = prefs.getStringList(_queueKey) ?? [];

    resultData['docId'] = docId; // Store docId natively inside payload

    // Avoid duplicating exact active id
    rawQueue.removeWhere((item) {
       final Map decoded = jsonDecode(item);
       return decoded['docId'] == docId;
    });

    // We can't safely serialize Timestamp via jsonEncode easily, 
    // so we convert to Iso8601 string for local storage.
    resultData['completedAt'] = DateTime.now().toIso8601String();

    rawQueue.add(jsonEncode(resultData));
    await prefs.setStringList(_queueKey, rawQueue);
  }

  /// Blasts the stuck queue to Firestore when device retrieves connection
  static Future<void> syncOfflineResults() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> rawQueue = prefs.getStringList(_queueKey) ?? [];

    if (rawQueue.isEmpty) return;

    List<String> successfulUploads = [];

    for (String item in rawQueue) {
      try {
        final Map<String, dynamic> data = jsonDecode(item);
        final String docId = data.remove('docId'); // extract to use as key

        // Convert the string completedAt back to Firestore Timestamp safely
        if (data['completedAt'] != null) {
          data['completedAt'] = Timestamp.fromDate(DateTime.parse(data['completedAt']));
        }

        await FirebaseFirestore.instance.collection('quizResults').doc(docId).set(data);
        successfulUploads.add(item);
      } catch (e) {
        // If it throws here, meaning no internet yet, it just stays in the queue loop!
        continue;
      }
    }

    // Safely remove the items that made it sequentially to the cloud
    for (String ok in successfulUploads) {
      rawQueue.remove(ok);
    }

    prefs.setStringList(_queueKey, rawQueue);
  }
}

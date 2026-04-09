import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class StudentNotification extends StatelessWidget {
  const StudentNotification({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Announcements"),
        backgroundColor: const Color(0xFF001F3F),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('announcements')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No announcements yet.",
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          final announcements = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              final doc = announcements[index];
              final data = doc.data() as Map<String, dynamic>?;

              final title = data?['title'] ?? "No Title";
              final description = data?['description'] ?? "";
              final timestamp = data?['date'] as Timestamp?;
              final date = timestamp != null
                  ? DateFormat.yMMMd().add_jm().format(timestamp.toDate())
                  : "Unknown date";

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(description),
                      const SizedBox(height: 8),
                      Text(
                        date,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  leading: const Icon(
                    Icons.announcement,
                    color: Colors.deepPurple,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

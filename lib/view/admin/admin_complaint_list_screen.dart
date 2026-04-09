import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminComplaintListScreen extends StatelessWidget {
  const AdminComplaintListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Complaints"),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('complaints')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No complaints yet 🎉"));
          }

          final complaints = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: complaints.length,
            itemBuilder: (context, index) {
              final doc = complaints[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  title: Text(
                    data['complaint'] ?? 'No text',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    (data['timestamp'] as Timestamp)
                        .toDate()
                        .toLocal()
                        .toString(),
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == "delete") {
                        await doc.reference.delete();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Complaint deleted 🗑️"),
                          ),
                        );
                      }
                      if (value == "resolve") {
                        await doc.reference.update({"resolved": true});
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Marked as resolved ✅")),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: "resolve",
                        child: Text("Mark as Resolved"),
                      ),
                      const PopupMenuItem(
                        value: "delete",
                        child: Text("Delete"),
                      ),
                    ],
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Complaint Details"),
                        content: Text(data['complaint'] ?? "No complaint text"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Close"),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

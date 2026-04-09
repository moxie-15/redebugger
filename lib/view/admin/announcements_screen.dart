import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:redebugger/theme/theme.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  Future<void> _postAnnouncement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await _firestore.collection('announcements').add({
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'date': Timestamp.now(),
        'createdBy': 'Admin',
      });

      _titleController.clear();
      _descController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Announcement posted successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to post announcement: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Post Announcement"),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Title',
                            border: OutlineInputBorder(),
                          ),
                          validator: (val) =>
                              val == null || val.isEmpty ? 'Enter title' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descController,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(),
                          ),
                          validator: (val) => val == null || val.isEmpty
                              ? 'Enter description'
                              : null,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _postAnnouncement,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                          child: const Text("Post Announcement"),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 10),
                  const Text(
                    "Recent Announcements",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('announcements')
                          .orderBy('date', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final announcements = snapshot.data!.docs;

                        if (announcements.isEmpty) {
                          return const Center(
                            child: Text("No announcements yet."),
                          );
                        }

                        return ListView.builder(
                          itemCount: announcements.length,
                          itemBuilder: (context, index) {
                            final doc = announcements[index];
                            final data = doc.data() as Map<String, dynamic>?;

                            final title = data?['title'] ?? "No Title";
                            final description = data?['description'] ?? "";
                            final timestamp = data?['date'] as Timestamp?;
                            final date = timestamp != null
                                ? timestamp.toDate().toString()
                                : "Unknown date";

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                title: Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 8),
                                    Text(description),
                                    const SizedBox(height: 6),
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
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

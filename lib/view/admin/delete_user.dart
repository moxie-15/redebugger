import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:redebugger/theme/theme.dart';

class DeleteUserScreen extends StatefulWidget {
  const DeleteUserScreen({super.key});

  @override
  State<DeleteUserScreen> createState() => _DeleteUserScreenState();
}

class _DeleteUserScreenState extends State<DeleteUserScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String apiKey = "AIzaSyACllx_r561xGlxeE6epqGQHdQQOZJLAt0";
  bool _isDeleting = false;

  /// Delete user from Firebase Auth REST API
  Future<void> _deleteAuthUser(String uid) async {
    // ⚠️ This needs an Admin SDK token normally.
    // For client-side demo, we only remove from Firestore.
    // To truly delete from Firebase Auth, handle on backend with Admin SDK.

    // Placeholder logic
    print("Auth user $uid deletion would happen here via Admin SDK.");
  }

  /// Delete user from Firestore
  Future<void> _deleteUser(String uid) async {
    setState(() => _isDeleting = true);

    try {
      await _firestore.collection("users").doc(uid).delete();
      await _deleteAuthUser(uid);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User deleted successfully 🗑️")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error deleting user: $e")));
    } finally {
      setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Delete User"),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection("users")
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No users found 😅"));
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final uid = user.id;
              final email = user['email'];
              final role = user['role'];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                child: ListTile(
                  leading: const Icon(
                    Icons.person,
                    color: AppTheme.buttonColor,
                    size: 32,
                  ),
                  title: Text(email),
                  subtitle: Text("Role: $role"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: _isDeleting
                        ? null
                        : () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Confirm Delete"),
                                content: Text("Delete user $email?"),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _deleteUser(uid);
                                    },
                                    child: const Text(
                                      "Delete",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
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

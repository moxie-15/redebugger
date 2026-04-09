import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:redebugger/theme/theme.dart';

class StudentResultScreen extends StatefulWidget {
  const StudentResultScreen({super.key});

  @override
  State<StudentResultScreen> createState() => _StudentResultScreenState();
}

class _StudentResultScreenState extends State<StudentResultScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Results"),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: user == null
          ? const Center(child: Text("Please sign in to view your results."))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('quizResults')
                  .where('studentId', isEqualTo: user!.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text("Error loading results."));
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.info_outline, size: 80, color: Colors.orange),
                          SizedBox(height: 24),
                          Text(
                            "You haven't taken any exams yet.",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final title = data['quizTitle'] ?? 'Unknown Exam';
                    final score = data['score'] ?? 0;
                    final total = data['totalQuestions'] ?? 0;
                    final showResults = data['showResultsToStudent'] ?? false;

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: showResults ? Colors.green.shade100 : Colors.orange.shade100,
                          child: Icon(showResults ? Icons.check_circle : Icons.pending, color: showResults ? Colors.green : Colors.orange),
                        ),
                        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: showResults
                              ? Text("Score: $score / $total", style: const TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold))
                              : const Text("Pending Teacher Release", style: TextStyle(fontSize: 14, color: Colors.orange, fontStyle: FontStyle.italic)),
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


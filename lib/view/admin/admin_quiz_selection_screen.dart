import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:redebugger/model/quiz.dart';
import 'package:redebugger/theme/theme.dart';
import 'package:redebugger/view/admin/result_screen.dart';

class AdminQuizSelectionScreen extends StatefulWidget {
  const AdminQuizSelectionScreen({super.key});

  @override
  State<AdminQuizSelectionScreen> createState() =>
      _AdminQuizSelectionScreenState();
}

class _AdminQuizSelectionScreenState extends State<AdminQuizSelectionScreen> {
  List<Quiz> _quizzes = [];

  @override
  void initState() {
    super.initState();
    _fetchQuizzes();
  }

  Future<void> _fetchQuizzes() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('quizzes')
        .orderBy('createdAt', descending: true)
        .get();

    setState(() {
      _quizzes = snapshot.docs
          .map(
            (doc) =>
                Quiz.fromMap(doc.data(), id: doc.id),
          )
          .toList();
    });
  }

  void _openResults(Quiz quiz) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ResultScreen(quiz: quiz)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Quiz"),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: _quizzes.isEmpty
          ? const Center(child: Text("No quizzes available"))
          : ListView.builder(
              itemCount: _quizzes.length,
              itemBuilder: (context, index) {
                final quiz = _quizzes[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    title: Text(quiz.title),
                    subtitle: Text("Category: ${quiz.categoryName}"),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => _openResults(quiz),
                  ),
                );
              },
            ),
    );
  }
}

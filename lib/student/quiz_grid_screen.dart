// lib/student/quiz_grid_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:redebugger/model/category.dart';
import 'package:redebugger/model/quiz.dart';
import 'package:redebugger/student/quiz_question_screen.dart';

class QuizGridScreen extends StatefulWidget {
  final Category category;
  final String studentName; // Required
  final String studentClass; // Required

  const QuizGridScreen({
    super.key,
    required this.category,
    required this.studentName,
    required this.studentClass,
  });

  @override
  State<QuizGridScreen> createState() => _QuizGridScreenState();
}

class _QuizGridScreenState extends State<QuizGridScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Quiz> _quizzes = [];
  bool _loading = true;

  String? get _studentId => _auth.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _fetchQuizzes();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_studentId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No logged-in student found. Sign-in required.'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "✅ Logged in: ${widget.studentName} (${widget.studentClass})",
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  Future<void> _fetchQuizzes() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('quizzes')
        .where('categoryId', isEqualTo: widget.category.id)
        .get();

    setState(() {
      _quizzes = snapshot.docs
          .map((doc) => Quiz.fromMap(doc.data(), id: doc.id))
          .toList();
      _loading = false;
    });
  }

  String _sanitizeId(String id) => id.replaceAll(RegExp(r'[.@]'), '_');

  Future<bool> _hasStudentCompletedQuiz(String quizId) async {
    final id = _studentId;
    if (id == null) return false;
    final docId = '${quizId}_${_sanitizeId(id)}';
    final doc = await FirebaseFirestore.instance
        .collection('quizResults')
        .doc(docId)
        .get();
    return doc.exists;
  }

  void _showStartDialog(Quiz quiz) async {
    final id = _studentId;
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be signed in to start an exam.'),
        ),
      );
      return;
    }

    final already = await _hasStudentCompletedQuiz(quiz.id);
    if (already) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You have already completed this exam."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final start = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Start Exam"),
        content: Text(
          "This exam has a time limit of ${quiz.timeLimit} minutes.\n"
          "${quiz.shuffleQuestions ? "Questions will be shuffled." : "Questions will appear in order."}\n"
          "${quiz.showResultsToStudent ? "Results will be shown immediately after." : "Results will only be available to the teacher."}\n\n"
          "Once you start this exam you cannot go back or restart it. Do you want to continue?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Start"),
          ),
        ],
      ),
    );

    if (start == true) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QuizQuestionScreen(
            quiz: quiz,
            studentId: id,
            studentName: widget.studentName,
            studentClass: widget.studentClass,
            shuffleQuestions: quiz.shuffleQuestions,
            showResultsToStudent: quiz.showResultsToStudent,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.name),
        backgroundColor: const Color(0xFF001F3F),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _quizzes.isEmpty
          ? const Center(child: Text("No quizzes found"))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: _quizzes.length,
              itemBuilder: (context, index) {
                final quiz = _quizzes[index];
                return FutureBuilder<bool>(
                  future: _hasStudentCompletedQuiz(quiz.id),
                  builder: (context, snapshot) {
                    final completed = snapshot.data ?? false;
                    return Card(
                      color: completed ? Colors.grey : Colors.blue.shade400,
                      child: InkWell(
                        onTap: completed ? null : () => _showStartDialog(quiz),
                        child: Center(
                          child: Text(
                            quiz.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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

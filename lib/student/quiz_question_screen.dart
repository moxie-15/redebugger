import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:redebugger/model/question.dart';
import 'package:redebugger/model/quiz.dart';
import 'package:redebugger/services/local_result_sync_manager.dart';
import 'submission_success_screen.dart'; // make sure this exists

class QuizQuestionScreen extends StatefulWidget {
  final Quiz quiz;
  final String studentId;
  final String studentName;
  final String studentClass;
  final bool? shuffleQuestions;
  final bool? showResultsToStudent;

  const QuizQuestionScreen({
    Key? key,
    required this.quiz,
    required this.studentId,
    required this.studentName,
    required this.studentClass,
    this.shuffleQuestions,
    this.showResultsToStudent,
  }) : super(key: key);

  @override
  State<QuizQuestionScreen> createState() => _QuizQuestionScreenState();
}

class _QuizQuestionScreenState extends State<QuizQuestionScreen> {
  late List<Question> _questions;
  late final bool _shuffleQuestions;
  late final bool _showResultsToStudent;

  int _currentIndex = 0;
  Map<int, String> _answers = {};
  int _remainingSeconds = 0;
  Timer? _timer;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();

    _shuffleQuestions = widget.shuffleQuestions ?? widget.quiz.shuffleQuestions;
    _showResultsToStudent =
        widget.showResultsToStudent ?? widget.quiz.showResultsToStudent;

    _questions = List<Question>.from(widget.quiz.questions);
    if (_shuffleQuestions) _questions.shuffle(Random());

    if (widget.quiz.timeLimit > 0) {
      _remainingSeconds = widget.quiz.timeLimit * 60;
      _startTimer();
    } else {
      throw Exception("⛔ Quiz time limit not set by admin in Firestore.");
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_remainingSeconds <= 0) {
          timer.cancel();
          _submitQuiz(auto: true);
        } else {
          _remainingSeconds--;
        }
      });
    });
  }

  String _formatTime(int seconds) {
    final min = (seconds ~/ 60).toString().padLeft(2, '0');
    final sec = (seconds % 60).toString().padLeft(2, '0');
    return "$min:$sec";
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() => _currentIndex++);
    } else {
      _showSubmitDialog();
    }
  }

  Future<void> _submitQuiz({bool auto = false}) async {
    if (_submitting) return;
    _submitting = true;
    _timer?.cancel();

    final resultId =
        '${widget.quiz.id}_${widget.studentId.replaceAll(RegExp(r'[.@]'), '_')}';

    int score = 0;
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      final ans = _answers[i];
      if (ans != null && q.correctOptionIndex < q.options.length) {
         if (ans == q.options[q.correctOptionIndex]) {
           score++;
         }
      }
    }

    try {
      final existing = await FirebaseFirestore.instance
          .collection('quizResults')
          .doc(resultId)
          .get();

      if (existing.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("You have already submitted this quiz."),
              backgroundColor: Colors.red,
            ),
          );
        }
        _submitting = false;
        return;
      }

      final payload = {
        "quizId": widget.quiz.id,
        "quizTitle": widget.quiz.title,
        "studentId": widget.studentId,
        "studentName": widget.studentName,
        "studentClass": widget.studentClass,
        "score": score,
        "totalQuestions": _questions.length,
        "answers": _answers.map(
          (key, value) => MapEntry(key.toString(), value),
        ),
        "questionsUsed": _questions
            .map((q) => {'text': q.text, 'options': q.options})
            .toList(),
        "completedAt": Timestamp.now(),
        "autoSubmitted": auto,
        "showResultsToStudent": _showResultsToStudent,
      };

      await FirebaseFirestore.instance
          .collection('quizResults')
          .doc(resultId)
          .set(payload);
    } catch (e) {
      // Offline fallback
      final payload = {
        "quizId": widget.quiz.id,
        "quizTitle": widget.quiz.title,
        "studentId": widget.studentId,
        "studentName": widget.studentName,
        "studentClass": widget.studentClass,
        "score": score,
        "totalQuestions": _questions.length,
        "answers": _answers.map(
          (key, value) => MapEntry(key.toString(), value),
        ),
        "questionsUsed": _questions
            .map((q) => {'text': q.text, 'options': q.options})
            .toList(),
        "autoSubmitted": auto,
        "showResultsToStudent": _showResultsToStudent,
      };
      await LocalResultSyncManager.queueResultOffline(payload, resultId);
      
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Offline Mode: Result saved securely to local device."), backgroundColor: Colors.orange));
      }
    }

    if (!mounted) return;

    // ✅ Navigate to SubmissionSuccessScreen and remove all previous routes
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => SubmissionSuccessScreen(
          studentName: widget.studentName,
          studentClass: widget.studentClass,
          score: score,
          totalQuestions: _questions.length,
          showResultsToStudent: _showResultsToStudent,
        ),
      ),
      (route) => false, // removes all previous routes
    );
  }

  void _showSubmitDialog() {
    _timer?.cancel();
    int dialogSeconds = 10;
    Timer? dialogTimer;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            dialogTimer ??= Timer.periodic(const Duration(seconds: 1), (t) {
              setStateDialog(() {
                if (dialogSeconds > 0) {
                  dialogSeconds--;
                } else {
                  t.cancel();
                  Navigator.of(context).pop();
                  _submitQuiz();
                }
              });
            });

            return AlertDialog(
              title: const Text("Submit Quiz"),
              content: Text(
                "Do you want to submit your answers?\n"
                "Auto-submitting in $dialogSeconds seconds...",
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    dialogTimer?.cancel();
                    _startTimer();
                    Navigator.of(context).pop();
                  },
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    dialogTimer?.cancel();
                    Navigator.of(context).pop();
                    _submitQuiz();
                  },
                  child: const Text("Submit Now"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Color _getTimerColor() {
    double fraction = _remainingSeconds / (widget.quiz.timeLimit * 60);
    if (fraction > 0.5) return Colors.green;
    if (fraction > 0.25) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final question = _questions[_currentIndex];
    double progress = _remainingSeconds / (widget.quiz.timeLimit * 60);

    return WillPopScope(
      onWillPop: () async => false, // disables back button
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.quiz.title),
          backgroundColor: const Color(0xFF001F3F),
          automaticallyImplyLeading: false,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timer
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer, color: Colors.blueAccent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey.shade300,
                        color: _getTimerColor(),
                        minHeight: 10,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _formatTime(_remainingSeconds),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Text(
                "Question ${_currentIndex + 1} of ${_questions.length}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(question.text, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 20),

              ...question.options.map((option) {
                final selected = _answers[_currentIndex] == option;
                return RadioListTile<String>(
                  title: Text(option),
                  value: option,
                  groupValue: _answers[_currentIndex],
                  onChanged: (val) {
                    setState(() {
                      _answers[_currentIndex] = val!;
                    });
                  },
                  selected: selected,
                );
              }),

              const Spacer(),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentIndex > 0)
                    ElevatedButton(
                      onPressed: () => setState(() => _currentIndex--),
                      child: const Text("Previous"),
                    ),
                  ElevatedButton(
                    onPressed: _answers[_currentIndex] != null
                        ? _nextQuestion
                        : null,
                    style: _currentIndex == _questions.length - 1
                        ? ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          )
                        : null,
                    child: Text(
                      _currentIndex == _questions.length - 1
                          ? "Submit"
                          : "Next",
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

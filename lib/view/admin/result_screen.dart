import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:redebugger/model/quiz.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';

class ResultScreen extends StatefulWidget {
  final Quiz quiz;
  const ResultScreen({super.key, required this.quiz});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _results = [];

  @override
  void initState() {
    super.initState();
    _fetchResults();
  }

  Future<void> _fetchResults() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('quizResults')
          .where('quizId', isEqualTo: widget.quiz.id)
          .get();

      setState(() {
        _results = snapshot.docs.map((doc) => doc.data()).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error loading results: $e")));
    }
  }

  int _calculateScore(Map<String, dynamic> studentData) {
    if (studentData['score'] != null) {
      return studentData['score'] as int;
    }
    final answers = Map<String, dynamic>.from(studentData['answers'] ?? {});
    int score = 0;
    answers.forEach((key, value) {
      final qIndex = int.tryParse(key) ?? -1;
      if (qIndex >= 0 && qIndex < widget.quiz.questions.length) {
        final q = widget.quiz.questions[qIndex];
        if (q.options.isNotEmpty && q.correctOptionIndex < q.options.length) {
          if (q.options[q.correctOptionIndex] == value) score++;
        }
      }
    });
    return score;
  }

  Future<void> _exportToCSV() async {
    if (_results.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No results to export")));
      return;
    }

    List<List<dynamic>> rows = [];

    // Header
    List<String> header = ['Student Email', 'Student UID'];
    for (int i = 0; i < widget.quiz.questions.length; i++) {
      header.add('Q${i + 1}');
    }
    header.add('Score');
    rows.add(header);

    // Data
    for (var student in _results) {
      List<dynamic> row = [];
      row.add(student['studentName'] ?? student['studentEmail'] ?? 'Unknown');
      row.add(student['studentClass'] ?? 'Unknown Class');
      final answers = Map<String, dynamic>.from(student['answers'] ?? {});
      int score = 0;

      for (int i = 0; i < widget.quiz.questions.length; i++) {
        final ans = answers[i.toString()] ?? 'Not answered';
        row.add(ans);
        final q = widget.quiz.questions[i];
        if (q.options.isNotEmpty && q.correctOptionIndex < q.options.length) {
           if (q.options[q.correctOptionIndex] == ans) score++;
        }
      }
      row.add(score);
      rows.add(row);
    }

    String csv = const ListToCsvConverter().convert(rows);
    final bytes = Uint8List.fromList(csv.codeUnits);

    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = "${directory.path}/${widget.quiz.title}_results.csv";
      final file = File(path);
      await file.writeAsBytes(bytes);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("CSV saved successfully at $path")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("CSV export failed: $e")));
    }
  }

  void _showStudentAnswers(Map<String, dynamic> studentData) {
    final answers = Map<String, dynamic>.from(studentData['answers'] ?? {});
    int wrong = 0;
    int correct = 0;

    for (int i = 0; i < widget.quiz.questions.length; i++) {
      final question = widget.quiz.questions[i];
      final ans = answers[i.toString()] ?? 'Not answered';
      final correctAns = question.options.isNotEmpty && question.correctOptionIndex < question.options.length 
        ? question.options[question.correctOptionIndex] 
        : 'Unknown';
      if (ans.toString().trim() == correctAns.toString().trim()) {
        correct++;
      } else {
        wrong++;
      }
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("${studentData['studentName'] ?? studentData['studentEmail'] ?? 'Student'} - Answers"),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('No.', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Question', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Selected Answer', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Correct Answer', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: List<DataRow>.generate(
                  widget.quiz.questions.length,
                  (index) {
                    final question = widget.quiz.questions[index];
                    final ans = answers[index.toString()] ?? 'Not answered';
                    final correctAns = question.options.isNotEmpty && question.correctOptionIndex < question.options.length 
                      ? question.options[question.correctOptionIndex] 
                      : 'Unknown';
                    final isCorrect = ans.toString().trim() == correctAns.toString().trim();

                    return DataRow(
                      cells: [
                        DataCell(Text('${index + 1}')),
                        DataCell(Text(question.text.length > 30 ? '${question.text.substring(0, 30)}...' : question.text)),
                        DataCell(Text(ans.toString())),
                        DataCell(Text(correctAns.toString())),
                        DataCell(Icon(isCorrect ? Icons.check_circle : Icons.cancel, color: isCorrect ? Colors.green : Colors.red)),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text("Total: $correct Correct, $wrong Wrong", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.quiz.title} - Results"),
        backgroundColor: const Color(0xFF001F3F),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: "Export to CSV",
            onPressed: _exportToCSV,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _results.isEmpty
          ? const Center(child: Text("No submissions yet"))
          : ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final student = _results[index];
                final score = _calculateScore(student);

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    title: Text(
                      student['studentName'] ?? student['studentEmail'] ?? 'Unknown Student',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "Class: ${student['studentClass'] ?? 'Unknown'}  |  Score: $score / ${widget.quiz.questions.length}",
                    ),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () => _showStudentAnswers(student),
                  ),
                );
              },
            ),
    );
  }
}

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:redebugger/theme/theme.dart';

class TeacherGradesExportScreen extends StatefulWidget {
  const TeacherGradesExportScreen({super.key});

  @override
  State<TeacherGradesExportScreen> createState() => _TeacherGradesExportScreenState();
}

class _TeacherGradesExportScreenState extends State<TeacherGradesExportScreen> {
  bool _isExporting = false;

  Future<void> _exportGrades() async {
    setState(() => _isExporting = true);
    
    try {
      // 1. Fetch all quiz results
      final query = await FirebaseFirestore.instance.collection('quizResults').get();
      
      if (query.docs.isEmpty) {
        throw Exception("There are no student results recorded in the database yet.");
      }

      // 2. Prepare Spreadsheet Rows (Header)
      List<List<dynamic>> rows = [
        ["Exam Title", "Student Name", "Student Class", "Score", "Total Questions", "Completion Time", "Date Taken"]
      ];

      // 3. Map Firestore data into Csv Rows
      for (var doc in query.docs) {
        final data = doc.data();
        rows.add([
          data['quizTitle'] ?? 'Unknown Exam',
          data['studentName'] ?? 'Unknown Student',
          data['studentClass'] ?? 'Unknown Class',
          data['score'] ?? 0,
          data['totalQuestions'] ?? 0,
          data['timeTaken'] ?? 'Unknown',
          data['dateTaken'] != null ? (data['dateTaken'] as Timestamp).toDate().toString() : 'Unknown Date',
        ]);
      }

      // 4. Convert to CSV stringent format
      String csvData = const ListToCsvConverter().convert(rows);

      // 5. Trigger Native Desktop Download / Save securely via OS handles
      final dir = await getApplicationDocumentsDirectory();
      final String safeDate = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      final file = File('${dir.path}/Student_Grades_$safeDate.csv');
      await file.writeAsString(csvData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Export Successful! CSV saved to Documents > Student_Grades_$safeDate.csv"), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Export failed: ${e.toString()}"), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Export Grades (Spreadsheet)")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.table_view_rounded, size: 80, color: AppTheme.primaryColor),
              const SizedBox(height: 24),
              const Text(
                 "Generate Offline Spreadsheet", 
                 style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 16),
              const Text(
                "Clicking this button will securely compile all student scores across all exams into an Excel-ready CSV file and save it directly to your computer.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              _isExporting
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      backgroundColor: AppTheme.successColor,
                    ),
                    onPressed: _exportGrades,
                    icon: const Icon(Icons.download, color: Colors.white),
                    label: const Text("Export All Grades (CSV)", style: TextStyle(color: Colors.white, fontSize: 18)),
                  )
            ],
          ),
        ),
      ),
    );
  }
}

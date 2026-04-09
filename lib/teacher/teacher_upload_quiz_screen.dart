import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:redebugger/model/category.dart';
import 'package:redebugger/model/quiz.dart';
import 'package:redebugger/services/file_parser_service.dart';
import 'package:redebugger/theme/theme.dart';

class TeacherUploadQuizScreen extends StatefulWidget {
  const TeacherUploadQuizScreen({super.key});

  @override
  State<TeacherUploadQuizScreen> createState() => _TeacherUploadQuizScreenState();
}

class _TeacherUploadQuizScreenState extends State<TeacherUploadQuizScreen> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  Category? _selectedCategory;
  int _timeLimit = 30;
  bool _isTermExam = false; // Maps to !showResultsToStudent

  File? _selectedFile;
  bool _isLoading = false;
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    final query = await FirebaseFirestore.instance.collection('categories').get();
    setState(() {
      _categories = query.docs.map((d) => Category.fromMap(d.data(), id: d.id)).toList();
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _uploadQuiz() async {
    if (!_formKey.currentState!.validate() || _selectedCategory == null || _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ensure all fields and a file are selected.")));
      return;
    }
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      // 1. Offload extraction to FileParserService
      final String rawText = await FileParserService.extractText(_selectedFile!);
      
      // 2. Parse into exact Models
      final parsedQuestions = FileParserService.parseQuestionsFromText(rawText);

      // 3. Assemble the Quiz Model
      final newQuizId = FirebaseFirestore.instance.collection('quizzes').doc().id;
      final quiz = Quiz(
        id: newQuizId,
        title: _title,
        categoryId: _selectedCategory!.id,
        categoryName: _selectedCategory!.name,
        timeLimit: _timeLimit,
        questions: parsedQuestions,
        shuffleQuestions: true,
        showResultsToStudent: !_isTermExam, // Term Exams block Student Results!
        showResultsImmediately: !_isTermExam,
      );

      // 4. Send to Firebase
      await FirebaseFirestore.instance.collection('quizzes').doc(newQuizId).set(quiz.toMap(isNew: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Success! Cleanly imported ${parsedQuestions.length} questions."), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Parsing Error: ${e.toString()}"), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload Document Quiz"), backgroundColor: AppTheme.primaryColor),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   Card(
                     elevation: 2,
                     child: Padding(
                       padding: const EdgeInsets.all(16.0),
                       child: Column(
                         children: [
                           const Icon(Icons.info_outline, color: Colors.blue),
                           const SizedBox(height: 8),
                           const Text("Ensure your document strictly uses this format:\nQ1. Question text\nA) Option A\nB) Option B\nC) Option C\nD) Option D\nANS: B", textAlign: TextAlign.center),
                         ],
                       ),
                     ),
                   ),
                   const SizedBox(height: 20),
                   TextFormField(
                     decoration: const InputDecoration(labelText: "Exam Title", border: OutlineInputBorder()),
                     validator: (v) => v!.isEmpty ? "Required" : null,
                     onSaved: (v) => _title = v!,
                   ),
                   const SizedBox(height: 16),
                   DropdownButtonFormField<Category>(
                     decoration: const InputDecoration(labelText: "Subject / Category", border: OutlineInputBorder()),
                     initialValue: _selectedCategory,
                     items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                     onChanged: (v) => setState(() => _selectedCategory = v),
                   ),
                   const SizedBox(height: 16),
                   TextFormField(
                     decoration: const InputDecoration(labelText: "Time Limit (Minutes)", border: OutlineInputBorder()),
                     initialValue: "30",
                     keyboardType: TextInputType.number,
                     onSaved: (v) => _timeLimit = int.tryParse(v!) ?? 30,
                   ),
                   const SizedBox(height: 16),
                   SwitchListTile(
                     title: const Text("Is this a Term Exam?"),
                     subtitle: const Text("If true, students will NOT see their scores after submitting."),
                     value: _isTermExam,
                     onChanged: (val) => setState(() => _isTermExam = val),
                   ),
                   const SizedBox(height: 20),
                   OutlinedButton.icon(
                     icon: const Icon(Icons.attach_file),
                     label: Text(_selectedFile == null ? "Select Word (.docx) or PDF" : _selectedFile!.path.split(Platform.pathSeparator).last),
                     onPressed: _pickFile,
                     style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
                   ),
                   const SizedBox(height: 30),
                   ElevatedButton(
                     onPressed: _uploadQuiz,
                     style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, padding: const EdgeInsets.all(16)),
                     child: const Text("Extract & Upload Exam", style: TextStyle(fontSize: 16, color: Colors.white)),
                   )
                ],
              ),
            ),
          ),
    );
  }
}

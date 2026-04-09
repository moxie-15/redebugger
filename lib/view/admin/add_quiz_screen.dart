import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:redebugger/model/quiz.dart';
import 'package:redebugger/theme/theme.dart';

class AddQuizScreen extends StatefulWidget {
  final String? categoryId;
  final String? categoryName;
  final Quiz? quiz;

  const AddQuizScreen({Key? key, this.categoryId, this.categoryName, this.quiz})
    : super(key: key);

  @override
  State<AddQuizScreen> createState() => _AddQuizScreenState();
}

class QuestionFormItem {
  final TextEditingController questionController;
  final List<TextEditingController> optionsController;
  int correctOptionIndex;

  QuestionFormItem({
    required this.questionController,
    required this.optionsController,
    required this.correctOptionIndex,
  });

  void dispose() {
    questionController.dispose();
    for (var c in optionsController) c.dispose();
  }
}

class _AddQuizScreenState extends State<AddQuizScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _timeLimitController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  late bool _isEditing;
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  final List<QuestionFormItem> _questionsItems = [];

  List<Map<String, dynamic>> _categories = [];

  // 🔑 New settings toggles
  bool _shuffleQuestions = false;
  bool _showResultsImmediately = true;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.quiz != null;
    _selectedCategoryId = widget.categoryId ?? widget.quiz?.categoryId;
    _selectedCategoryName = widget.categoryName ?? widget.quiz?.categoryName;
    _fetchCategories();

    if (_isEditing && widget.quiz != null) {
      _populateFromQuiz(widget.quiz!);
    } else {
      _addQuestion();
    }
  }

  Future<void> _fetchCategories() async {
    final snapshot = await _firestore.collection('categories').get();
    setState(() {
      _categories = snapshot.docs
          .map((doc) => {'id': doc.id, 'name': doc['name'] ?? 'Unknown'})
          .toList();
    });
  }

  void _populateFromQuiz(Quiz quiz) {
    _titleController.text = quiz.title;
    _timeLimitController.text = quiz.timeLimit.toString();
    _selectedCategoryId = quiz.categoryId;
    _selectedCategoryName = quiz.categoryName;

    // restore toggles if they exist
    _shuffleQuestions = quiz.shuffleQuestions ?? false;
    _showResultsImmediately = quiz.showResultsImmediately ?? true;

    _questionsItems.clear();
    for (var q in quiz.questions) {
      final optsCtrls = List.generate(
        max(q.options.length, 4),
        (i) => TextEditingController(
          text: i < q.options.length ? q.options[i] : '',
        ),
      );
      _questionsItems.add(
        QuestionFormItem(
          questionController: TextEditingController(text: q.text),
          optionsController: optsCtrls,
          correctOptionIndex: q.correctOptionIndex,
        ),
      );
    }
    setState(() {});
  }

  @override
  void dispose() {
    _titleController.dispose();
    _timeLimitController.dispose();
    for (var item in _questionsItems) item.dispose();
    super.dispose();
  }

  void _addQuestion() {
    setState(() {
      _questionsItems.add(
        QuestionFormItem(
          questionController: TextEditingController(),
          optionsController: List.generate(4, (_) => TextEditingController()),
          correctOptionIndex: 0,
        ),
      );
    });
  }

  void _removeQuestion(int idx) {
    if (idx < 0 || idx >= _questionsItems.length) return;
    setState(() {
      _questionsItems[idx].dispose();
      _questionsItems.removeAt(idx);
    });
  }

  Future<void> _saveQuiz() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final questionsData = _questionsItems.map((item) {
        final options = item.optionsController
            .map((c) => c.text.trim())
            .where((t) => t.isNotEmpty)
            .toList();
        return {
          'text': item.questionController.text.trim(),
          'options': options,
          'correctOptionIndex': item.correctOptionIndex >= options.length
              ? 0
              : item.correctOptionIndex,
        };
      }).toList();

      final quizData = {
        'title': _titleController.text.trim(),
        'timeLimit': int.tryParse(_timeLimitController.text.trim()) ?? 0,
        'categoryId': _selectedCategoryId,
        'categoryName': _selectedCategoryName ?? 'Unknown',
        'questions': questionsData,
        'shuffleQuestions': _shuffleQuestions,
        'showResultsImmediately': _showResultsImmediately,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_isEditing && widget.quiz != null) {
        await _firestore
            .collection('quizzes')
            .doc(widget.quiz!.id)
            .update(quizData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quiz updated successfully')),
        );
      } else {
        final docRef = _firestore.collection('quizzes').doc();
        await docRef.set({
          'id': docRef.id,
          ...quizData,
          'createdAt': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quiz created successfully')),
        );
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save quiz: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildQuestionCard(int index, QuestionFormItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            TextFormField(
              controller: item.questionController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.question_answer),
                labelText: 'Question ${index + 1}',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter question' : null,
            ),
            const SizedBox(height: 12),
            ...item.optionsController.asMap().entries.map((entry) {
              final optIndex = entry.key;
              final optCtrl = entry.value;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Radio<int>(
                    value: optIndex,
                    groupValue: item.correctOptionIndex,
                    onChanged: (val) {
                      setState(() {
                        item.correctOptionIndex = val ?? 0;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: optCtrl,
                      decoration: InputDecoration(
                        labelText: 'Option ${optIndex + 1}',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter option'
                          : null,
                    ),
                  ),
                ],
              );
            }).toList(),
            if (_questionsItems.length > 1) const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _removeQuestion(index),
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text(
                  'Remove Question',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Quiz' : 'Add Quiz'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveQuiz,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(40, 8, 40, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEditing ? 'Edit Quiz Details' : 'Quiz Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.text_fields),
                        labelText: 'Quiz Title',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter quiz title'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _timeLimitController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.timer),
                        labelText: 'Time Limit (mins)',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter time limit'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategoryId,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.category),
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories
                          .map(
                            (cat) => DropdownMenuItem<String>(
                              value: cat['id'],
                              child: Text(cat['name']),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedCategoryId = val;
                          _selectedCategoryName = _categories.firstWhere(
                            (c) => c['id'] == val,
                          )['name'];
                        });
                      },
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Select category' : null,
                    ),
                    const SizedBox(height: 20),

                    // 🔑 New switches
                    SwitchListTile(
                      title: const Text("Shuffle Questions"),
                      value: _shuffleQuestions,
                      onChanged: (val) =>
                          setState(() => _shuffleQuestions = val),
                    ),
                    SwitchListTile(
                      title: const Text("Show Results Immediately"),
                      subtitle: const Text(
                        "If off, only teacher/admin can view results",
                      ),
                      value: _showResultsImmediately,
                      onChanged: (val) =>
                          setState(() => _showResultsImmediately = val),
                    ),

                    const SizedBox(height: 20),
                    ..._questionsItems.asMap().entries.map(
                      (e) => _buildQuestionCard(e.key, e.value),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _addQuestion,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Question'),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveQuiz,
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : Text(_isEditing ? 'Update Quiz' : 'Save Quiz'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}

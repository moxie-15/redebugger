import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:redebugger/model/assessment.dart';
import 'package:redebugger/theme/theme.dart';

class AddAssessmentScreen extends StatefulWidget {
  final String? classId;
  final String? className;
  final Assessment? assessment;

  const AddAssessmentScreen({Key? key, this.classId, this.className, this.assessment})
    : super(key: key);

  @override
  State<AddAssessmentScreen> createState() => _AddAssessmentScreenState();
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

class _AddAssessmentScreenState extends State<AddAssessmentScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _timeLimitController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  late bool _isEditing;
  String? _selectedClassId;
  String? _selectedClassName;
  final List<QuestionFormItem> _questionsItems = [];

  List<Map<String, dynamic>> _classes = [];

  String _assessmentType = 'test'; // test or exam
  String _releaseMode = 'manual'; // manual or scheduled
  DateTime? _releaseDate;
  bool _shuffleQuestions = true;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.assessment != null;
    _selectedClassId = widget.classId ?? widget.assessment?.classId;
    _selectedClassName = widget.className ?? widget.assessment?.className;
    _fetchClasses();

    if (_isEditing && widget.assessment != null) {
      _populateFromAssessment(widget.assessment!);
    } else {
      _addQuestion();
    }
  }

  Future<void> _fetchClasses() async {
    final snapshot = await _firestore.collection('classes').get();
    setState(() {
      _classes = snapshot.docs
          .map((doc) => {'id': doc.id, 'name': doc['name'] ?? 'Unknown'})
          .toList();
    });
  }

  void _populateFromAssessment(Assessment assessment) {
    _titleController.text = assessment.title;
    _timeLimitController.text = assessment.durationMinutes.toString();
    _selectedClassId = assessment.classId;
    _selectedClassName = assessment.className;
    _assessmentType = assessment.type;
    _releaseMode = assessment.releaseMode;
    _releaseDate = assessment.releaseDate;
    _shuffleQuestions = assessment.shuffleQuestions;

    _questionsItems.clear();
    for (var q in assessment.questions) {
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

  Future<void> _pickReleaseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _releaseDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _releaseDate = picked);
    }
  }

  Future<void> _saveAssessment() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedClassId == null || _selectedClassId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a class')));
      return;
    }

    if (_releaseMode == 'scheduled' && _releaseDate == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a release date for scheduled releases.')));
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

      final assessmentData = {
        'title': _titleController.text.trim(),
        'durationMinutes': int.tryParse(_timeLimitController.text.trim()) ?? 0,
        'classId': _selectedClassId,
        'className': _selectedClassName ?? 'Unknown',
        'type': _assessmentType,
        'releaseMode': _releaseMode,
        'releaseDate': _releaseDate != null ? Timestamp.fromDate(_releaseDate!) : null,
        'isResultReleased': false,
        'questions': questionsData,
        'shuffleQuestions': _shuffleQuestions,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_isEditing && widget.assessment != null) {
        await _firestore
            .collection('assessments')
            .doc(widget.assessment!.id)
            .update(assessmentData);
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Assessment updated successfully')));
      } else {
        final docRef = _firestore.collection('assessments').doc();
        await docRef.set({
          'id': docRef.id,
          ...assessmentData,
          'createdAt': FieldValue.serverTimestamp(),
        });
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Assessment created successfully')));
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save assessment: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildQuestionCard(int index, QuestionFormItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          children: [
            TextFormField(
              controller: item.questionController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.question_answer),
                labelText: 'Question ${index + 1}',
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter question' : null,
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
                        labelText: 'Option ${String.fromCharCode(65 + optIndex)}',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter option' : null,
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
                label: const Text('Remove Question', style: TextStyle(color: Colors.red)),
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
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Assessment' : 'Create Assessment'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveAssessment,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Assessment Configurations", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(prefixIcon: Icon(Icons.text_fields), labelText: 'Assessment Title'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter title' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _timeLimitController,
                            decoration: const InputDecoration(prefixIcon: Icon(Icons.timer), labelText: 'Duration (mins)'),
                            keyboardType: TextInputType.number,
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter duration' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedClassId,
                            decoration: const InputDecoration(prefixIcon: Icon(Icons.class_), labelText: 'Target Class', border: OutlineInputBorder()),
                            items: _classes.map((cat) => DropdownMenuItem<String>(value: cat['id'], child: Text(cat['name']))).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedClassId = val;
                                _selectedClassName = _classes.firstWhere((c) => c['id'] == val)['name'];
                              });
                            },
                            validator: (v) => (v == null || v.isEmpty) ? 'Select class' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _assessmentType,
                            decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                            items: const [
                              DropdownMenuItem(value: 'test', child: Text("Test (Midterm/Short)")),
                              DropdownMenuItem(value: 'exam', child: Text("Exam (Final/Long)")),
                            ],
                            onChanged: (val) => setState(() => _assessmentType = val!),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _releaseMode,
                            decoration: const InputDecoration(labelText: 'Result Release Mode', border: OutlineInputBorder()),
                            items: const [
                              DropdownMenuItem(value: 'manual', child: Text("Manual (Teacher Action)")),
                              DropdownMenuItem(value: 'scheduled', child: Text("Scheduled Date")),
                            ],
                            onChanged: (val) => setState(() => _releaseMode = val!),
                          ),
                        ),
                      ],
                    ),
                    if (_releaseMode == 'scheduled') ...[
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(_releaseDate == null ? "Select Release Date" : "Releases on: ${_releaseDate!.toLocal().toString().split(' ')[0]}"),
                        trailing: ElevatedButton(onPressed: _pickReleaseDate, child: const Text("Pick Date")),
                      ),
                    ],
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Shuffle Questions"),
                      value: _shuffleQuestions,
                      onChanged: (val) => setState(() => _shuffleQuestions = val),
                    ),
                    const Divider(height: 40),
                    Text("Questions Setup", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    ..._questionsItems.asMap().entries.map((e) => _buildQuestionCard(e.key, e.value)),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _addQuestion,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Question'),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveAssessment,
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(_isEditing ? 'Update Assessment' : 'Save Assessment', style: const TextStyle(color: Colors.white, fontSize: 16)),
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

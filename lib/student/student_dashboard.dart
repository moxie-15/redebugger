import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:redebugger/model/category.dart';
import 'package:redebugger/student/quiz_grid_screen.dart';
import 'package:redebugger/student/quiz_question_screen.dart';
import 'package:redebugger/services/aloc_quiz_service.dart';

class StudentDashboard extends StatefulWidget {
  final String studentName;
  final String studentClass;

  const StudentDashboard({
    super.key,
    required this.studentName,
    required this.studentClass,
  });

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final TextEditingController _searchController = TextEditingController();
  List<Category> _allCategories = [];
  List<Category> _filteredCategories = [];
  List<String> _categories = ['All'];
  String _selectedFilter = "All";

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('categories')
        .orderBy('createdAt', descending: true)
        .get();

    if (!mounted) return;

    final List<Category> fetched = snapshot.docs
        .map((doc) => Category.fromMap(doc.data(), id: doc.id))
        .toList();

    // Inject ALOC National Exams Category (Free Offline/Online Engine)
    fetched.insert(
      0,
      Category(
        id: 'aloc_national',
        name: 'National Standardized Exams (WAEC/JAMB/NECO)',
        description: 'Take dynamic past questions pulled from National syllabus (Offers Offline Mode)',
        createdAt: DateTime.now(),
      ),
    );

    setState(() {
      _allCategories = fetched;
      _filteredCategories = _allCategories;

      _categories = ['All'];
      _categories.addAll(
        _allCategories.map((cat) => cat.name).toSet().toList(),
      );
    });
  }

  void _filterCategories(String query, String categoryFilter) {
    if (!mounted) return;
    setState(() {
      _filteredCategories = _allCategories.where((cat) {
        final matchesQuery =
            cat.name.toLowerCase().contains(query.toLowerCase()) ||
            cat.description.toLowerCase().contains(query.toLowerCase());
        final matchesCategory =
            categoryFilter == "All" || cat.name == categoryFilter;
        return matchesQuery && matchesCategory;
      }).toList();
    });
  }

  void _openQuizzes(Category category) async {
    if (category.id == 'aloc_national') {
      _startAlocExam();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizGridScreen(
          category: category,
          studentName: widget.studentName,
          studentClass: widget.studentClass,
        ),
      ),
    );
  }

  void _startAlocExam() {
    showDialog(
      context: context,
      builder: (ctx) {
        String subject = 'english';
        bool loading = false;
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              title: const Text("Select Subject"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Choose a Nigerian Curriculum Subject to take a 10-question mock exam. This engine works offline if downloaded once!"),
                  const SizedBox(height: 20),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: subject,
                    items: ['english', 'mathematics', 'physics', 'chemistry', 'biology']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase())))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => subject = val);
                    },
                  ),
                  if (loading) const Padding(padding: EdgeInsets.only(top:20), child: CircularProgressIndicator())
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: loading ? null : () async {
                    setDialogState(() => loading = true);
                    try {
                      final quiz = await AlocQuizService.fetchQuiz(subject);
                      if (context.mounted) {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => QuizQuestionScreen(
                              quiz: quiz,
                              studentId: widget.studentName,
                              studentName: widget.studentName,
                              studentClass: widget.studentClass,
                              shuffleQuestions: quiz.shuffleQuestions,
                              showResultsToStudent: quiz.showResultsToStudent,
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      setDialogState(() => loading = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
                      }
                    }
                  },
                  child: const Text("Start Exam"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Take a Quiz",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF020268),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(40, 20, 40, 0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Categories',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) =>
                  _filterCategories(_searchController.text, _selectedFilter),
            ),
            const SizedBox(height: 10),
            DropdownButton<String>(
              isExpanded: true,
              value: _selectedFilter,
              items: _categories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue == null) return;
                setState(() {
                  _selectedFilter = newValue;
                  _filterCategories(_searchController.text, _selectedFilter);
                });
              },
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _filteredCategories.isEmpty
                  ? const Center(child: Text('No categories found'))
                  : ListView.builder(
                      itemCount: _filteredCategories.length,
                      itemBuilder: (context, index) {
                        final category = _filteredCategories[index];
                        final isAloc = category.id == 'aloc_national';
                        return Card(
                          color: isAloc ? Colors.blue.shade50 : Theme.of(context).cardColor,
                          elevation: isAloc ? 4 : 1,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: isAloc 
                              ? const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.public, color: Colors.white)) 
                              : const CircleAvatar(backgroundColor: Colors.grey, child: Icon(Icons.folder, color: Colors.white)),
                            title: Text(category.name, style: TextStyle(fontWeight: isAloc ? FontWeight.bold : FontWeight.normal)),
                            subtitle: Text(category.description),
                            trailing: const Icon(Icons.arrow_forward),
                            onTap: () => _openQuizzes(category),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

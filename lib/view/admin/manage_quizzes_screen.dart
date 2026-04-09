import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:redebugger/model/category.dart';
import 'package:redebugger/model/quiz.dart';
import 'package:redebugger/theme/theme.dart';
import 'package:redebugger/view/admin/add_quiz_screen.dart';

class ManageQuizzesScreen extends StatefulWidget {
  final String? categoryId;
  final String? categoryName;

  const ManageQuizzesScreen({super.key, this.categoryId, this.categoryName});

  @override
  State<ManageQuizzesScreen> createState() => _ManageQuizzesScreenState();
}

class _ManageQuizzesScreenState extends State<ManageQuizzesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String? _selectedCategoryId;

  // Map of categoryId -> Category for live updates
  Map<String, Category> _categoryMap = {};

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.categoryId;
    _listenCategories();
  }

  // Live listen to categories
  void _listenCategories() {
    _firestore.collection('categories').snapshots().listen((snapshot) {
      final map = <String, Category>{};
      for (var doc in snapshot.docs) {
        final cat = Category.fromMap(
          doc.data(),
          id: doc.id,
        );
        map[cat.id] = cat;
      }
      setState(() {
        _categoryMap = map;
      });
    });
  }

  Stream<QuerySnapshot> _getQuizStream() {
    Query query = _firestore.collection("quizzes");
    final filterCategoryId = _selectedCategoryId;

    if (filterCategoryId != null) {
      query = query.where("categoryId", isEqualTo: filterCategoryId);
    }

    return query.snapshots();
  }

  Widget _builderTitle() {
    if (_selectedCategoryId == null)
      return const Text(
        'All Quizzes',
        style: TextStyle(fontWeight: FontWeight.bold),
      );

    final category = _categoryMap[_selectedCategoryId!];
    return Text(
      category?.name ?? 'Loading...',
      style: const TextStyle(fontWeight: FontWeight.bold),
    );
  }

  void _openAddQuizScreen({Quiz? quiz}) {
    final categoryId = _selectedCategoryId;
    final categoryName = categoryId != null
        ? _categoryMap[categoryId]?.name ?? 'Unknown'
        : 'Unknown';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddQuizScreen(
          categoryId: categoryId,
          categoryName: categoryName,
          quiz: quiz,
        ),
      ),
    ).then((value) {
      // Refresh after adding/editing
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _builderTitle(),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            onPressed: () => _openAddQuizScreen(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 20, 40, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                fillColor: Colors.white,
                filled: true,
                hintText: 'Search Quizzes',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 12, 40, 0),
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                fillColor: Colors.white,
                filled: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 15,
                ),
                border: OutlineInputBorder(),
                hintText: 'Select Category',
                prefixIcon: Icon(Icons.category),
              ),
              initialValue: _selectedCategoryId,
              items: _categoryMap.values.map((cat) {
                return DropdownMenuItem(value: cat.id, child: Text(cat.name));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategoryId = value;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getQuizStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError)
                  return const Center(child: Text('Error loading quizzes'));
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                final quizzes = snapshot.data!.docs
                    .map(
                      (doc) => Quiz.fromMap(
                        doc.data() as Map<String, dynamic>,
                        id: doc.id,
                      ),
                    )
                    .where(
                      (quiz) =>
                          _searchQuery.isEmpty ||
                          quiz.title.toLowerCase().contains(_searchQuery),
                    )
                    .toList();

                if (quizzes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.quiz_outlined, size: 70),
                        const SizedBox(height: 10),
                        const Text("No quizzes found"),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => _openAddQuizScreen(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.buttonColor,
                          ),
                          child: const Text('Add Quiz'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  itemCount: quizzes.length,
                  itemBuilder: (context, index) {
                    final quiz = quizzes[index];
                    final categoryName =
                        _categoryMap[quiz.categoryId]?.name ?? 'Unknown';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.quiz_outlined,
                            color: AppTheme.buttonColor,
                          ),
                        ),
                        title: Text(
                          quiz.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.category, size: 16),
                                const SizedBox(width: 4),
                                Text(categoryName),
                                const SizedBox(width: 16),
                                const Icon(
                                  Icons.question_answer_outlined,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text("${quiz.questions.length} questions"),
                                const SizedBox(width: 16),
                                const Icon(Icons.timer_outlined, size: 16),
                                const SizedBox(width: 4),
                                Text("${quiz.timeLimit} mins"),
                              ],
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  Icons.edit,
                                  color: AppTheme.buttonColor,
                                ),
                                title: const Text('Edit'),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                title: const Text('Delete'),
                              ),
                            ),
                          ],
                          onSelected: (value) => _handleQuizAction(value, quiz),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleQuizAction(String action, Quiz quiz) async {
    if (action == 'edit') {
      _openAddQuizScreen(quiz: quiz);
    } else if (action == 'delete') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Delete Quiz"),
          content: const Text("Are you sure you want to delete this quiz?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      if (confirm == true) {
        await _firestore.collection("quizzes").doc(quiz.id).delete();
      }
    }
  }
}

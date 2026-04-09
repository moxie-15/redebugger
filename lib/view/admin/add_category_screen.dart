import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:redebugger/model/category.dart';
import 'package:redebugger/theme/theme.dart';

class AddCategoryScreen extends StatefulWidget {
  final Category? category; // null => add new, else edit
  const AddCategoryScreen({super.key, this.category});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? "");
    _descriptionController = TextEditingController(
      text: widget.category?.description ?? "",
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();

      if (widget.category == null) {
        // Create new category
        final docRef = _firestore.collection("categories").doc();
        final newCategory = Category(
          id: docRef.id,
          name: name,
          description: description,
          createdAt: DateTime.now(),
        );

        await docRef.set(newCategory.toMap(isNew: true));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ Category added successfully")),
          );
        }
      } else {
        // Update existing category
        final updatedCategory = Category(
          id: widget.category!.id,
          name: name,
          description: description,
          createdAt: widget.category?.createdAt,
          updatedAt: DateTime.now(),
        );

        await _firestore
            .collection("categories")
            .doc(widget.category!.id)
            .update(updatedCategory.toMap());

        // Run linked quizzes update in background to avoid UI freeze
        _updateLinkedQuizzes(widget.category!.id, name);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ Category updated successfully")),
          );
        }
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e, st) {
      debugPrint("❌ Error saving category: $e\n$st");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Failed to save category")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Update quizzes linked to a category (non-blocking)
  Future<void> _updateLinkedQuizzes(String categoryId, String newName) async {
    try {
      final quizzesSnapshot = await _firestore
          .collection('quizzes')
          .where('categoryId', isEqualTo: categoryId)
          .get();

      if (quizzesSnapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (var doc in quizzesSnapshot.docs) {
        batch.update(doc.reference, {
          'updatedAt': FieldValue.serverTimestamp(),
          'categoryName': newName,
        });
      }
      await batch.commit();
    } catch (e) {
      debugPrint("⚠️ Error updating linked quizzes: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.category != null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        title: Text(isEditing ? "Edit Category" : "Add Category"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(35),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                "Create a category for organizing quizzes",
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Category Name",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category_rounded),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? "Enter category name" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description_rounded),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveCategory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.buttonColor,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(isEditing ? "Update Category" : "Add Category"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:redebugger/model/category.dart';
import 'package:redebugger/theme/theme.dart';
import 'package:redebugger/view/admin/add_category_screen.dart';
import 'package:redebugger/view/admin/manage_quizzes_screen.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Safe snackbar helper
  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Safe dialog helper
  Future<bool> _showConfirmDialog(String title, String content) async {
    if (!mounted) return false;
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Manage Categories',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            onPressed: () async {
              await _safeNavigate(const AddCategoryScreen());
              _refreshIfMounted();
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('categories').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return const Center(child: Text('❌ Error loading categories'));
          if (!snapshot.hasData)
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );

          final categories = snapshot.data!.docs.map((doc) {
            return Category.fromMap(
              doc.data() as Map<String, dynamic>,
              id: doc.id,
            );
          }).toList();

          if (categories.isEmpty) return _buildEmptyState();

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            itemCount: categories.length,
            itemBuilder: (context, index) =>
                _buildCategoryTile(categories[index]),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.category_outlined, size: 64, color: AppTheme.buttonColor),
          const SizedBox(height: 16),
          Text(
            'No Categories found',
            style: TextStyle(color: AppTheme.buttonColor, fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              await _safeNavigate(const AddCategoryScreen());
              _refreshIfMounted();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.buttonColor,
            ),
            child: const Text('Add Category'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(Category category) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: AppTheme.buttonColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.category_outlined, color: AppTheme.primaryColor),
        ),
        title: Text(
          category.name,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.secondaryColor,
          ),
        ),
        subtitle: Text(category.description),
        trailing: PopupMenuButton(
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit, color: AppTheme.primaryColor),
                title: const Text('Edit'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
          onSelected: (value) =>
              _handleCategoryAction(value, category),
        ),
        onTap: () => _safeNavigate(
          ManageQuizzesScreen(
            categoryId: category.id,
            categoryName: category.name,
          ),
        ),
      ),
    );
  }

  Future<void> _handleCategoryAction(String action, Category category) async {
    if (action == 'edit') {
      await _safeNavigate(AddCategoryScreen(category: category));
      _refreshIfMounted();
    } else if (action == 'delete') {
      final confirm = await _showConfirmDialog(
        'Delete Category',
        'Are you sure you want to delete this category? Quizzes under it will remain.',
      );
      if (!confirm) return;

      try {
        await _firestore.collection('categories').doc(category.id).delete();
        _showSnackBar('Category deleted successfully');
      } catch (e) {
        _showSnackBar('Error deleting category: $e');
      }
    }
  }

  /// Safe navigator that checks mounted
  Future<void> _safeNavigate(Widget page) async {
    if (!mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void _refreshIfMounted() {
    if (!mounted) return;
    setState(() {});
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:redebugger/model/school_class.dart';
import 'package:redebugger/theme/theme.dart';
import 'package:redebugger/view/admin/add_class_screen.dart';
import 'package:redebugger/view/admin/manage_assessments_screen.dart';

class ManageClassesScreen extends StatefulWidget {
  const ManageClassesScreen({super.key});

  @override
  State<ManageClassesScreen> createState() => _ManageClassesScreenState();
}

class _ManageClassesScreenState extends State<ManageClassesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    if (!mounted) return false;
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Classes', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            onPressed: () async {
              await _safeNavigate(const AddClassScreen());
              _refreshIfMounted();
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('classes').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('❌ Error loading classes'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final classes = snapshot.data!.docs.map((doc) => SchoolClass.fromMap(doc.data() as Map<String, dynamic>, id: doc.id)).toList();

          if (classes.isEmpty) return _buildEmptyState();

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            itemCount: classes.length,
            itemBuilder: (context, index) => _buildClassTile(classes[index]),
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
          const Icon(Icons.class_outlined, size: 64, color: AppTheme.primaryColor),
          const SizedBox(height: 16),
          const Text('No Classes found', style: TextStyle(color: AppTheme.primaryColor, fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              await _safeNavigate(const AddClassScreen());
              _refreshIfMounted();
            },
            child: const Text('Add Class'),
          ),
        ],
      ),
    );
  }

  Widget _buildClassTile(SchoolClass schoolClass) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.class_outlined, color: AppTheme.primaryColor),
        ),
        title: Text(schoolClass.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        subtitle: Text(schoolClass.description),
        trailing: PopupMenuButton(
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit, color: AppTheme.primaryColor), title: Text('Edit'), contentPadding: EdgeInsets.zero)),
            const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('Delete'), contentPadding: EdgeInsets.zero)),
          ],
          onSelected: (value) => _handleClassAction(value, schoolClass),
        ),
        onTap: () => _safeNavigate(ManageAssessmentsScreen(classId: schoolClass.id, className: schoolClass.name)),
      ),
    );
  }

  Future<void> _handleClassAction(String action, SchoolClass schoolClass) async {
    if (action == 'edit') {
      await _safeNavigate(AddClassScreen(schoolClass: schoolClass));
      _refreshIfMounted();
    } else if (action == 'delete') {
      final confirm = await _showConfirmDialog('Delete Class', 'Are you sure you want to delete this class? Assessments under it will remain.');
      if (!confirm) return;

      try {
        await _firestore.collection('classes').doc(schoolClass.id).delete();
        _showSnackBar('Class deleted successfully');
      } catch (e) {
        _showSnackBar('Error deleting class: $e');
      }
    }
  }

  Future<void> _safeNavigate(Widget page) async {
    if (!mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void _refreshIfMounted() {
    if (!mounted) return;
    setState(() {});
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:redebugger/model/school_class.dart';
import 'package:redebugger/theme/theme.dart';

class AddClassScreen extends StatefulWidget {
  final SchoolClass? schoolClass; 
  const AddClassScreen({super.key, this.schoolClass});

  @override
  State<AddClassScreen> createState() => _AddClassScreenState();
}

class _AddClassScreenState extends State<AddClassScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.schoolClass?.name ?? "");
    _descriptionController = TextEditingController(
      text: widget.schoolClass?.description ?? "",
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveClass() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();

      if (widget.schoolClass == null) {
        // Create new class
        final docRef = _firestore.collection("classes").doc();
        final newClass = SchoolClass(
          id: docRef.id,
          name: name,
          description: description,
          createdAt: DateTime.now(),
        );

        await docRef.set(newClass.toMap(isNew: true));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ Class added successfully")),
          );
        }
      } else {
        // Update existing class
        final updatedClass = SchoolClass(
          id: widget.schoolClass!.id,
          name: name,
          description: description,
          createdAt: widget.schoolClass?.createdAt,
          updatedAt: DateTime.now(),
        );

        await _firestore
            .collection("classes")
            .doc(widget.schoolClass!.id)
            .update(updatedClass.toMap());

        // Run linked assessments update in background to avoid UI freeze
        _updateLinkedAssessments(widget.schoolClass!.id, name);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ Class updated successfully")),
          );
        }
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e, st) {
      debugPrint("❌ Error saving class: $e\n$st");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Failed to save class")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Update assessments linked to a class (non-blocking)
  Future<void> _updateLinkedAssessments(String classId, String newName) async {
    try {
      final snapshot = await _firestore
          .collection('assessments')
          .where('classId', isEqualTo: classId)
          .get();

      if (snapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {
          'updatedAt': FieldValue.serverTimestamp(),
          'className': newName,
        });
      }
      await batch.commit();
    } catch (e) {
      debugPrint("⚠️ Error updating linked assessments: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.schoolClass != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Edit Class" : "Add Class"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(35),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                "Create a class for organizing tests and exams",
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Class Name",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.class_rounded),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? "Enter class name" : null,
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
                  onPressed: _isLoading ? null : _saveClass,
                  style: ElevatedButton.styleFrom(
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
                      : Text(isEditing ? "Update Class" : "Add Class"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

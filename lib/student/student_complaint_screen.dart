import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:redebugger/theme/theme.dart'; // AppTheme

class StudentComplaintScreen extends StatefulWidget {
  const StudentComplaintScreen({super.key});

  @override
  State<StudentComplaintScreen> createState() => _StudentComplaintScreenState();
}

class _StudentComplaintScreenState extends State<StudentComplaintScreen> {
  final TextEditingController _complaintController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _complaintController.dispose();
    super.dispose();
  }

  Future<void> _submitComplaint() async {
    final complaintText = _complaintController.text.trim();
    if (complaintText.isEmpty) return;

    if (!mounted) return;
    setState(() => _isSubmitting = true);

    try {
      // Add complaint to Firestore
      await FirebaseFirestore.instance.collection('complaints').add({
        'complaint': complaintText,
        'timestamp': DateTime.now(),
        // Add student info here if needed
      });

      if (!mounted) return;
      _complaintController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Complaint submitted successfully ✅")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error submitting complaint: $e")));
    } finally {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Complaint"),
        centerTitle: true,
        backgroundColor: const Color(0xFF001F3F),
      ),
      body: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            TextField(
              controller: _complaintController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: "Enter your complaint",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitComplaint,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text("Submitting..."),
                        ],
                      )
                    : const Text("Submit", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

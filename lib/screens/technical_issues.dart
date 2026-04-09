import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TechnicalIssuesPage extends StatefulWidget {
  const TechnicalIssuesPage({Key? key}) : super(key: key);

  @override
  State<TechnicalIssuesPage> createState() => _TechnicalIssuesPageState();
}

class _TechnicalIssuesPageState extends State<TechnicalIssuesPage> {
  final TextEditingController _issueController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitIssue() async {
    if (_issueController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('technical_issues').add({
        'issue': _issueController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Issue submitted successfully ✅")),
      );

      _issueController.clear();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Report Technical Issue")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Describe the issue you’re facing:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _issueController,
              maxLines: 6,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: "e.g. App freezes when I submit a test...",
              ),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    onPressed: _submitIssue,
                    icon: const Icon(Icons.send),
                    label: const Text("Submit"),
                  ),
          ],
        ),
      ),
    );
  }
}

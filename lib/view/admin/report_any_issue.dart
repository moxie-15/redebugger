import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:redebugger/theme/theme.dart';
import 'package:url_launcher/url_launcher.dart';
// For Clipboard

class ReportAnyIssue extends StatefulWidget {
  const ReportAnyIssue({super.key});

  @override
  State<ReportAnyIssue> createState() => _ReportAnyIssueState();
}

class _ReportAnyIssueState extends State<ReportAnyIssue> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _issueController = TextEditingController();

  final String myEmail = 'samuelayomideojo9@gmail.com';

  Future<void> _sendEmail() async {
    if (!_formKey.currentState!.validate()) return;

    final String name = _nameController.text.trim();
    final String email = _emailController.text.trim();
    final String issue = _issueController.text.trim();

    // gmail app or default email app
    final Uri mailtoUri = Uri(
      scheme: 'mailto',
      path: myEmail,
      queryParameters: {
        'subject': 'Issue Report from $name',
        'body': 'Name: $name\nEmail: $email\n\nIssue:\n$issue',
      },
    );

    // 2️⃣ Gmail web
    final Uri gmailUrl = Uri.parse(
      'https://mail.google.com/mail/?view=cm&fs=1&to=$myEmail&su=${Uri.encodeComponent('Issue Report from $name')}&body=${Uri.encodeComponent('Name: $name\nEmail: $email\n\nIssue:\n$issue')}',
    );

    try {
      // Try default email app first
      await launchUrl(mailtoUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        // If that fails, try Gmail web
        await launchUrl(gmailUrl, mode: LaunchMode.externalApplication);
      } catch (_) {
        // If all fails, show dialog with copy option
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Unable to open email apps'),
            content: SelectableText(
              'Please send your issue manually to:\n\n$myEmail',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: myEmail));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Email copied to clipboard!')),
                  );
                  Navigator.pop(context);
                },
                child: const Text('Copy Email'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _issueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Report an Issue"),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(
              Icons.report_problem_outlined,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              "Facing an issue? Fill the form below and submit to contact admin.",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Your Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) => val == null || val.isEmpty
                        ? 'Please enter your name'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Your Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'\S+@\S+\.\S+').hasMatch(val)) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _issueController,
                    decoration: const InputDecoration(
                      labelText: 'Describe the issue',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.multiline,
                    maxLines: 5,
                    validator: (val) => val == null || val.isEmpty
                        ? 'Please describe the issue'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _sendEmail,
                      child: const Text(
                        'Submit',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

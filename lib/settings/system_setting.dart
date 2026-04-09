import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:redebugger/theme/theme.dart';
import 'package:redebugger/auth/startscreen.dart';

// ==========================================
// 1. THE SETTINGS HUB (Main Screen)
// ==========================================
class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {
  bool _isDarkMode = false;
  bool _pushNotifications = true;
  bool _autoSync = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0, 
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        children: [
          _buildSectionHeader("Appearance"),
          SwitchListTile(
            title: const Text("Dark Mode"),
            subtitle: const Text("Reduce eye strain and save battery"),
            secondary: const Icon(Icons.dark_mode_outlined),
            value: _isDarkMode,
            activeThumbColor: AppTheme.primaryColor,
            onChanged: (bool value) {
              setState(() => _isDarkMode = value);
            },
          ),
          const Divider(),

          _buildSectionHeader("Notifications"),
          SwitchListTile(
            title: const Text("Push Notifications"),
            subtitle: const Text("Stay in the loop with real-time pings"),
            secondary: const Icon(Icons.notifications_active_outlined),
            value: _pushNotifications,
            activeThumbColor: AppTheme.primaryColor,
            onChanged: (bool value) {
              setState(() => _pushNotifications = value);
            },
          ),
          const Divider(),

          _buildSectionHeader("Advanced Configurations"),
          SwitchListTile(
            title: const Text("Background Data Sync"),
            subtitle: const Text("Keep local caches updated automatically"),
            secondary: const Icon(Icons.sync),
            value: _autoSync,
            activeThumbColor: AppTheme.primaryColor,
            onChanged: (bool value) {
              setState(() => _autoSync = value);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
            title: const Text(
              "Clear Cache", 
              style: TextStyle(color: Colors.redAccent)
            ),
            onTap: () {
              // Execute cache clearing logic here
            },
          ),
          const Divider(),

          _buildSectionHeader("Support & Feedback"),
          ListTile(
            leading: const Icon(Icons.bug_report_outlined),
            title: const Text("Report an Issue"),
            subtitle: const Text("Found a bug? Contact admin directly."),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReportAnyIssue()),
              );
            },
          ),
          const Divider(),

          // Account Management & Logout Integration
          _buildSectionHeader("Account"),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: const Text(
              "Log Out",
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.redAccent),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LogoutScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ==========================================
// 2. THE REPORTING MODULE (Sub-Screen)
// ==========================================
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

    final Uri mailtoUri = Uri(
      scheme: 'mailto',
      path: myEmail,
      queryParameters: {
        'subject': 'Issue Report from $name',
        'body': 'Name: $name\nEmail: $email\n\nIssue:\n$issue',
      },
    );

    final Uri gmailUrl = Uri.parse(
      'https://mail.google.com/mail/?view=cm&fs=1&to=$myEmail&su=${Uri.encodeComponent('Issue Report from $name')}&body=${Uri.encodeComponent('Name: $name\nEmail: $email\n\nIssue:\n$issue')}',
    );

    try {
      await launchUrl(mailtoUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        await launchUrl(gmailUrl, mode: LaunchMode.externalApplication);
      } catch (_) {
        if (!mounted) return;
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
                        backgroundColor: AppTheme.primaryColor,
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

// ==========================================
// 3. THE OFFBOARDING MODULE (Logout Screen)
// ==========================================
class LogoutScreen extends StatelessWidget {
  const LogoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  'images/default_1.jpg',
                ), 
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Semi-transparent overlay to darken the background
          Container(color: Colors.black.withOpacity(0.4)),

          // Centered logout card
          Center(
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.logout_rounded,
                      size: 80,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Are you sure you want to log out?",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Cancel button
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.secondaryColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 25,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                        // Logout button
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const Startscreen(),
                              ),
                              (route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 25,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Logout",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:redebugger/settings/system_setting.dart';
import 'package:redebugger/student/student_complaint_screen.dart';
import 'package:redebugger/student/student_faq_screen.dart';
import 'package:redebugger/student/student_notification.dart';
import 'package:redebugger/student/student_result_screen.dart';

import 'package:redebugger/student/student_dashboard.dart';
import 'package:redebugger/student/textbook_library_screen.dart';
import 'package:redebugger/theme/theme.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:redebugger/services/local_result_sync_manager.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  User? _user;
  String _studentName = 'Student';
  String _studentClass = 'Unknown Class';

  @override
  void initState() {
    super.initState();
    _loadUser();
    // Silently process any stuck offline exam results natively!
    LocalResultSyncManager.syncOfflineResults();
  }

  Future<void> _loadUser() async {
    _user = FirebaseAuth.instance.currentUser;
    if (_user != null) {
      try {
        await _user!.reload();
        _user = FirebaseAuth.instance.currentUser;
        
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(_user!.uid).get();
        if (userDoc.exists) {
          final data = userDoc.data()!;
          final name = data['displayName']?.toString() ?? '';
          final sClass = data['studentClass']?.toString() ?? 'Unknown Class';
          final sStream = data['studentStream']?.toString() ?? '';
          
          setState(() {
            _studentName = name.isNotEmpty ? name : 'Student';
            if (sStream.isNotEmpty) {
              _studentClass = '$sClass ($sStream)';
            } else {
              _studentClass = sClass;
            }
          });
        }
      } catch (e) {
        debugPrint('User reload error: $e');
      }
    }
    if (mounted) setState(() {});
  }

  String get userName {
    if (_studentName != 'Student') return _studentName;

    final email = _user?.email ?? FirebaseAuth.instance.currentUser?.email;
    if (email == null || email.trim().isEmpty) return 'Student';

    final localPart = email.split('@').first.trim();
    if (localPart.isEmpty) return 'Student';

    final cleaned = localPart.replaceAll(RegExp(r'[_\.\-]+'), ' ').trim();
    if (cleaned.isEmpty) return 'Student';

    final words = cleaned
        .split(RegExp(r'\s+'))
        .map((w) {
          if (w.isEmpty) return '';
          final first = w[0].toUpperCase();
          final rest = w.length > 1 ? w.substring(1) : '';
          return '$first$rest';
        })
        .where((w) => w.isNotEmpty)
        .toList();

    if (words.isEmpty) return 'Username';
    return words.join(' ');
  }

  void _openFeatureMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFeatureItem(
              icon: Icons.admin_panel_settings,
              title: 'Reach Admin',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StudentComplaintScreen(),
                  ),
                );
              },
            ),
            _buildFeatureItem(
              icon: Icons.help_center,
              title: 'FAQ',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StudentFAQScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic theme styling for professional gradient
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Dashboard"),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        // THE PIVOT: Injecting the notification action here
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_active_outlined, 
              color: Colors.white, // High contrast for visibility
            ),
            tooltip: 'Notifications',
            onPressed: () {
              // Actionable deliverable: Route directly from the AppBar
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StudentNotification(),
                ),
              );
            },
          ),
          const SizedBox(width: 8), // Padding so it doesn't hug the edge
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openFeatureMenu,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.menu, color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF121212), const Color(0xFF1A1A2E)]
                : [Colors.grey.shade50, Colors.blue.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black26 : Colors.blue.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  "Welcome to your Dashboard, $userName! 👋",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 40),

              // Responsive Layout Grid (Now cleaner without the Notification block)
              LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = 2; // Mobile
                  if (constraints.maxWidth > 1000) {
                    crossAxisCount = 4; // Desktop (Adjusted from 5 since we removed an item)
                  } else if (constraints.maxWidth > 600) {
                    crossAxisCount = 3; // Tablet
                  }

                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    children: [
                      _buildCard(
                        color: Colors.blue.shade600,
                        title: "Take Quiz",
                        icon: Icons.quiz,
                        onTap: () {
                          // Bypassing TestLoginScreen completely!
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Exam Zone"),
                              content: Text("You are entering the Exam Zone as $_studentName.\nMake sure your environment is quiet."),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => StudentDashboard(
                                          studentName: _studentName, 
                                          studentClass: _studentClass
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text("Proceed")
                                )
                              ],
                            )
                          );
                        },
                      ),
                      _buildCard(
                        color: Colors.teal.shade500,
                        title: "Textbook Library",
                        icon: Icons.library_books,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TextbookLibraryScreen(),
                          ),
                        ),
                      ),
                      _buildCard(
                        color: Colors.purple.shade500,
                        title: "My Results",
                        icon: Icons.bar_chart,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const StudentResultScreen(),
                          ),
                        ),
                      ),
                      _buildCard(
                        color: Colors.grey.shade700,
                        title: "Settings",
                        icon: Icons.settings,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SystemSettingsScreen(),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Modernized Card builder with hover/scale potential
  Widget _buildCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Card(
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      shadowColor: color.withOpacity(0.5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
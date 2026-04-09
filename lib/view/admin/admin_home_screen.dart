import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:redebugger/settings/system_setting.dart';
import 'package:redebugger/theme/theme.dart';
import 'package:redebugger/view/admin/admin_quiz_selection_screen.dart';
import 'package:redebugger/view/admin/announcements_screen.dart';

import 'package:redebugger/teacher/teacher_upload_quiz_screen.dart';
import 'package:redebugger/teacher/teacher_grades_export_screen.dart';
import 'package:redebugger/view/admin/exams/exams_functions.dart';
import 'package:redebugger/view/admin/manage_categories_screen.dart';
import 'package:redebugger/view/admin/manage_quizzes_screen.dart';
import 'package:redebugger/view/admin/manage_user.dart';
import 'package:redebugger/view/admin/report_any_issue.dart' hide ReportAnyIssue;
import 'package:redebugger/view/admin/seed_demo_data.dart';


class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> _fetchStatistics() async {
    final categoriesCount = await _firestore
        .collection('categories')
        .count()
        .get();
    final quizzesCount = await _firestore.collection('quizzes').count().get();
    final latestQuizzes = await _firestore
        .collection('quizzes')
        .orderBy('createdAt', descending: true)
        .limit(5)
        .get();
    final usersCount = await _firestore.collection('users').count().get();
    final studentsCount = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'student')
        .count()
        .get();

    final categories = await _firestore.collection('categories').get();
    final categoryData = await Future.wait(
      categories.docs.map((category) async {
        final quizCount = await _firestore
            .collection('quizzes')
            .where('categoryId', isEqualTo: category.id)
            .count()
            .get();
        return {
          'name': category.data()['name'] as String,
          'count': quizCount.count,
        };
      }),
    );

    return {
      'totalCategories': categoriesCount.count,
      'totalUsers': usersCount.count,
      'totalQuizzes': quizzesCount.count,
      'latestQuizzes': latestQuizzes.docs,
      'categoriesData': categoryData,
      'totalStudents': studentsCount.count,
    };
  }

  Widget _buildStatsCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Card(
      elevation: 3,
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 30),
            const SizedBox(height: 18),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: color,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 30),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white, // unified for readability
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatData(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        title: const Text(
          "Admin Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: FutureBuilder(
        future: _fetchStatistics(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text("⚠️ Firestore Error: Could not load stats"),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: Text("No data found"));
          }

          final stats = snapshot.data!;
          final categoryData = stats['categoriesData'] as List<dynamic>;
          final latestQuizzes =
              stats['latestQuizzes'] as List<QueryDocumentSnapshot>;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Text(
                      "Welcome Admin",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Here's your quiz application overview",
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Stats row
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatsCard(
                          "Categories",
                          stats['totalCategories'].toString(),
                          Colors.teal,
                          Icons.category,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildStatsCard(
                          "Quizzes",
                          stats['totalQuizzes'].toString(),
                          Colors.indigo,
                          Icons.quiz,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildStatsCard(
                          "Students",
                          stats['totalStudents'].toString(),
                          Colors.orange,
                          Icons.people,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Admin management
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.admin_panel_settings,
                                color: AppTheme.primaryColor,
                                size: 25,
                              ),
                              const SizedBox(width: 20),
                              Text(
                                "Admin Management",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          GridView.count(
                            crossAxisCount: 5, // Windows fixed layout
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              _buildDashboardCard('Exams Functions', Icons.person, Colors.indigo, () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ExamsFunctions(),
                                  ),
                                );
                              }),

                             
                              _buildDashboardCard(
                                'Manage Users',
                                Icons.manage_accounts,
                                Colors.orange,
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ManageUser(),
                                    ),
                                  );
                                },
                              ),
                              _buildDashboardCard(
                                "Announcements",
                                Icons.campaign,
                                Colors.green,
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          AnnouncementsScreen(),
                                    ),
                                  );
                                },
                              ),
                                _buildDashboardCard(
                                  "System Settings",
                                  Icons.settings,
                                  Colors.grey,
                                  () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            SystemSettingsScreen(),
                                      ),
                                    );
                                  },
                                ),
                                _buildDashboardCard(
                                  "Seed 50 Demos",
                                  Icons.bug_report,
                                  Colors.redAccent,
                                  () async {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seeding demo data...')));
                                    try {
                                      await seedDemoQuestions();
                                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ 50 Questions added!')));
                                    } catch (e) {
                                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                                    }
                                  },
                                ),                           ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Category statistics
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.pie_chart_rounded,
                                color: AppTheme.primaryColor,
                                size: 25,
                              ),
                              const SizedBox(width: 20),
                              Text(
                                "Category Statistics",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: categoryData.length,
                            itemBuilder: (context, index) {
                              final data = categoryData[index];
                              final totalQuizzes = categoryData.fold<int>(
                                0,
                                (sum, item) => sum + (item['count'] as int),
                              );
                              final percentage = totalQuizzes > 0
                                  ? (data['count'] as int) / totalQuizzes * 100
                                  : 0.0;
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            data['name'] as String,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.primaryColor,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '${data['count']} quizzes',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: AppTheme.secondaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        "${percentage.toStringAsFixed(1)}%",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Recent activity
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.history_rounded,
                                color: AppTheme.primaryColor,
                                size: 25,
                              ),
                              const SizedBox(width: 20),
                              Text(
                                "Recent Activity",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: latestQuizzes.length,
                            itemBuilder: (context, index) {
                              final quiz =
                                  latestQuizzes[index].data()
                                      as Map<String, dynamic>;
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.quiz_rounded,
                                        color: AppTheme.primaryColor,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            quiz['title'],
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 15,
                                              color: Theme.of(context).textTheme.bodyLarge?.color,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "Created on ${_formatData(quiz['createdAt'].toDate())}",
                                            style: TextStyle(
                                              fontWeight: FontWeight.w400,
                                              fontSize: 13,
                                              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

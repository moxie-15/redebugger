import 'package:flutter/material.dart';
import 'package:redebugger/teacher/teacher_grades_export_screen.dart';
import 'package:redebugger/teacher/teacher_upload_quiz_screen.dart';
import 'package:redebugger/view/admin/admin_quiz_selection_screen.dart';
import 'package:redebugger/view/admin/manage_categories_screen.dart';
import 'package:redebugger/view/admin/manage_quizzes_screen.dart';

// IMPORTANT: Make sure you import all these screens so the routing actually works!
// import 'package:redebugger/admin/manage_quizzes_screen.dart';
// import 'package:redebugger/admin/teacher_upload_quiz_screen.dart';
// import 'package:redebugger/admin/teacher_grades_export_screen.dart';
// import 'package:redebugger/admin/manage_categories_screen.dart';
// import 'package:redebugger/admin/admin_quiz_selection_screen.dart';

class ExamsFunctions extends StatefulWidget {
  const ExamsFunctions({super.key});

  @override
  State<ExamsFunctions> createState() => _ExamsFunctionsState();
}

class _ExamsFunctionsState extends State<ExamsFunctions> {

  // We are storing the Navigation logic directly inside the data payload.
  // This is highly scalable and keeps the build method completely pristine.
  List<Map<String, dynamic>> _getAdminFunctions(BuildContext context) {
    return [
      {
        "title": "Manage Quizzes",
        "icon": Icons.quiz_rounded,
        "color": Colors.indigo,
        "onTap": () {
          Navigator.push(
            context,
            MaterialPageRoute(
              // Passing the dummy string you had in your snippet
              builder: (context) => ManageQuizzesScreen(categoryName: 'categoryName!,'),
            ),
          );
        },
      },
      {
        "title": "Upload File Exam",
        "icon": Icons.upload_file,
        "color": Colors.purple,
        "onTap": () {
          Navigator.push(
            context, 
            MaterialPageRoute(builder: (_) => const TeacherUploadQuizScreen())
          );
        },
      },
      {
        "title": "Export Gradebook",
        "icon": Icons.file_download,
        "color": Colors.blueAccent,
        "onTap": () {
          Navigator.push(
            context, 
            MaterialPageRoute(builder: (_) => const TeacherGradesExportScreen())
          );
        },
      },
      {
        "title": "Manage Categories",
        "icon": Icons.category_rounded,
        "color": Colors.teal,
        "onTap": () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ManageCategoriesScreen()),
          );
        },
      },
      {
        "title": "View Student Result",
        "icon": Icons.bar_chart,
        "color": Colors.blueGrey,
        "onTap": () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminQuizSelectionScreen()),
          );
        },
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Generate the list with the current context for routing
    final adminFunctions = _getAdminFunctions(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Assessment Hub"),
        backgroundColor: Colors.indigo, // Or use your AppTheme.primaryColor
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = 2; // Mobile
            if (constraints.maxWidth > 1000) {
              crossAxisCount = 5; // Desktop
            } else if (constraints.maxWidth > 600) {
              crossAxisCount = 3; // Tablet
            }

            return GridView.builder(
              shrinkWrap: true, 
              physics: const BouncingScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1, 
              ),
              itemCount: adminFunctions.length,
              itemBuilder: (context, index) {
                final item = adminFunctions[index];
                
                // The GridView just calls the helper method and passes the data
                return _buildDashboardCard(
                  title: item['title'] as String,
                  icon: item['icon'] as IconData,
                  color: item['color'] as Color,
                  onTap: item['onTap'] as VoidCallback,
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      color: color,
      elevation: 6,
      shadowColor: color.withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap, // Executes the specific routing function from our List
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12), 
                ),
                child: Icon(icon, size: 36, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
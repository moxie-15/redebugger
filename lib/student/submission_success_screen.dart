import 'package:flutter/material.dart';
import 'package:redebugger/student/student_home_screen.dart';

class SubmissionSuccessScreen extends StatelessWidget {
  final String studentName;
  final String studentClass;
  final int score;
  final int totalQuestions;
  final bool showResultsToStudent;

  const SubmissionSuccessScreen({
    super.key,
    required this.studentName,
    required this.studentClass,
    required this.score,
    required this.totalQuestions,
    required this.showResultsToStudent,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            fit: BoxFit.cover,
            image: AssetImage('images/submit.jpg'),
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 100,
                ),
                const SizedBox(height: 20),
                Text(
                  "🎉 Congratulations, $studentName! 🎉",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  "Your exam has been successfully submitted.\nClass: $studentClass",
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                if (showResultsToStudent)
                   Container(
                     padding: const EdgeInsets.all(16),
                     decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                     child: Text(
                        "Score: $score / $totalQuestions", 
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)
                     )
                   )
                else
                   Container(
                     padding: const EdgeInsets.all(16),
                     decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
                     child: const Text(
                        "Scores are hidden pending teacher approval.", 
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange)
                     )
                   ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    // Navigate to StudentDashboard and remove all previous routes
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StudentHomeScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  child: const Text("Back to Home"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

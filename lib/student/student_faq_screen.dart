import 'package:flutter/material.dart';
import 'package:redebugger/theme/theme.dart';

class StudentFAQScreen extends StatelessWidget {
  const StudentFAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = [
      {
        "question": "What are the exam rules and regulations?",
        "answer":
            "1. No cheating or impersonation.\n"
            "2. Note that when you submit your exam, you cannot retake it.\n"
            "3. No Mobile Phone.\n"
            "4. Students must arrive at least 15 minutes before the exam starts.\n"
            "5. Follow invigilator’s instructions strictly.\n"
            "6. No talking or disruptive behavior during the exam.\n"
            "7. Only authorized materials are allowed.\n"
            "8. Submit your exam on time.\n"
            "9. Stay seated until the exam is officially over.\n"
            "10. Any form of academic dishonesty will result in disciplinary action.\n"
            "11. Ensure your device is fully charged and has a stable internet connection for online exams.",
      },
      {
        "question": "How do I navigate the app?",
        "answer":
            "Use the bottom navigation bar to access Home, Quizzes, Results, and Profile. "
            "Tap on any menu icon to switch sections easily.",
      },
      {
        "question": "How do I reach the admin?",
        "answer":
            "Go to the 'Contact Admin' option from the floating action button "
            "or navigate to the Help section in the app.",
      },
      {
        "question": "Where do I see upcoming exams?",
        "answer":
            "Upcoming exams are listed on your Dashboard. You will also get notifications when a new exam is scheduled.",
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Student FAQs"),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: ListView.builder(
        itemCount: faqs.length,
        itemBuilder: (context, index) {
          final faq = faqs[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 35, vertical: 15),
            child: ExpansionTile(
              title: Text(
                faq["question"]!,

                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(faq["answer"]!),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

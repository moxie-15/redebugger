import 'package:flutter/material.dart';
import 'package:redebugger/theme/theme.dart';

class FaqsScreen extends StatelessWidget {
  const FaqsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = [
      {
        "question": "How do I reset my password?",
        "answer":
            "Go to the login screen, click contact Admin?', and follow the instructions.",
      },
      {
        "question": "How do I contact the admin?",
        "answer":
            "Use the 'Contact Admin' option from the floating action button on the sign-in screen.",
      },
      {
        "question": "Can I change my username?",
        "answer":
            "Usernames are unique and cannot be changed. Contact admin for special cases.",
      },
      {
        "question": "Where can I see my quiz results?",
        "answer":
            "After completing a quiz, Meet your Teacher for your results.",
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("FAQs"),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: ListView.builder(
        itemCount: faqs.length,
        itemBuilder: (context, index) {
          final faq = faqs[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

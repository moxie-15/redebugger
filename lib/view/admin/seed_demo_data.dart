import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> seedDemoQuestions() async {
  final firestore = FirebaseFirestore.instance;
  
  // 1. Create a dummy category if it doesn't exist
  final catRef = firestore.collection('categories').doc('demo_category_1');
  await catRef.set({
    'name': 'Demo Category',
    'description': 'Category containing automatically seeded demo questions.',
    'createdAt': FieldValue.serverTimestamp(),
  });

  // 2. Generate 50 questions
  List<Map<String, dynamic>> questions = [];
  for (int i = 1; i <= 50; i++) {
    questions.add({
      'id': 'q_$i',
      'text': 'This is demo question number $i. What is $i + $i?',
      'options': [
        '${i * 2 - 1}',
        '${i * 2}',
        '${i * 2 + 1}',
        'None of the above'
      ],
      'correctOptionIndex': 1, // The correct answer is i * 2, which is index 1
      'points': 1,
    });
  }

  // 3. Create the demo quiz
  final quizRef = firestore.collection('quizzes').doc('demo_quiz_50_questions');
  await quizRef.set({
    'id': 'demo_quiz_50_questions',
    'categoryId': 'demo_category_1',
    'title': 'Test 50 Questions Demo',
    'description': 'A randomly generated test with 50 questions.',
    'timeLimit': 60, // 60 minutes
    'shuffleQuestions': true,
    'showResultsToStudent': true,
    'questions': questions,
    'createdBy': 'system',
    'createdAt': FieldValue.serverTimestamp(),
  });
}

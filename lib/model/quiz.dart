import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:redebugger/model/question.dart';

class Quiz {
  final String id;
  final String title;
  final String categoryId;
  final String categoryName;
  final int timeLimit; // in minutes
  final List<Question> questions;
  final bool shuffleQuestions; // ✅ new
  final bool showResultsToStudent; // ✅ new
  final bool showResultsImmediately; // ✅ optional, more fine-grained
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Quiz({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.categoryName,
    required this.timeLimit,
    required this.questions,
    this.shuffleQuestions = false,
    this.showResultsToStudent = true,
    this.showResultsImmediately = true,
    this.createdAt,
    this.updatedAt,
  });

  // Factory constructor for Firestore
  factory Quiz.fromMap(Map<String, dynamic> map, {required String id}) {
    return Quiz(
      id: id,
      title: map['title'] ?? '',
      categoryId: map['categoryId'] ?? '',
      categoryName: map['categoryName'] ?? '',
      timeLimit: map['timeLimit'] ?? 0,
      questions: map['questions'] != null
          ? List<Question>.from(
              (map['questions'] as List).map(
                (q) => Question.fromMap(q as Map<String, dynamic>),
              ),
            )
          : [],
      shuffleQuestions: map['shuffleQuestions'] ?? false,
      showResultsToStudent: map['showResultsToStudent'] ?? true,
      showResultsImmediately: map['showResultsImmediately'] ?? true,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Convert to map for saving to Firestore
  Map<String, dynamic> toMap({bool isNew = false}) {
    return {
      'title': title,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'timeLimit': timeLimit,
      'questions': questions.map((q) => q.toMap()).toList(),
      'shuffleQuestions': shuffleQuestions,
      'showResultsToStudent': showResultsToStudent,
      'showResultsImmediately': showResultsImmediately,
      if (isNew) 'createdAt': Timestamp.fromDate(DateTime.now()),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
  }

  // Copy with helper
  Quiz copyWith({
    String? id,
    String? title,
    String? categoryId,
    String? categoryName,
    int? timeLimit,
    List<Question>? questions,
    bool? shuffleQuestions,
    bool? showResultsToStudent,
    bool? showResultsImmediately,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Quiz(
      id: id ?? this.id,
      title: title ?? this.title,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      timeLimit: timeLimit ?? this.timeLimit,
      questions: questions ?? this.questions,
      shuffleQuestions: shuffleQuestions ?? this.shuffleQuestions,
      showResultsToStudent: showResultsToStudent ?? this.showResultsToStudent,
      showResultsImmediately:
          showResultsImmediately ?? this.showResultsImmediately,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:redebugger/model/question.dart';

class Assessment {
  final String id;
  final String title;
  final String classId; // Formerly categoryId
  final String className; // Formerly categoryName
  final String type; // 'test' or 'exam'
  final int durationMinutes; // Time Limit

  // Teacher Release Controls
  final String releaseMode; // 'manual' or 'scheduled'
  final DateTime? releaseDate; // null if manual
  final bool isResultReleased; // controls visibility

  final List<Question> questions;
  final bool shuffleQuestions;
  
  final DateTime? startTime;
  final DateTime? endTime;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  Assessment({
    required this.id,
    required this.title,
    required this.classId,
    required this.className,
    required this.type,
    required this.durationMinutes,
    this.releaseMode = 'manual',
    this.releaseDate,
    this.isResultReleased = false,
    required this.questions,
    this.shuffleQuestions = true,
    this.startTime,
    this.endTime,
    this.createdAt,
    this.updatedAt,
  });

  factory Assessment.fromMap(Map<String, dynamic> map, {required String id}) {
    return Assessment(
      id: id,
      title: map['title'] ?? '',
      classId: map['classId'] ?? '',
      className: map['className'] ?? '',
      type: map['type'] ?? 'test',
      durationMinutes: map['durationMinutes'] ?? 0,
      releaseMode: map['releaseMode'] ?? 'manual',
      releaseDate: map['releaseDate'] != null ? (map['releaseDate'] as Timestamp).toDate() : null,
      isResultReleased: map['isResultReleased'] ?? false,
      questions: map['questions'] != null
          ? List<Question>.from(
              (map['questions'] as List).map(
                (q) => Question.fromMap(q as Map<String, dynamic>),
              ),
            )
          : [],
      shuffleQuestions: map['shuffleQuestions'] ?? true,
      startTime: map['startTime'] != null ? (map['startTime'] as Timestamp).toDate() : null,
      endTime: map['endTime'] != null ? (map['endTime'] as Timestamp).toDate() : null,
      createdAt: map['createdAt'] != null ? (map['createdAt'] as Timestamp).toDate() : null,
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap({bool isNew = false}) {
    return {
      'title': title,
      'classId': classId,
      'className': className,
      'type': type,
      'durationMinutes': durationMinutes,
      'releaseMode': releaseMode,
      'releaseDate': releaseDate != null ? Timestamp.fromDate(releaseDate!) : null,
      'isResultReleased': isResultReleased,
      'questions': questions.map((q) => q.toMap()).toList(),
      'shuffleQuestions': shuffleQuestions,
      'startTime': startTime != null ? Timestamp.fromDate(startTime!) : null,
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      if (isNew) 'createdAt': Timestamp.fromDate(DateTime.now()),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
  }
}

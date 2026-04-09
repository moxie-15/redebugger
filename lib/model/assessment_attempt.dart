import 'package:cloud_firestore/cloud_firestore.dart';

class AssessmentAttempt {
  final String id;
  final String userId;
  final String studentName;
  final String assessmentId;
  final String title;
  
  // Mapping Question Text -> Selected Option Text or Indices
  final Map<String, int> answersSubmitted; 
  
  final int? score;
  final String status; // 'pending', 'reviewed', 'released'
  
  final DateTime? submittedAt;
  final DateTime? createdAt;

  AssessmentAttempt({
    required this.id,
    required this.userId,
    required this.studentName,
    required this.assessmentId,
    required this.title,
    required this.answersSubmitted,
    this.score,
    required this.status,
    this.submittedAt,
    this.createdAt,
  });

  factory AssessmentAttempt.fromMap(Map<String, dynamic> map, {required String id}) {
    return AssessmentAttempt(
      id: id,
      userId: map['userId'] ?? '',
      studentName: map['studentName'] ?? 'Unknown',
      assessmentId: map['assessmentId'] ?? '',
      title: map['title'] ?? '',
      answersSubmitted: Map<String, int>.from(map['answersSubmitted'] ?? {}),
      score: map['score'],
      status: map['status'] ?? 'pending',
      submittedAt: map['submittedAt'] != null ? (map['submittedAt'] as Timestamp).toDate() : null,
      createdAt: map['createdAt'] != null ? (map['createdAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'studentName': studentName,
      'assessmentId': assessmentId,
      'title': title,
      'answersSubmitted': answersSubmitted,
      'score': score,
      'status': status,
      'submittedAt': submittedAt != null ? Timestamp.fromDate(submittedAt!) : null,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : Timestamp.fromDate(DateTime.now()),
    };
  }
}

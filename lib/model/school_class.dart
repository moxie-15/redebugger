import 'package:cloud_firestore/cloud_firestore.dart';

class SchoolClass {
  final String id;
  final String name;
  final String description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SchoolClass({
    required this.id,
    required this.name,
    required this.description,
    this.createdAt,
    this.updatedAt,
  });

  factory SchoolClass.fromMap(Map<String, dynamic> map, {String? id}) {
    DateTime? _parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return null;
    }

    return SchoolClass(
      id: id ?? map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap({bool isNew = false}) {
    final map = <String, dynamic>{
      'id': id,
      'name': name,
      'description': description,
    };

    if (isNew) {
      map['createdAt'] = FieldValue.serverTimestamp();
    }
    map['updatedAt'] = FieldValue.serverTimestamp();

    return map;
  }

  SchoolClass copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SchoolClass(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}


class Question {
  final String text;
  final List<String> options;
  final int correctOptionIndex;

  Question({
    required this.text,
    required this.options,
    required this.correctOptionIndex,
  });

  // Factory constructor to create from map
  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      text: map['text'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctOptionIndex: map['correctOptionIndex'] ?? 0,
    );
  }

  // Convert Question to map
  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'options': options,
      'correctOptionIndex': correctOptionIndex,
    };
  }

  // CopyWith method for immutability
  Question copyWith({
    String? text,
    List<String>? options,
    int? correctOptionIndex,
  }) {
    return Question(
      text: text ?? this.text,
      options: options ?? this.options,
      correctOptionIndex: correctOptionIndex ?? this.correctOptionIndex,
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'questions.dart';

class QuizModel {
  final String id;
  final String name;
  final String description;
  final List<Question> questionBank;
  final String createdBy;
  final DateTime createdAt;
  final int difficulty; // 1-5 scale

  QuizModel({
    required this.id,
    required this.name,
    required this.description,
    required this.questionBank,
    required this.createdBy,
    required this.createdAt,
    this.difficulty = 3,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'questions': questionBank.map((q) => q.toMap()).toList(),
      'createdBy': createdBy,
      'createdAt': createdAt,
      'difficulty': difficulty,
    };
  }

  factory QuizModel.fromMap(Map<String, dynamic> map, String docId) {
    return QuizModel(
      id: docId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      questionBank:
          (map['questions'] as List?)
              ?.map((q) => Question.fromMap(q as Map<String, dynamic>))
              .toList() ??
          [],
      createdBy: map['createdBy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      difficulty: map['difficulty'] ?? 3,
    );
  }
}

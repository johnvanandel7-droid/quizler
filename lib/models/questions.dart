class Question {
  String q;
  bool a;

  Question({required this.q, required this.a});

  // Convert to Firestore format
  Map<String, dynamic> toMap() {
    return {'q': q, 'a': a};
  }

  // Create from Firestore document
  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(q: map['q'] ?? '', a: map['a'] ?? false);
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quizler/models/quiz_model.dart';
import 'package:quizler/models/questions.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String quizzesCollection = 'quizzes';

  /// Fetch all quizzes
  Future<List<QuizModel>> getAllQuizzes() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(quizzesCollection)
          .get();

      return snapshot.docs
          .map(
            (doc) =>
                QuizModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();
    } catch (e) {
      print('Error fetching quizzes: $e');
      return [];
    }
  }

  /// Fetch quiz by ID
  Future<QuizModel?> getQuizById(String quizId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection(quizzesCollection)
          .doc(quizId)
          .get();

      if (doc.exists) {
        return QuizModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('Error fetching quiz: $e');
      return null;
    }
  }

  /// Search quizzes by name
  Future<List<QuizModel>> searchQuizzes(String query) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(quizzesCollection)
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: query + 'z')
          .get();

      return snapshot.docs
          .map(
            (doc) =>
                QuizModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();
    } catch (e) {
      print('Error searching quizzes: $e');
      return [];
    }
  }

  /// Create new quiz
  Future<String?> createQuiz({
    required String name,
    required String description,
    required List<Question> questions,
    required String userId,
    int difficulty = 3,
  }) async {
    try {
      final docRef = await _firestore.collection(quizzesCollection).add({
        'name': name,
        'description': description,
        'questions': questions.map((q) => q.toMap()).toList(),
        'createdBy': userId,
        'createdAt': FieldValue.serverTimestamp(),
        'difficulty': difficulty,
      });
      return docRef.id;
    } catch (e) {
      print('Error creating quiz: $e');
      return null;
    }
  }

  /// Update existing quiz
  Future<bool> updateQuiz({
    required String quizId,
    required String name,
    required String description,
    required List<Question> questions,
    int difficulty = 3,
  }) async {
    try {
      await _firestore.collection(quizzesCollection).doc(quizId).update({
        'name': name,
        'description': description,
        'questions': questions.map((q) => q.toMap()).toList(),
        'difficulty': difficulty,
      });
      return true;
    } catch (e) {
      print('Error updating quiz: $e');
      return false;
    }
  }

  /// Delete quiz
  Future<bool> deleteQuiz(String quizId) async {
    try {
      await _firestore.collection(quizzesCollection).doc(quizId).delete();
      return true;
    } catch (e) {
      print('Error deleting quiz: $e');
      return false;
    }
  }

  /// Get quizzes by user
  Future<List<QuizModel>> getQuizzesByUser(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(quizzesCollection)
          .where('createdBy', isEqualTo: userId)
          .get();

      return snapshot.docs
          .map(
            (doc) =>
                QuizModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();
    } catch (e) {
      print('Error fetching user quizzes: $e');
      return [];
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quizler/models/questions.dart';
import 'package:quizler/services/firebase_service.dart';
import 'package:quizler/models/quiz_model.dart';

final firestore = FirebaseFirestore.instance;

class QuizProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  List<QuizModel> _quizzes = [];
  List<QuizModel> _filteredQuizzes = [];
  QuizModel? _currentQuiz;
  bool _isLoading = false;
  String _errorMessage = '';

  // Getters
  List<QuizModel> get quizzes => _quizzes;
  List<QuizModel> get filteredQuizzes => _filteredQuizzes;
  QuizModel? get currentQuiz => _currentQuiz;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  QuizProvider() {
    fetchAllQuizzes();
  }

  /// Fetch all quizzes from Firebase
  Future<void> fetchAllQuizzes() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _quizzes = await _firebaseService.getAllQuizzes();
      _filteredQuizzes = _quizzes;
    } catch (e) {
      _errorMessage = 'Failed to load quizzes';
      print('Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Search quizzes by name
  Future<void> searchQuizzes(String query) async {
    if (query.isEmpty) {
      _filteredQuizzes = _quizzes;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _filteredQuizzes = await _firebaseService.searchQuizzes(query);
      if (_filteredQuizzes.isEmpty) {
        _errorMessage = 'No quizzes found';
      }
    } catch (e) {
      _errorMessage = 'Search failed';
      print('Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Set current quiz (can be null to clear selection)
  void setCurrentQuiz(QuizModel? quiz) {
    _currentQuiz = quiz;
    notifyListeners();
  }

  /// Create new quiz and save to Firebase
  Future<bool> createQuiz({
    required String name,
    required String description,
    required List<Question> questions,
    required String userId,
    int difficulty = 3,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final quizId = await _firebaseService.createQuiz(
        name: name,
        description: description,
        questions: questions,
        userId: userId,
        difficulty: difficulty,
      );

      if (quizId != null) {
        await fetchAllQuizzes();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Failed to create quiz';
      print('Error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
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
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _firebaseService.updateQuiz(
        quizId: quizId,
        name: name,
        description: description,
        questions: questions,
        difficulty: difficulty,
      );

      if (success) {
        await fetchAllQuizzes();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Failed to update quiz';
      print('Error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Delete quiz by ID
  Future<bool> deleteQuiz(String quizId) async {
    try {
      final success = await _firebaseService.deleteQuiz(quizId);
      if (success) {
        await fetchAllQuizzes();
        // Clear current quiz if it was deleted
        if (_currentQuiz?.id == quizId) {
          _currentQuiz = null;
        }
        notifyListeners();
      }
      return success;
    } catch (e) {
      _errorMessage = 'Failed to delete quiz';
      print('Error: $e');
      return false;
    }
  }

  /// Get quizzes created by a specific user
  Future<List<QuizModel>> getQuizzesByUser(String userId) async {
    try {
      return await _firebaseService.getQuizzesByUser(userId);
    } catch (e) {
      print('Error: $e');
      return [];
    }
  }

  /// Get quiz by ID
  Future<QuizModel?> getQuizById(String quizId) async {
    try {
      return await _firebaseService.getQuizById(quizId);
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }

  /// Refresh quizzes list
  Future<void> refreshQuizzes() async {
    await fetchAllQuizzes();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  /// Sort quizzes by difficulty
  void sortByDifficulty() {
    _filteredQuizzes.sort((a, b) => a.difficulty.compareTo(b.difficulty));
    notifyListeners();
  }

  /// Sort quizzes by name
  void sortByName() {
    _filteredQuizzes.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
  }

  /// Sort quizzes by creation date (newest first)
  void sortByDate() {
    _filteredQuizzes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  /// Get total number of quizzes
  int getTotalQuizzes() => _quizzes.length;

  /// Get average difficulty across all quizzes
  double getAverageDifficulty() {
    if (_quizzes.isEmpty) return 0;
    final sum = _quizzes.fold<int>(0, (sum, quiz) => sum + quiz.difficulty);
    return sum / _quizzes.length;
  }

  Future<List<QuizModel>> showFavoriteQuizzes(String userId) async {
    try {
      final userDoc = await firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) return [];

      final favoriteIds = List<String>.from(
        userDoc.data()?['favoriteQuizes'] ?? [],
      );

      if (favoriteIds.isEmpty) return [];

      // fetch each quiz by ID using your existing method
      final quizFeatures = favoriteIds.map((id) => getQuizById(id));
      final results = await Future.wait(quizFeatures);

      // filter out any nulls like deleted quizes
      return results.whereType<QuizModel>().toList();
    } catch (e) {
      return [];
    }
  }
}

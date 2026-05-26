import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quizler/quiz_provider.dart';
import 'package:quizler/models/questions.dart';

/// QuestionInfo manages the current question state during a quiz
class QuestionInfo {
  int questionNumber = 0;
  int quizLength = 0;

  /// Initialize with quiz length
  QuestionInfo({int initialQuizLength = 0}) {
    quizLength = initialQuizLength;
  }

  /// Move to next question
  void nextQuestion() {
    if (questionNumber < quizLength - 1) {
      questionNumber++;
    }
  }

  /// Check if quiz is finished (on last question)
  bool isFinished() {
    return questionNumber >= quizLength - 1;
  }

  /// Reset to first question (useful for replaying)
  void resetQuestion() {
    questionNumber = 0;
  }

  /// Get current question text from question bank
  String getQuestionText(List<Question> questionBank) {
    if (questionBank.isEmpty || questionNumber >= questionBank.length) {
      return 'No question available';
    }
    return questionBank[questionNumber].q;
  }

  /// Get current question answer from question bank
  bool getQuestionAnswer(List<Question> questionBank) {
    if (questionBank.isEmpty || questionNumber >= questionBank.length) {
      return false;
    }
    return questionBank[questionNumber].a;
  }

  /// Get current question object
  Question? getCurrentQuestion(List<Question> questionBank) {
    if (questionBank.isEmpty || questionNumber >= questionBank.length) {
      return null;
    }
    return questionBank[questionNumber];
  }

  /// Get progress percentage (0.0 to 1.0)
  double getProgress() {
    if (quizLength == 0) return 0.0;
    return (questionNumber + 1) / quizLength;
  }

  /// Get question count string (e.g., "3/10")
  String getQuestionCount() {
    return '${questionNumber + 1}/$quizLength';
  }

  /// Get remaining questions
  int getRemainingQuestions() {
    return quizLength - questionNumber - 1;
  }
}

/// Helper class to access QuestionInfo with BuildContext
/// Usage: QuestionHelper.of(context)
class QuestionHelper {
  /// Get QuestionInfo from context (requires QuizProvider in tree)
  static QuestionInfo of(BuildContext context) {
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    if (quizProvider.currentQuiz == null) {
      throw Exception(
        'No quiz selected. Make sure QuizProvider.currentQuiz is set.',
      );
    }
    return QuestionInfo(
      initialQuizLength: quizProvider.currentQuiz!.questionBank.length,
    );
  }

  /// Get question bank safely
  static List<Question> getQuestionBank(BuildContext context) {
    try {
      final quizProvider = Provider.of<QuizProvider>(context, listen: false);
      return quizProvider.currentQuiz?.questionBank ?? [];
    } catch (e) {
      print('Error getting question bank: $e');
      return [];
    }
  }

  /// Get current question text
  static String getQuestionText(
    BuildContext context,
    QuestionInfo questionInfo,
  ) {
    final questionBank = getQuestionBank(context);
    return questionInfo.getQuestionText(questionBank);
  }

  /// Get current question answer
  static bool getQuestionAnswer(
    BuildContext context,
    QuestionInfo questionInfo,
  ) {
    final questionBank = getQuestionBank(context);
    return questionInfo.getQuestionAnswer(questionBank);
  }
}

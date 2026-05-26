import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quizler/quiz_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quizler/screens/quiz_generator.dart';

final auth = FirebaseAuth.instance;

class QuizEnd extends StatefulWidget {
  const QuizEnd({super.key});

  @override
  State<QuizEnd> createState() => _QuizEndState();
}

class _QuizEndState extends State<QuizEnd> {
  late double quizPercentage;
  late double numberOfQuestions;
  late int correctAnswers;
  late int incorrectAnswers;
  bool _isSavingScore = false;

  @override
  void initState() {
    super.initState();
    _calculateScores();
    _saveScoreToFirebase();
  }

  void _calculateScores() {
    numberOfQuestions = numberOfCorrectAnswers + numberOfIncorrectAnswers;
    quizPercentage = numberOfQuestions > 0
        ? (numberOfCorrectAnswers / numberOfQuestions * 100)
        : 0;
    correctAnswers = numberOfCorrectAnswers.toInt();
    incorrectAnswers = numberOfIncorrectAnswers.toInt();
  }

  /// Save quiz score to Firestore
  Future<void> _saveScoreToFirebase() async {
    final quizProvider = context.read<QuizProvider>();
    final currentQuiz = quizProvider.currentQuiz;

    if (currentQuiz == null) return;

    setState(() => _isSavingScore = true);

    try {
      await FirebaseFirestore.instance.collection('scores').add({
        'quizId': currentQuiz.id,
        'quizName': currentQuiz.name,
        'userId': auth.currentUser?.uid ?? '!!',
        'score': quizPercentage.toStringAsFixed(1),
        'correctAnswers': correctAnswers,
        'totalQuestions': numberOfQuestions.toInt(),
        'timestamp': FieldValue.serverTimestamp(),
        'difficulty': currentQuiz.difficulty,
      });
    } catch (e) {
      print('Error saving score: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to save score, but your attempt was recorded locally.',
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingScore = false);
      }
    }
  }

  /// Determine color based on score
  Color _getScoreColor() {
    if (quizPercentage >= 80) return Colors.green;
    if (quizPercentage >= 60) return Colors.orange;
    return Colors.red;
  }

  /// Determine performance message
  String _getPerformanceMessage() {
    if (quizPercentage >= 90) {
      return '🎉 Outstanding! Perfect performance!';
    } else if (quizPercentage >= 80) {
      return '✨ Great job! Very well done!';
    } else if (quizPercentage >= 70) {
      return '👍 Good effort! Keep practicing!';
    } else if (quizPercentage >= 60) {
      return '📚 Not bad! Review the material and try again.';
    } else {
      return '💪 Keep learning! You\'ll do better next time!';
    }
  }

  void _resetScores() {
    numberOfCorrectAnswers = 0;
    numberOfIncorrectAnswers = 0;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _resetScores();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.blue.shade600,
        appBar: AppBar(
          title: const Text('Quiz Score'),
          centerTitle: true,
          backgroundColor: Colors.blueGrey,
          elevation: 10,
          shadowColor: Colors.black,
          automaticallyImplyLeading: false,
        ),
        body: Consumer<QuizProvider>(
          builder: (context, quizProvider, _) {
            return SingleChildScrollView(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 30),

                    // Quiz Name
                    if (quizProvider.currentQuiz != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          quizProvider.currentQuiz!.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    const SizedBox(height: 30),

                    // Score Display Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Percentage Circle
                            Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _getScoreColor().withOpacity(0.2),
                                border: Border.all(
                                  color: _getScoreColor(),
                                  width: 4,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '${quizPercentage.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: _getScoreColor(),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Performance Message
                            Text(
                              _getPerformanceMessage(),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: _getScoreColor(),
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 30),

                            // Statistics
                            Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: [
                                  _buildStatRow(
                                    'Correct Answers',
                                    correctAnswers.toString(),
                                    Colors.green,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildStatRow(
                                    'Incorrect Answers',
                                    incorrectAnswers.toString(),
                                    Colors.red,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildStatRow(
                                    'Total Questions',
                                    numberOfQuestions.toInt().toString(),
                                    Colors.blueGrey,
                                  ),
                                  if (quizProvider.currentQuiz != null) ...[
                                    const SizedBox(height: 12),
                                    _buildStatRow(
                                      'Difficulty',
                                      '${quizProvider.currentQuiz!.difficulty}/5',
                                      Colors.orange,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Action Buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          // Play Again Button
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                elevation: 5,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                _resetScores();
                                Navigator.pushNamed(context, 'quiz_generator');
                              },
                              child: const Text(
                                'Play Again',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Find New Quiz Button
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueGrey,
                                elevation: 5,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                _resetScores();
                                Navigator.pushNamed(context, 'home_page');
                              },
                              child: const Text(
                                'Find New Quiz',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Home Button
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Colors.black,
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                _resetScores();
                                Navigator.pushNamed(context, 'home_page');
                              },
                              child: const Text(
                                'Home',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Saving Indicator
                    if (_isSavingScore)
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Saving your score...',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Build a statistic row
  Widget _buildStatRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

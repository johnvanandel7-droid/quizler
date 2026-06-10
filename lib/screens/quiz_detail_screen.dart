import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quizler/models/quiz_model.dart';
import 'package:quizler/quiz_provider.dart';

final _auth = FirebaseAuth.instance;
final _firestore = FirebaseFirestore.instance;

class QuizDetailScreen extends StatefulWidget {
  final QuizModel quiz;

  const QuizDetailScreen({super.key, required this.quiz});

  @override
  State<QuizDetailScreen> createState() => _QuizDetailScreenState();
}

class _QuizDetailScreenState extends State<QuizDetailScreen> {
  bool _isFavorited = false;
  bool _isTogglingFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkIfFavorited();
  }

  Future<void> _checkIfFavorited() async {
    if (_auth.currentUser == null) return;
    try {
      final doc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();
      if (doc.exists && mounted) {
        final favorites = List<String>.from(
          doc.data()?['favoriteQuizzes'] ?? [],
        );
        setState(() {
          _isFavorited = favorites.contains(widget.quiz.id);
        });
      }
    } catch (e) {
      print('Error checking favorites: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    if (_auth.currentUser == null) return;
    setState(() => _isTogglingFavorite = true);
    try {
      await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
        'favoriteQuizzes': _isFavorited
            ? FieldValue.arrayRemove([widget.quiz.id])
            : FieldValue.arrayUnion([widget.quiz.id]),
      });
      if (mounted) {
        setState(() => _isFavorited = !_isFavorited);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isFavorited ? 'Added to favorites!' : 'Removed from favorites!',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update favorites: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isTogglingFavorite = false);
    }
  }

  /// Difficulty label from 1-5 int
  String _difficultyLabel(int difficulty) {
    switch (difficulty) {
      case 1:
        return 'Very Easy';
      case 2:
        return 'Easy';
      case 3:
        return 'Medium';
      case 4:
        return 'Hard';
      case 5:
        return 'Very Hard';
      default:
        return 'Unknown';
    }
  }

  /// Difficulty color
  Color _difficultyColor(int difficulty) {
    switch (difficulty) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.lightGreen;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.deepOrange;
      case 5:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final quiz = widget.quiz;
    final isOwner = _auth.currentUser?.uid == quiz.createdBy;

    return Scaffold(
      backgroundColor: Colors.blue.shade600,
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        title: Text(quiz.name, overflow: TextOverflow.ellipsis),
        centerTitle: true,
        actions: [
          // Favorite toggle button
          _isTogglingFavorite
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                )
              : IconButton(
                  icon: Icon(
                    _isFavorited ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorited ? Colors.red : Colors.white,
                  ),
                  onPressed: _toggleFavorite,
                  tooltip: _isFavorited
                      ? 'Remove from favorites'
                      : 'Add to favorites',
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Quiz info card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quiz name
                  Text(
                    quiz.name,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  if (quiz.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      quiz.description,
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],

                  const Divider(height: 30),

                  // Stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatChip(
                        icon: Icons.quiz,
                        label: 'Questions',
                        value: quiz.questionBank.length.toString(),
                        color: Colors.blue,
                      ),
                      _buildStatChip(
                        icon: Icons.signal_cellular_alt,
                        label: 'Difficulty',
                        value: _difficultyLabel(quiz.difficulty),
                        color: _difficultyColor(quiz.difficulty),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Difficulty bar
                  Row(
                    children: [
                      const Text(
                        'Difficulty: ',
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: quiz.difficulty / 5,
                            minHeight: 10,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _difficultyColor(quiz.difficulty),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${quiz.difficulty}/5',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _difficultyColor(quiz.difficulty),
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 30),

                  // Created by / date
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Created ${_formatDate(quiz.createdAt)}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Question preview list
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[800],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preview (${quiz.questionBank.length} questions)',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Show first 3 questions as a teaser
                  ...quiz.questionBank.take(3).toList().asMap().entries.map((
                    entry,
                  ) {
                    final index = entry.key;
                    final question = entry.value;
                    // Strip MC encoding if present
                    final displayText = question.q.contains('|||')
                        ? question.q.split('|||').first
                        : question.q;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${index + 1}. ',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              displayText,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (quiz.questionBank.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '... and ${quiz.questionBank.length - 3} more',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Edit button — only visible to the quiz creator
            if (isOwner)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      'edit_quiz',
                      arguments: {'quizId': quiz.id, 'quizName': quiz.name},
                    );
                  },
                  icon: const Icon(Icons.edit, color: Colors.white),
                  label: const Text(
                    'Edit Quiz',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),

            // Start Quiz button
            SizedBox(
              height: 58,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.read<QuizProvider>().setCurrentQuiz(quiz);
                  Navigator.pushNamed(context, 'quiz_generator');
                },
                icon: const Icon(Icons.play_arrow, size: 28),
                label: const Text(
                  'Start Quiz',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 6,
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

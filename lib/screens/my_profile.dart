import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quizler/components/app_bar.dart';
import 'package:provider/provider.dart';
import 'package:quizler/components/section_header.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quizler/components/time_ago.dart';
import 'package:quizler/screens/edit_quiz_screen.dart';
import 'package:quizler/quiz_provider.dart';
import 'package:quizler/models/quiz_model.dart';

final auth = FirebaseAuth.instance;
final firestore = FirebaseFirestore.instance;

class MyProfile extends StatefulWidget {
  const MyProfile({super.key});

  @override
  State<MyProfile> createState() => _MyProfileState();
}

class _MyProfileState extends State<MyProfile> {
  bool showQuizes = false;
  bool showPlayingHistory = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ReusableAppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // header User name
            Padding(
              padding: EdgeInsets.all(15),
              child: Text(
                auth.currentUser?.email!.split('@')[0] ?? 'no_name',
                style: TextStyle(fontSize: 25),
              ),
            ),
            // quizes section header
            SectionHeader(
              title: 'My Quizes',
              isExpanded: showQuizes,
              onToggle: () {
                setState(() {
                  showQuizes = !showQuizes;
                });
              },
            ),
            if (showQuizes == true) const MyQuizesList(),
            if (showQuizes == false) const SizedBox(),
            // playing history section
            SectionHeader(
              title: 'My Playing History',
              isExpanded: showPlayingHistory,
              onToggle: () {
                setState(() {
                  showPlayingHistory = !showPlayingHistory;
                });
              },
            ),
            if (showPlayingHistory == true)
              const MyPlayingHistoryList()
            else
              const SizedBox(),
            SizedBox(height: 12),
            Text(
              'Favorite Quizes',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            FavoriteQuizesList(),
          ],
        ),
      ),
    );
  }
}

class FavoriteQuizesList extends StatelessWidget {
  const FavoriteQuizesList({super.key});

  @override
  Widget build(BuildContext context) {
    // Use StreamBuilder so favorites update in real time
    return StreamBuilder<DocumentSnapshot>(
      stream: firestore
          .collection('users')
          .doc(auth.currentUser!.uid)
          .snapshots(),

      builder: (context, userSnapshot) {
        // loading
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // error
        if (userSnapshot.hasError) {
          return Center(child: Text('Error: ${userSnapshot.error}'));
        }

        // no user doc
        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return const Center(child: Text('User data not found'));
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>;

        // FIX: check both field name spellings for backwards compatibility
        final List<dynamic> favoriteQuizzesDynamic =
            userData['favoriteQuizzes'] ?? userData['favoriteQuizes'] ?? [];

        final List<String> favoriteQuizzes = favoriteQuizzesDynamic
            .cast<String>();

        // empty favorites
        if (favoriteQuizzes.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: Text('No favorite quizzes yet')),
          );
        }

        return FutureBuilder<QuerySnapshot>(
          future: firestore
              .collection('quizzes')
              .where(FieldPath.documentId, whereIn: favoriteQuizzes)
              .get(),

          builder: (context, quizSnapshot) {
            // loading
            if (quizSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // error
            if (quizSnapshot.hasError) {
              return Center(child: Text('Error: ${quizSnapshot.error}'));
            }

            if (!quizSnapshot.hasData || quizSnapshot.data!.docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: Text('No quizzes found')),
              );
            }

            final docs = quizSnapshot.data!.docs;

            // FIX: use shrinkWrap instead of Expanded — Expanded crashes inside
            // SingleChildScrollView > Column
            return ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: docs.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                try {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final plays = (data['plays'] as int?) ?? 0;
                  final quizName = (data['name'] as String?) ?? 'Unnamed Quiz';
                  final createdAt =
                      (data['createdAt'] as Timestamp?) ?? Timestamp.now();

                  return QuizTemplate(
                    plays: plays,
                    quizName: quizName,
                    createdAt: createdAt,
                    quizId: doc.id,
                    quizDoc: doc,
                  );
                } catch (e) {
                  print(e);
                  return const SizedBox.shrink();
                }
              },
            );
          },
        );
      },
    );
  }
}

class MyPlayingHistoryList extends StatelessWidget {
  const MyPlayingHistoryList({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: firestore
          .collection('scores')
          .where('userId', isEqualTo: auth.currentUser!.uid)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        // loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // error state
        if (snapshot.hasError) {
          print(snapshot.error);
          return Center(
            child: Text(
              "Error: ${snapshot.error}",
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        // empty state
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text("No scores yet"),
            ),
          );
        }

        final docs = snapshot.data!.docs;

        // FIX: shrinkWrap instead of Expanded (Expanded crashes in SingleChildScrollView)
        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: docs.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            try {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              // FIX: score was saved as String, parse it safely
              final rawScore = data['score'];
              final percentage = rawScore is double
                  ? rawScore
                  : double.tryParse(rawScore.toString()) ?? 0.0;
              final quizName = (data['quizName'] as String?) ?? 'Unnamed Quiz';
              final timestamp =
                  (data['timestamp'] as Timestamp?) ?? Timestamp.now();
              final quizId = doc.id;

              return ScoreTemplate(
                quizName: quizName,
                timeStamp: timestamp,
                quizId: quizId,
                scorePercentage: percentage,
              );
            } catch (e) {
              print('Error parsing quiz: $e');
              return const SizedBox.shrink();
            }
          },
        );
      },
    );
  }
}

class MyQuizesList extends StatelessWidget {
  const MyQuizesList({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: firestore
          .collection('quizzes')
          .where('createdBy', isEqualTo: auth.currentUser!.uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        // loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // error state
        if (snapshot.hasError) {
          print(snapshot.error);
          return Center(
            child: Text(
              "Error: ${snapshot.error}",
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        // empty state
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text("No quizes yet"),
            ),
          );
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: docs.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            try {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              // Safely parse data with defaults
              final plays = (data['plays'] as int?) ?? 0;
              final quizName = (data['name'] as String?) ?? 'Unnamed Quiz';
              final createdAt =
                  (data['createdAt'] as Timestamp?) ?? Timestamp.now();
              final quizId = doc.id;

              return QuizTemplate(
                plays: plays,
                quizName: quizName,
                createdAt: createdAt,
                quizId: quizId,
                quizDoc: doc, // Pass doc for Play Quiz functionality
              );
            } catch (e) {
              print('Error parsing quiz: $e');
              return const SizedBox.shrink();
            }
          },
        );
      },
    );
  }
}

class ScoreTemplate extends StatefulWidget {
  final String quizName;
  final Timestamp timeStamp;
  final double scorePercentage;
  final String quizId;

  const ScoreTemplate({
    super.key,
    required this.quizId,
    required this.quizName,
    required this.scorePercentage,
    required this.timeStamp,
  });

  @override
  State<ScoreTemplate> createState() => _ScoreTemplateState();
}

class _ScoreTemplateState extends State<ScoreTemplate> {
  bool _isLoading = false;

  Future<void> _playQuiz(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final doc = await firestore
          .collection('quizzes')
          .doc(widget.quizId)
          .get();

      if (!doc.exists) {
        throw Exception('Quiz no longer exists');
      }

      final data = doc.data()!;
      final quiz = QuizModel.fromMap(data, doc.id);

      if (!mounted) return;

      context.read<QuizProvider>().setCurrentQuiz(quiz);

      Navigator.pushNamed(context, 'quiz_generator');
    } catch (e) {
      print('Error loading quiz: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading quiz'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blueGrey,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.quizName,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              Text(
                formatTimeAgo(widget.timeStamp),
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            'Your Score: ${widget.scorePercentage}%',
            style: const TextStyle(fontSize: 20),
          ),

          const SizedBox(height: 15),

          ElevatedButton(
            onPressed: _isLoading ? null : () => _playQuiz(context),
            child: _isLoading
                ? const CircularProgressIndicator()
                : const Text('Play Quiz'),
          ),
        ],
      ),
    );
  }
}

class QuizTemplate extends StatefulWidget {
  final int plays;
  final String quizName;
  final Timestamp createdAt;
  final String quizId;
  final QueryDocumentSnapshot quizDoc;

  const QuizTemplate({
    super.key,
    required this.plays,
    required this.quizName,
    required this.createdAt,
    required this.quizId,
    required this.quizDoc,
  });

  @override
  State<QuizTemplate> createState() => _QuizTemplateState();
}

class _QuizTemplateState extends State<QuizTemplate> {
  bool showStats = false;
  bool _isDeleting = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
        ),
        padding: EdgeInsets.all(10),
        child: Column(
          children: [
            // Quiz name and date
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.quizName,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Spacer(),
                Text(
                  formatTimeAgo(widget.createdAt),
                  style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Quiz stats section
            SectionHeader(
              title: 'quiz stats',
              isExpanded: showStats,
              onToggle: () {
                setState(() {
                  showStats = !showStats;
                });
              },
            ),
            if (showStats == true)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Played ${widget.plays}${widget.plays == 1 ? 'time' : 'times'}',
                  style: const TextStyle(color: Colors.grey, fontSize: 20),
                ),
              ),
            const SizedBox(height: 15),
            if (showStats == false) SizedBox(),
            const SizedBox(height: 10),

            // action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // edit quiz button
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditQuiz(
                          quizId: widget.quizId,
                          quizName: widget.quizName,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                ),

                // delete button
                ElevatedButton.icon(
                  onPressed: _isDeleting
                      ? null
                      : () {
                          _showDeleteConfirmation(context, widget.quizId);
                        },
                  icon: _isDeleting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Icon(Icons.delete),
                  label: const Text('Delete'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),

                // play quiz
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _playQuiz(context),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Icon(Icons.play_arrow),
                  label: Text('Play'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Play the quiz by loading it and navigating to quiz_generator
  Future<void> _playQuiz(BuildContext context) async {
    setState(() => _isLoading = true);

    try {
      // Convert Firestore document to QuizModel
      final data = widget.quizDoc.data() as Map<String, dynamic>;
      final quiz = QuizModel.fromMap(data, widget.quizId);

      if (!mounted) return;

      // Set current quiz and navigate
      context.read<QuizProvider>().setCurrentQuiz(quiz);
      Navigator.pushNamed(context, 'quiz_generator');
    } catch (e) {
      print('Error loading quiz for play: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading quiz: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Show delete confirmation dialog
  void _showDeleteConfirmation(BuildContext context, String quizId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Quiz?'),
          content: const Text(
            'Are you sure you want to delete this quiz? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteQuiz(quizId);
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  /// Delete quiz from Firebase with proper error handling
  Future<void> _deleteQuiz(String quizId) async {
    setState(() => _isDeleting = true);

    try {
      await firestore.collection('quizzes').doc(quizId).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quiz deleted successfully'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseException catch (e) {
      print('❌ Firebase Error: ${e.code} - ${e.message}');
      _showErrorSnackBar(_getFirebaseErrorMessage(e.code));
    } catch (e) {
      print('❌ Unexpected Error: $e');
      _showErrorSnackBar('An unexpected error occurred');
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  /// Show error snackbar
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Get user-friendly error message from Firebase error code
  String _getFirebaseErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'permission-denied':
        return 'Permission denied. You don\'t have permission to delete this quiz. Check Firestore security rules.';
      case 'not-found':
        return 'Quiz not found. It may have already been deleted.';
      case 'unauthenticated':
        return 'You are not authenticated. Please log in again.';
      case 'internal':
        return 'Internal Firestore error. Try again later.';
      case 'network-error':
        return 'Network error. Check your internet connection.';
      default:
        return 'Error deleting quiz: $errorCode. Check Firestore security rules.';
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quizler/components/app_bar.dart';
import 'package:quizler/components/section_header.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quizler/components/time_ago.dart';
import 'package:quizler/screens/edit_quiz_screen.dart';

final auth = FirebaseAuth.instance;
final firestore = FirebaseFirestore.instance;

class MyProfile extends StatefulWidget {
  const MyProfile({super.key});

  @override
  State<MyProfile> createState() => _MyProfileState();
}

class _MyProfileState extends State<MyProfile> {
  bool showQuizes = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ReusableAppBar(),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(15),
            child: Text(
              auth.currentUser?.email!.split('@')[0] ?? 'no_name',
              style: TextStyle(fontSize: 25),
            ),
          ),
          SectionHeader(
            title: 'My Quizes',
            isExpanded: showQuizes,
            onToggle: () {
              setState(() {
                showQuizes = !showQuizes;
              });
            },
          ),
          if (showQuizes == true) MyQuizesList(),
          if (showQuizes == false) SizedBox(),
        ],
      ),
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
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No quizes yet"));
        }

        final docs = snapshot.data!.docs; // already ordered by query

        List<QuizTemplate> quizes = [];

        for (var doc in docs) {
          try {
            final data = doc.data() as Map<String, dynamic>;

            final plays = data['plays'] as int;
            final quizName = data['name'] as String;
            final createdAt = data['createdAt'] as Timestamp;
            final quizId = doc.id;

            quizes.add(
              QuizTemplate(
                plays: plays,
                quizName: quizName,
                createdAt: createdAt,
                quizId: quizId,
              ),
            );
          } catch (e) {
            print(e);
          }
        }
        return Expanded(
          child: ListView(
            reverse: false,
            padding: const EdgeInsets.all(10),
            children: quizes,
          ),
        );
      },
    );
  }
}

class QuizTemplate extends StatefulWidget {
  final int plays;
  final String quizName;
  final Timestamp createdAt;
  final String quizId;

  const QuizTemplate({
    super.key,
    required this.plays,
    required this.quizName,
    required this.createdAt,
    required this.quizId,
  });

  @override
  State<QuizTemplate> createState() => _QuizTemplateState();
}

class _QuizTemplateState extends State<QuizTemplate> {
  bool showStats = false;

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
            Row(
              children: [
                Text(
                  widget.quizName,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Text(
                  formatTimeAgo(widget.createdAt),
                  style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                ),
              ],
            ),
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
              Text(
                'your quiz has been played ${widget.plays} times',
                style: TextStyle(color: Colors.grey, fontSize: 20),
              ),
            if (showStats == false) SizedBox(),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
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
                ElevatedButton.icon(
                  onPressed: () {
                    _showDeleteConfirmation(context, widget.quizId);
                  },
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
                _deleteQuiz(quizId, context);
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

  /// Delete quiz from Firebase
  Future<void> _deleteQuiz(String quizId, BuildContext context) async {
    try {
      await firestore.collection('quizzes').doc(quizId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quiz deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting quiz: $e')));
      }
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quizler/models/quiz_model.dart';
import 'package:quizler/models/questions.dart';

final firestore = FirebaseFirestore.instance;

class EditQuiz extends StatefulWidget {
  final String quizId;
  final String quizName;

  const EditQuiz({super.key, required this.quizId, required this.quizName});

  @override
  State<EditQuiz> createState() => _EditQuizState();
}

class _EditQuizState extends State<EditQuiz> {
  late TextEditingController quizNameController;
  late TextEditingController descriptionController;
  List<Question> questions = [];
  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    quizNameController = TextEditingController(text: widget.quizName);
    descriptionController = TextEditingController();
    _loadQuizData();
  }

  /// Load quiz data from Firebase
  Future<void> _loadQuizData() async {
    try {
      final doc = await firestore
          .collection('quizzes')
          .doc(widget.quizId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final desc = data['description'] as String? ?? '';
        final questionsList = data['questions'] as List? ?? [];

        setState(() {
          descriptionController.text = desc;
          questions = questionsList
              .map((q) => Question(q: q['q'] as String, a: q['a'] as bool))
              .toList();
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading quiz: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading quiz: $e')));
        Navigator.pop(context);
      }
    }
  }

  /// Save changes to Firebase
  Future<void> _saveChanges() async {
    if (quizNameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a quiz name')));
      return;
    }

    if (questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one question')),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      await firestore.collection('quizzes').doc(widget.quizId).update({
        'name': quizNameController.text,
        'description': descriptionController.text,
        'questions': questions.map((q) => q.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quiz updated successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving quiz: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  /// Add a new question
  void _addQuestion() {
    setState(() {
      questions.add(Question(q: '', a: false));
    });
  }

  /// Delete a question
  void _deleteQuestion(int index) {
    setState(() {
      questions.removeAt(index);
    });
  }

  /// Update question text
  void _updateQuestionText(int index, String text) {
    setState(() {
      questions[index] = Question(q: text, a: questions[index].a);
    });
  }

  /// Update question answer
  void _updateQuestionAnswer(int index, bool answer) {
    setState(() {
      questions[index] = Question(q: questions[index].q, a: answer);
    });
  }

  @override
  void dispose() {
    quizNameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Quiz')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Quiz'),
        backgroundColor: Colors.blueGrey,
        actions: [
          if (isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveChanges,
              tooltip: 'Save Changes',
            ),
        ],
      ),
      backgroundColor: Colors.blue[700],
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Quiz Details Section
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Container(
                color: Colors.blue,
                child: Column(
                  children: [
                    const Text(
                      'Quiz Details',
                      style: TextStyle(
                        fontSize: 30,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Quiz Name
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: TextField(
                        controller: quizNameController,
                        decoration: InputDecoration(
                          hintText: 'Quiz name',
                          hintStyle: const TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    // Description
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: TextField(
                        controller: descriptionController,
                        decoration: InputDecoration(
                          hintText: 'Quiz description',
                          hintStyle: const TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        maxLines: 3,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Questions Section
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Text(
                'Questions (${questions.length})',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            // Questions List
            ...questions.asMap().entries.map((entry) {
              int index = entry.key;
              Question question = entry.value;

              return Padding(
                padding: const EdgeInsets.all(15.0),
                child: Container(
                  color: Colors.blue,
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Question ${index + 1}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.red,
                              size: 24,
                            ),
                            onPressed: () => _deleteQuestion(index),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Question Text Input
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Enter question',
                          hintStyle: const TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onChanged: (value) => _updateQuestionText(index, value),
                      ),
                      const SizedBox(height: 15),

                      // Answer Selection
                      const Text(
                        'Correct Answer:',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // True Button
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () =>
                                  _updateQuestionAnswer(index, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: question.a
                                    ? Colors.green
                                    : Colors.green[300],
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                              ),
                              child: const Text(
                                'True',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),

                          // False Button
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () =>
                                  _updateQuestionAnswer(index, false),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: !question.a
                                    ? Colors.red
                                    : Colors.red[300],
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                              ),
                              child: const Text(
                                'False',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),

            const SizedBox(height: 20),
          ],
        ),
      ),

      // Bottom Action Buttons
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Add Question Button
            ElevatedButton.icon(
              onPressed: _addQuestion,
              icon: const Icon(Icons.add),
              label: const Text('Add Question'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[800],
              ),
            ),
            const SizedBox(width: 15),

            // Save Button
            ElevatedButton.icon(
              onPressed: isSaving ? null : _saveChanges,
              icon: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Icon(Icons.save),
              label: const Text('Save'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
          ],
        ),
      ),
    );
  }
}

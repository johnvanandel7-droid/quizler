import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quizler/models/questions.dart';

final firestore = FirebaseFirestore.instance;

// ---------------------------------------------------------------------------
// MC encoding helpers (mirrors quiz_generator.dart)
// Format: "question|||opt0|||opt1|||opt2|||opt3|||correctIndex"
// ---------------------------------------------------------------------------
bool _isMC(String q) => q.contains('|||');

Map<String, dynamic> _parseMC(String q) {
  final parts = q.split('|||');
  if (parts.length != 6) {
    return {
      'question': q,
      'options': ['', '', '', ''],
      'correctIndex': 0,
    };
  }
  return {
    'question': parts[0],
    'options': [parts[1], parts[2], parts[3], parts[4]],
    'correctIndex': int.tryParse(parts[5]) ?? 0,
  };
}

String _encodeMC(String question, List<String> options, int correctIndex) =>
    '$question|||${options[0]}|||${options[1]}|||${options[2]}|||${options[3]}|||$correctIndex';

// ---------------------------------------------------------------------------

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

  // Per-question controllers — for TF just [questionCtrl],
  // for MC [questionCtrl, opt0, opt1, opt2, opt3]
  List<List<TextEditingController>> questionControllers = [];

  // Whether each question slot is MC (true) or True/False (false)
  List<bool> isMCList = [];

  // For MC questions, which option index is the correct answer
  List<int> mcCorrectIndex = [];

  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    quizNameController = TextEditingController(text: widget.quizName);
    descriptionController = TextEditingController();
    _loadQuizData();
  }

  // -------------------------------------------------------------------------
  // Build per-question controller list from loaded questions
  // -------------------------------------------------------------------------
  void _rebuildControllers(List<Question> loaded) {
    for (final group in questionControllers) {
      for (final c in group) c.dispose();
    }
    questionControllers = [];
    isMCList = [];
    mcCorrectIndex = [];

    for (final q in loaded) {
      if (_isMC(q.q)) {
        final parsed = _parseMC(q.q);
        final opts = parsed['options'] as List<String>;
        questionControllers.add([
          TextEditingController(text: parsed['question'] as String),
          TextEditingController(text: opts[0]),
          TextEditingController(text: opts[1]),
          TextEditingController(text: opts[2]),
          TextEditingController(text: opts[3]),
        ]);
        isMCList.add(true);
        mcCorrectIndex.add(parsed['correctIndex'] as int);
      } else {
        questionControllers.add([TextEditingController(text: q.q)]);
        isMCList.add(false);
        mcCorrectIndex.add(0);
      }
    }
  }

  // -------------------------------------------------------------------------
  // Load from Firestore
  // -------------------------------------------------------------------------
  Future<void> _loadQuizData() async {
    try {
      final doc = await firestore
          .collection('quizzes')
          .doc(widget.quizId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final desc = data['description'] as String? ?? '';
        final raw = data['questions'] as List? ?? [];

        final loaded = raw
            .map((q) => Question(q: q['q'] as String, a: q['a'] as bool))
            .toList();

        setState(() {
          descriptionController.text = desc;
          questions = loaded;
          _rebuildControllers(loaded);
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading quiz: $e')));
        Navigator.pop(context);
      }
    }
  }

  // -------------------------------------------------------------------------
  // Convert controllers back to Question objects before saving
  // -------------------------------------------------------------------------
  List<Question> _buildQuestionsFromControllers() {
    final result = <Question>[];
    for (int i = 0; i < questions.length; i++) {
      if (isMCList[i]) {
        final encoded = _encodeMC(questionControllers[i][0].text, [
          questionControllers[i][1].text,
          questionControllers[i][2].text,
          questionControllers[i][3].text,
          questionControllers[i][4].text,
        ], mcCorrectIndex[i]);
        // MC questions store answer as true (unused — correctIndex is what matters)
        result.add(Question(q: encoded, a: true));
      } else {
        result.add(
          Question(q: questionControllers[i][0].text, a: questions[i].a),
        );
      }
    }
    return result;
  }

  // -------------------------------------------------------------------------
  // Save to Firestore
  // -------------------------------------------------------------------------
  Future<void> _saveChanges() async {
    if (quizNameController.text.trim().isEmpty) {
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
      final built = _buildQuestionsFromControllers();
      await firestore.collection('quizzes').doc(widget.quizId).update({
        'name': quizNameController.text.trim(),
        'description': descriptionController.text,
        'questions': built.map((q) => q.toMap()).toList(),
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
      if (mounted) setState(() => isSaving = false);
    }
  }

  // -------------------------------------------------------------------------
  // Add question
  // -------------------------------------------------------------------------
  void _addTrueFalseQuestion() {
    setState(() {
      questions.add(Question(q: '', a: false));
      questionControllers.add([TextEditingController()]);
      isMCList.add(false);
      mcCorrectIndex.add(0);
    });
  }

  void _addMCQuestion() {
    setState(() {
      questions.add(Question(q: '', a: true));
      questionControllers.add([
        TextEditingController(), // question
        TextEditingController(), // option A
        TextEditingController(), // option B
        TextEditingController(), // option C
        TextEditingController(), // option D
      ]);
      isMCList.add(true);
      mcCorrectIndex.add(0);
    });
  }

  // -------------------------------------------------------------------------
  // Delete question
  // -------------------------------------------------------------------------
  void _deleteQuestion(int index) {
    for (final c in questionControllers[index]) c.dispose();
    setState(() {
      questions.removeAt(index);
      questionControllers.removeAt(index);
      isMCList.removeAt(index);
      mcCorrectIndex.removeAt(index);
    });
  }

  // -------------------------------------------------------------------------
  // Toggle TF answer
  // -------------------------------------------------------------------------
  void _updateTFAnswer(int index, bool answer) {
    setState(() {
      questions[index] = Question(
        q: questionControllers[index][0].text,
        a: answer,
      );
    });
  }

  @override
  void dispose() {
    quizNameController.dispose();
    descriptionController.dispose();
    for (final group in questionControllers) {
      for (final c in group) c.dispose();
    }
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Build UI for a single True/False question
  // -------------------------------------------------------------------------
  Widget _buildTFQuestion(int index) {
    final question = questions[index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: questionControllers[index][0],
          decoration: _inputDecoration('Enter question'),
          style: const TextStyle(color: Colors.black, fontSize: 16),
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        const Text(
          'Correct Answer:',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _updateTFAnswer(index, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: question.a
                      ? Colors.green
                      : Colors.green[300],
                  padding: const EdgeInsets.symmetric(vertical: 14),
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
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _updateTFAnswer(index, false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: !question.a ? Colors.red : Colors.red[300],
                  padding: const EdgeInsets.symmetric(vertical: 14),
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
    );
  }

  // -------------------------------------------------------------------------
  // Build UI for a single Multiple Choice question
  // -------------------------------------------------------------------------
  Widget _buildMCQuestion(int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question text
        TextField(
          controller: questionControllers[index][0],
          decoration: _inputDecoration('Enter question'),
          style: const TextStyle(color: Colors.black, fontSize: 16),
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        const Text(
          'Options (tap the circle to mark correct answer):',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        // Four option fields with radio-style correct selector
        ...List.generate(4, (optIndex) {
          final letter = String.fromCharCode(65 + optIndex); // A B C D
          final isCorrect = mcCorrectIndex[index] == optIndex;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                // Correct answer selector
                GestureDetector(
                  onTap: () => setState(() => mcCorrectIndex[index] = optIndex),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCorrect ? Colors.green : Colors.white24,
                      border: Border.all(
                        color: isCorrect ? Colors.green : Colors.white54,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        letter,
                        style: TextStyle(
                          color: isCorrect ? Colors.white : Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Option text field
                Expanded(
                  child: TextField(
                    controller: questionControllers[index][optIndex + 1],
                    decoration: _inputDecoration('Option $letter'),
                    style: const TextStyle(color: Colors.black, fontSize: 15),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Shared input decoration
  // -------------------------------------------------------------------------
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------
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
            // Quiz Details card
            Padding(
              padding: const EdgeInsets.all(15),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: [
                    const Text(
                      'Quiz Details',
                      style: TextStyle(
                        fontSize: 28,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: quizNameController,
                      decoration: _inputDecoration('Quiz name'),
                      style: const TextStyle(color: Colors.black, fontSize: 18),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descriptionController,
                      decoration: _inputDecoration('Quiz description'),
                      maxLines: 3,
                      style: const TextStyle(color: Colors.black, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

            // Questions header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Text(
                'Questions (${questions.length})',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Question cards
            ...questions.asMap().entries.map((entry) {
              final index = entry.key;
              final ismc = isMCList[index];

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 8,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row: number + type badge + delete
                      Row(
                        children: [
                          Text(
                            'Q${index + 1}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Type badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: ismc
                                  ? Colors.purple[300]
                                  : Colors.teal[300],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              ismc ? 'Multiple Choice' : 'True / False',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.red,
                              size: 22,
                            ),
                            onPressed: () => _deleteQuestion(index),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Question body
                      ismc ? _buildMCQuestion(index) : _buildTFQuestion(index),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 100),
          ],
        ),
      ),

      // Bottom bar — two add buttons + save
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15, 8, 15, 8),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _addTrueFalseQuestion,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text(
                    'True/False',
                    style: TextStyle(fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal[600],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _addMCQuestion,
                  icon: const Icon(Icons.list, size: 18),
                  label: const Text(
                    'Multi Choice',
                    style: TextStyle(fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[600],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isSaving ? null : _saveChanges,
                  icon: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Icon(Icons.save, size: 18),
                  label: const Text('Save', style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

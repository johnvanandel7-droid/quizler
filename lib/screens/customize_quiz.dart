import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quizler/quiz_provider.dart';
import 'package:quizler/components/reusable_card.dart';
import 'package:quizler/constants.dart';
import 'package:quizler/models/questions.dart';
import 'package:firebase_auth/firebase_auth.dart';

final _auth = FirebaseAuth.instance;

class CustomizeQuiz extends StatefulWidget {
  const CustomizeQuiz({super.key});

  @override
  State<CustomizeQuiz> createState() => _CustomizeQuizState();
}

class _CustomizeQuizState extends State<CustomizeQuiz> {
  List<String> questionList = [];
  List<bool?> answerList = [];
  List<List<String>> multipleChoiceAnswers = [];
  List<int?> correctMCAnswerIndex = [];
  List<bool> isMultipleChoiceList = [];
  late TextEditingController quizNameController;
  late TextEditingController quizDescriptionController;
  final List<Widget> _questionWidgets = [];

  @override
  void initState() {
    super.initState();
    quizNameController = TextEditingController();
    quizDescriptionController = TextEditingController();
    _addQuestion();
  }

  @override
  void dispose() {
    quizNameController.dispose();
    quizDescriptionController.dispose();
    super.dispose();
  }

  Future<void> saveQuiz() async {
    if (quizNameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a quiz name')));
      return;
    }

    // Convert questionList and answerList to Question objects
    List<Question> questions = [];

    for (int i = 0; i < questionList.length; i++) {
      if (questionList[i].isEmpty) continue;

      // For true and false questions
      if (!isMultipleChoiceList[i]) {
        if (answerList[i] != null) {
          questions.add(Question(q: questionList[i], a: answerList[i]!));
        }
      }
      // For multiple choice questions
      else {
        if (multipleChoiceAnswers[i].isNotEmpty &&
            correctMCAnswerIndex[i] != null) {
          // Store MC data as special question format
          String mcQuestion =
              '${questionList[i]}|||${multipleChoiceAnswers[i].join('|||')}|||${correctMCAnswerIndex[i]}';
          questions.add(
            Question(q: mcQuestion, a: true),
          ); // Use 'a' as placeholder
        }
      }
    }

    if (questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please add at least one question')),
      );
      return;
    }

    final quizProvider = context.read<QuizProvider>();

    final success = await quizProvider.createQuiz(
      name: quizNameController.text,
      description: quizDescriptionController.text,
      questions: questions,
      userId: _auth.currentUser?.uid ?? 'user not logged in',
      difficulty: 3,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quiz saved successfully!')),
        );
        Navigator.pushNamed(context, 'home_page');
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to save quiz')));
      }
    }
  }

  void _addQuestion() {
    setState(() {
      final index = _questionWidgets.length;
      questionList.add('');
      answerList.add(null);
      multipleChoiceAnswers.add(['', '', '', '']);
      correctMCAnswerIndex.add(null);
      isMultipleChoiceList.add(false);

      _questionWidgets.add(
        NewQuestionTemplate(
          key: UniqueKey(),
          questionNumber: index + 1,
          onQuestionChanged: (value) {
            questionList[index] = value;
          },
          onAnswerSelected: (isCorrect) {
            answerList[index] = isCorrect;
          },
          onMultipleChoiceChanged: (answers, correctIndex) {
            multipleChoiceAnswers[index] = answers;
            correctMCAnswerIndex[index] = correctIndex;
          },
          onTypeChanged: (isMultipleChoice) {
            isMultipleChoiceList[index] = isMultipleChoice;
          },
          onDelete: () {
            setState(() {
              questionList.removeAt(index);
              answerList.removeAt(index);
              multipleChoiceAnswers.removeAt(index);
              correctMCAnswerIndex.removeAt(index);
              isMultipleChoiceList.removeAt(index);
              _questionWidgets.removeAt(index);
            });
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
          title: const Text('Create Quiz'),
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              color: Colors.black,
              onPressed: () {
                Navigator.pushNamed(context, 'home_page');
              },
            ),
          ],
        ),
        backgroundColor: Colors.blue[700],
        body: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: Container(
                  color: Colors.blue,
                  child: Column(
                    children: [
                      const Text(
                        'Quiz Details',
                        style: TextStyle(fontSize: 30, color: Colors.black),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: TextField(
                          controller: quizNameController,
                          decoration: kTextFieldDecoration2.copyWith(
                            hintText: 'Quiz name',
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: TextField(
                          controller: quizDescriptionController,
                          decoration: kTextFieldDecoration2.copyWith(
                            hintText: 'Quiz description',
                          ),
                          maxLines: 3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ..._questionWidgets,
              const SizedBox(height: 20),
            ],
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _addQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                ),
                icon: Icon(Icons.add),
                label: Text(
                  'Add Question',
                  style: TextStyle(color: Colors.grey[700], fontSize: 15),
                ),
              ),
              const SizedBox(width: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                ),
                onPressed: saveQuiz,
                icon: Icon(Icons.save),
                label: const Text(
                  'Save',
                  style: TextStyle(color: Colors.black, fontSize: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NewQuestionTemplate extends StatefulWidget {
  final int questionNumber;
  final Function(String) onQuestionChanged;
  final Function(bool) onAnswerSelected;
  final Function(List<String>, int?) onMultipleChoiceChanged;
  final Function(bool) onTypeChanged;
  final VoidCallback onDelete;

  const NewQuestionTemplate({
    super.key,
    required this.questionNumber,
    required this.onQuestionChanged,
    required this.onAnswerSelected,
    required this.onMultipleChoiceChanged,
    required this.onTypeChanged,
    required this.onDelete,
  });

  @override
  State<NewQuestionTemplate> createState() => _NewQuestionTemplateState();
}

class _NewQuestionTemplateState extends State<NewQuestionTemplate> {
  bool? selectedAnswer;
  bool isMultipleChoice = false;
  List<String> mcAnswers = ['', '', '', ''];
  int? correctMCIndex;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Container(
        color: Colors.blue,
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question type toggle
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Question ${widget.questionNumber}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 24),
                    onPressed: widget.onDelete,
                  ),
                ],
              ),
            ),

            // Question type selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: !isMultipleChoice
                          ? null
                          : () {
                              setState(() => isMultipleChoice = false);
                              widget.onTypeChanged(false);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: !isMultipleChoice
                            ? Colors.green
                            : Colors.grey[400],
                      ),
                      child: const Text('True/False'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isMultipleChoice
                          ? null
                          : () {
                              setState(() => isMultipleChoice = true);
                              widget.onTypeChanged(true);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isMultipleChoice
                            ? Colors.orange
                            : Colors.grey[400],
                      ),
                      child: const Text('Multiple Choice'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),

            // Question text input
            Padding(
              padding: const EdgeInsets.all(15),
              child: TextField(
                decoration: const InputDecoration(
                  icon: Icon(Icons.question_mark),
                  hintText: 'Enter your question',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                onChanged: widget.onQuestionChanged,
              ),
            ),

            // True/False answers
            if (!isMultipleChoice) ...[
              const Padding(
                padding: EdgeInsets.all(15),
                child: Text(
                  'Correct Answer',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() => selectedAnswer = true);
                          widget.onAnswerSelected(true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedAnswer == true
                              ? Colors.green[600]
                              : Colors.green[200],
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(15),
                          child: Text(
                            'True',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() => selectedAnswer = false);
                          widget.onAnswerSelected(false);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedAnswer == false
                              ? Colors.red[600]
                              : Colors.red[200],
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(15),
                          child: Text(
                            'False',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Multiple choice answers
            if (isMultipleChoice) ...[
              const Padding(
                padding: EdgeInsets.all(15),
                child: Text(
                  'Answer Options',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: List.generate(4, (index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText:
                                    'Option ${String.fromCharCode(65 + index)}',
                                hintStyle: const TextStyle(color: Colors.grey),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                              ),
                              onChanged: (value) {
                                mcAnswers[index] = value;
                                widget.onMultipleChoiceChanged(
                                  mcAnswers,
                                  correctMCIndex,
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () {
                              setState(() => correctMCIndex = index);
                              widget.onMultipleChoiceChanged(mcAnswers, index);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: correctMCIndex == index
                                  ? Colors.green
                                  : Colors.grey[400],
                            ),
                            child: const Text(
                              '✓',
                              style: TextStyle(fontSize: 20),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

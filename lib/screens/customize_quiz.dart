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
      if (questionList[i].isNotEmpty && answerList[i] != null) {
        questions.add(Question(q: questionList[i], a: answerList[i]!));
      }
    }

    if (questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one question')),
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
          onDelete: () {
            setState(() {
              questionList.removeAt(index);
              answerList.removeAt(index);
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
            ],
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: _addQuestion,
                style: kButtonStyle,
                child: Text(
                  'Add Question',
                  style: TextStyle(color: Colors.grey[700], fontSize: 15),
                ),
              ),
              const SizedBox(width: 40),
              TextButton(
                style: kButtonStyle,
                onPressed: saveQuiz,
                child: const Text(
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
  final VoidCallback onDelete;

  const NewQuestionTemplate({
    super.key,
    required this.questionNumber,
    required this.onQuestionChanged,
    required this.onAnswerSelected,
    required this.onDelete,
  });

  @override
  State<NewQuestionTemplate> createState() => _NewQuestionTemplateState();
}

class _NewQuestionTemplateState extends State<NewQuestionTemplate> {
  bool? selectedAnswer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Container(
        color: Colors.blue,
        width: double.infinity,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 30),
                    onPressed: widget.onDelete,
                  ),
                  const SizedBox(width: 20),
                  Text(
                    'Question ${widget.questionNumber}',
                    style: const TextStyle(fontSize: 15),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: TextField(
                decoration: const InputDecoration(
                  icon: Icon(Icons.question_mark),
                  hintText: 'Question',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                onChanged: widget.onQuestionChanged,
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(15),
              child: Text(
                'Answer',
                style: TextStyle(color: Colors.grey, fontSize: 20),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ReusableCard(
                      onPress: () {
                        setState(() => selectedAnswer = true);
                        widget.onAnswerSelected(true);
                      },
                      colour: selectedAnswer == true
                          ? kTrueActiveCardColor
                          : kTrueInactiveCardColor,
                      cardChild: const Icon(Icons.check),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: ReusableCard(
                      onPress: () {
                        setState(() => selectedAnswer = false);
                        widget.onAnswerSelected(false);
                      },
                      colour: selectedAnswer == false
                          ? kFalseActiveCardColor
                          : kFalseInactiveCardColor,
                      cardChild: const Icon(Icons.close),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

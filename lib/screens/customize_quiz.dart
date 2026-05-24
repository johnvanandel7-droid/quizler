import 'package:flutter/material.dart';
import 'package:quizler/components/reusable_card.dart';
import 'package:quizler/constants.dart';

class CustomizeQuiz extends StatefulWidget {
  const CustomizeQuiz({super.key});

  @override
  State<CustomizeQuiz> createState() => _CustomizeQuizState();
}

class _CustomizeQuizState extends State<CustomizeQuiz> {
  // Use typed lists for better safety and functionality
  List<String> questionList = [];
  List<bool?> answerList = []; // Nullable to handle unselected answers

  // List of widgets with unique keys for state preservation
  final List<Widget> _questionWidgets = [];

  @override
  void initState() {
    super.initState();
    _addQuestion();
  }

  void saveQuiz() {

  }

  void _addQuestion() {
    setState(() {
      final index = _questionWidgets.length;
      questionList.add(''); // Add empty question
      answerList.add(null); // Add unselected answer
      _questionWidgets.add(
        NewQuestionTemplate(
          key: UniqueKey(), // Unique key to preserve state
          questionNumber: index + 1,
          onQuestionChanged: (value) {
            questionList[index] = value; // Update at specific index
          },
          onAnswerSelected: (isCorrect) {
            answerList[index] = isCorrect; // Update at specific index
          },
          onDelete: () {
            setState(() {
              questionList.removeAt(index);
              answerList.removeAt(index);
              _questionWidgets.removeAt(index);
              // Re-index remaining widgets
              for (int i = 0; i < _questionWidgets.length; i++) {
                
              }
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
          title: const Text('Make Your Own Quiz'),
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              color: Colors.black,
              onPressed: () {
                setState(() {
                  questionList.remove;
                  answerList.remove;
                  _questionWidgets.remove;
                  // Re-index remaining widgets
                  for (int i = 0; i < _questionWidgets.length; i++) {
                
                  }
                });
                Navigator.pushNamed(context, 'home_page');
              },
            )
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
                  child: const Column(
                    children: [
                      Text(
                        'Quiz Name',
                        style: TextStyle(
                          fontSize: 30,
                          color: Colors.black,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(20),
                        child: TextField(
                          decoration: kTextFieldDecoration2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Spread the list directly (fixes the error and improves efficiency)
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
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 40),
              TextButton(
                style: kButtonStyle,
                onPressed: () {
                  if (questionList.any((q) => q.isEmpty) || answerList.contains(null)) {
                    // Show error if incomplete
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please complete all questions and answers.')),
                    );
                  } 
                  else {
                    saveQuiz();
                    Navigator.pushNamed(context, 'home_page');
                  }
                },
                child: const Text(
                  'Save',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
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
  // ignore: library_private_types_in_public_api
  _NewQuestionTemplateState createState() => _NewQuestionTemplateState();
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
        height: 300,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.red,
                      size: 30.0,
                    ),
                    onPressed: widget.onDelete, // Fixed: Now invokes the callback
                  ),
                  const SizedBox(width: 20),
                  Text(
                    'Question ${widget.questionNumber}',
                    style: const TextStyle(
                      fontSize: 15,
                    ),
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
                  hintStyle: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w300,
                  ),
                  border: OutlineInputBorder(),
                  focusColor: Colors.blueGrey,
                  iconColor: Colors.black,
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
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 20,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: ReusableCard(
                      onPress: () {
                        setState(() {
                          selectedAnswer = true;
                        });
                        widget.onAnswerSelected(true); // Notify parent
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
                        setState(() {
                          selectedAnswer = false;
                        });
                        widget.onAnswerSelected(false); // Notify parent
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
          ],
        ),
      ),
    );
  }
}
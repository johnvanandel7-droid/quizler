import 'package:flutter/material.dart';
import 'package:quizler/question_info.dart';
import 'home_page.dart';

double numberOfCorrectAnswers = 0;
double numberOfIncorrectAnswers = 0;
// ignore: non_constant_identifier_names
QuestionInfo question_info = QuestionInfo();
HomePage homePage = HomePage();

class QuizPageGenerator extends StatefulWidget {

  final String appBarText;
  const QuizPageGenerator({super.key, required this.appBarText});

  @override

  // ignore: library_private_types_in_public_api
  _QuizPageGeneratorState createState() => _QuizPageGeneratorState();
}

class _QuizPageGeneratorState extends State<QuizPageGenerator> {

  List <Icon> scoreKeeper = [];

  void checkAnswer(bool userPickedAnswer) {
    bool correctAnswer = question_info.getQuestionAnswer();

    setState(() {

      if (question_info.isFinished() == true) {
        Navigator.pushNamed(context, 'quiz_end');
        scoreKeeper = [];
        question_info.questionNumber = 0;
      }

      else {
        if (userPickedAnswer == correctAnswer) {
          numberOfCorrectAnswers ++;
          scoreKeeper.add(Icon(
            Icons.check,
            color: Colors.green,
          ));
        } 
        else {
          numberOfIncorrectAnswers ++;
          scoreKeeper.add(Icon(
            Icons.close,
            color: Colors.red,
          ));
        }
        question_info.nextQuestion();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Center(
          child: Text(widget.appBarText)
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                question_info.questionNumber = 0;
              });
              Navigator.pushNamed(
                context,
                'home_page'
              );
            }, 
            icon: Icon(
              Icons.home,
              color: Colors.black,
              size: 20,
          )
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            flex: 5,
            child: Padding(
              padding: EdgeInsets.all(10.0),
              child: Center(
                child: Text(
                  question_info.getQuestionText(currentQuiz),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 25.0,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(15.0),
              child: TextButton(
                style: ButtonStyle(
                  shadowColor: WidgetStateProperty.all(Colors.black),
                  backgroundColor: WidgetStateProperty.all(Colors.green),
                ),
                child: Text(
                  'True',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.0,
                  ),
                ),
                onPressed: () {
                  // the user chose True
                  checkAnswer(true);
                },
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(15.0),
              child: TextButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.red),
                  shadowColor: WidgetStateProperty.all(Colors.black),
                ),
                child: Text(
                  'False',
                  style: TextStyle(
                    fontSize: 20.0,
                    color: Colors.white,
                  ),
                ),
                onPressed: () {
                  //The user picked false.
                  checkAnswer(false);
                },
              ),
            ),
          ),
          Row(
            children: scoreKeeper,
          ),
          SizedBox(height: 50)
        ],
      ),
    );
  }
}
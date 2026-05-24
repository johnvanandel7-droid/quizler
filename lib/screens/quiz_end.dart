import 'package:flutter/material.dart';
import 'package:quizler/question_info.dart';
import 'package:quizler/screens/home_page.dart';
import 'package:quizler/screens/quiz_generator.dart';
import 'package:quizler/constants.dart';

// ignore: non_constant_identifier_names
QuestionInfo question_info = QuestionInfo();
QuizPageGenerator quizGenerator = QuizPageGenerator(appBarText: '');

class QuizEnd extends StatefulWidget {
  const QuizEnd({super.key});

  @override
  State<QuizEnd> createState() => _QuizEndState();
}

class _QuizEndState extends State<QuizEnd> {

  @override
  Widget build(BuildContext context) {
    // Compute the percentage directly here using the global variables
    double numberOfQuestions = numberOfCorrectAnswers + numberOfIncorrectAnswers;
    double quizPercentage = numberOfQuestions > 0 ? (numberOfCorrectAnswers / numberOfQuestions * 100) : 0;
    
    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: AppBar(
        title: Text('quiz score'),
        shadowColor: Colors.black,
        elevation: 10,
        backgroundColor: Colors.blueGrey,
      ), 
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  color:Colors.grey
                ),
                child: Text(
                  'You got ${quizPercentage.toStringAsFixed(1)} percent',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            TextButton(
              style: kButtonStyle,
              onPressed:() {
                Navigator.pushNamed(context, 'quiz_generator');
                numberOfCorrectAnswers = 0;
                numberOfIncorrectAnswers = 0;
              },
              child: Text(
                'Play Again',
                style: TextStyle(
                  fontSize: 25,
                  color:Colors.black,
                )
              )
            ),
            SizedBox(height: 15),
            TextButton(
              style: kButtonStyle,
              onPressed: () {
                Navigator.pushNamed(context, 'home_page');
                numberOfCorrectAnswers = 0;
                numberOfIncorrectAnswers = 0;
                currentQuiz = null;  // Reset currentQuiz to null (or remove this line if not needed)
              }, 
              child: Text(
                'Find a new quiz',
                style: TextStyle(
                  fontSize: 25,
                  color:Colors.black,
                )
              )
            )
          ],
        ),
      )      
    );
  }
}
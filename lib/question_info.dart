import 'package:quizler/screens/home_page.dart';

dynamic quizLength = currentQuiz.questionBank.length;
dynamic questionAnswer = currentQuiz.questionBank;

class QuestionInfo {
  int questionNumber = 0;

  void nextQuestion() {
    if (questionNumber < quizLength - 1) {
      questionNumber++;
    }
  }

  bool isFinished() {
    if (questionNumber >= quizLength - 1) {
      return true;
    } else {
      return false;
    }
  }

  String getQuestionText(dynamic questionText) {
    return questionText.questionBank[questionNumber].q;
  }

  bool getQuestionAnswer() {
    return questionAnswer[questionNumber].a;
  }
}

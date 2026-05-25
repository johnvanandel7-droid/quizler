import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quizler/quiz_provider.dart';
import 'home_page.dart';
 
double numberOfCorrectAnswers = 0;
double numberOfIncorrectAnswers = 0;
 
class QuestionInfo {
  int questionNumber = 0;
  int quizLength = 0;
 
  void nextQuestion() {
    if (questionNumber < quizLength - 1) {
      questionNumber++;
    }
  }
 
  bool isFinished() {
    return questionNumber >= quizLength - 1;
  }
 
  String getQuestionText() {
    final context = navigatorKey.currentContext;
    if (context == null) return '';
    
    final currentQuiz = Provider.of<QuizProvider>(
      context,
      listen: false,
    ).currentQuiz;
 
    if (currentQuiz != null && questionNumber < currentQuiz.questionBank.length) {
      return currentQuiz.questionBank[questionNumber].q;
    }
    return '';
  }
 
  bool getQuestionAnswer() {
    final context = navigatorKey.currentContext;
    if (context == null) return false;
    
    final currentQuiz = Provider.of<QuizProvider>(
      context,
      listen: false,
    ).currentQuiz;
 
    if (currentQuiz != null && questionNumber < currentQuiz.questionBank.length) {
      return currentQuiz.questionBank[questionNumber].a;
    }
    return false;
  }
}
 
// Global navigator key to access context
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
 
class QuizPageGenerator extends StatefulWidget {
  const QuizPageGenerator({super.key});
 
  @override
  State<QuizPageGenerator> createState() => _QuizPageGeneratorState();
}
 
class _QuizPageGeneratorState extends State<QuizPageGenerator> {
  List<Icon> scoreKeeper = [];
  late QuestionInfo questionInfo;
 
  @override
  void initState() {
    super.initState();
    questionInfo = QuestionInfo();
    
    final quizProvider = context.read<QuizProvider>();
    if (quizProvider.currentQuiz != null) {
      questionInfo.quizLength = quizProvider.currentQuiz!.questionBank.length;
    }
  }
 
  void checkAnswer(bool userPickedAnswer) {
    final quizProvider = context.read<QuizProvider>();
    final currentQuiz = quizProvider.currentQuiz;
 
    if (currentQuiz == null) return;
 
    bool correctAnswer = currentQuiz.questionBank[questionInfo.questionNumber].a;
 
    setState(() {
      if (questionInfo.isFinished()) {
        Navigator.pushNamed(context, 'quiz_end');
        scoreKeeper = [];
        questionInfo.questionNumber = 0;
      } else {
        if (userPickedAnswer == correctAnswer) {
          numberOfCorrectAnswers++;
          scoreKeeper.add(
            const Icon(Icons.check, color: Colors.green),
          );
        } else {
          numberOfIncorrectAnswers++;
          scoreKeeper.add(
            const Icon(Icons.close, color: Colors.red),
          );
        }
        questionInfo.nextQuestion();
      }
    });
  }
 
  @override
  Widget build(BuildContext context) {
    return Consumer<QuizProvider>(
      builder: (context, quizProvider, _) {
        final currentQuiz = quizProvider.currentQuiz;
 
        if (currentQuiz == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Quiz'),
              backgroundColor: Colors.blueGrey,
            ),
            body: const Center(
              child: Text('No quiz selected'),
            ),
          );
        }
 
        String questionText = '';
        if (questionInfo.questionNumber < currentQuiz.questionBank.length) {
          questionText = currentQuiz.questionBank[questionInfo.questionNumber].q;
        }
 
        return Scaffold(
          backgroundColor: Colors.blue,
          appBar: AppBar(
            backgroundColor: Colors.blueGrey,
            title: Center(child: Text(currentQuiz.name)),
            actions: [
              IconButton(
                onPressed: () {
                  setState(() {
                    questionInfo.questionNumber = 0;
                    numberOfCorrectAnswers = 0;
                    numberOfIncorrectAnswers = 0;
                    scoreKeeper = [];
                  });
                  Navigator.pushNamed(context, 'home_page');
                },
                icon: const Icon(
                  Icons.home,
                  color: Colors.black,
                  size: 20,
                ),
              ),
            ],
          ),
          body: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Question display
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Center(
                    child: Text(
                      questionText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 25.0,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              // True button
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: TextButton(
                    style: ButtonStyle(
                      shadowColor: WidgetStateProperty.all(Colors.black),
                      backgroundColor: WidgetStateProperty.all(Colors.green),
                    ),
                    child: const Text(
                      'True',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20.0,
                      ),
                    ),
                    onPressed: () {
                      checkAnswer(true);
                    },
                  ),
                ),
              ),
              // False button
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: TextButton(
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(Colors.red),
                      shadowColor: WidgetStateProperty.all(Colors.black),
                    ),
                    child: const Text(
                      'False',
                      style: TextStyle(
                        fontSize: 20.0,
                        color: Colors.white,
                      ),
                    ),
                    onPressed: () {
                      checkAnswer(false);
                    },
                  ),
                ),
              ),
              // Score keeper
              Row(children: scoreKeeper),
              const SizedBox(height: 50),
            ],
          ),
        );
      },
    );
  }
}
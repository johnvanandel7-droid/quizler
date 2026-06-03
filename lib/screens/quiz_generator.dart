import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quizler/models/questions.dart';
import 'package:quizler/quiz_provider.dart';
import 'package:quizler/question_info.dart';

// Global score tracking (shared with quiz_end.dart)
double numberOfCorrectAnswers = 0;
double numberOfIncorrectAnswers = 0;

class QuizPageGenerator extends StatefulWidget {
  const QuizPageGenerator({super.key});

  @override
  State<QuizPageGenerator> createState() => _QuizPageGeneratorState();
}

class _QuizPageGeneratorState extends State<QuizPageGenerator> {
  late QuestionInfo questionInfo;
  late List<Question> shuffledQuestions;
  List<Icon> scoreKeeper = [];
  bool _isAnswered = false;

  @override
  void initState() {
    super.initState();
    _initializeQuiz();
  }

  /// Initialize quiz with current quiz from provider
  void _initializeQuiz() {
    final quizProvider = context.read<QuizProvider>();
    final currentQuiz = quizProvider.currentQuiz;

    if (currentQuiz == null) {
      // Navigate back if no quiz selected
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamed(context, 'home_page');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No quiz selected')));
      });
      return;
    }

    // create a copy of the questions and shuffle them
    shuffledQuestions = List.from(currentQuiz.questionBank);
    shuffledQuestions.shuffle();

    // Initialize question info with quiz length
    questionInfo = QuestionInfo(initialQuizLength: shuffledQuestions.length);
  }

  /// Check user's answer against correct answer
  void checkAnswer(bool userPickedAnswer) {
    if (_isAnswered) return; // Prevent multiple answers for same question

    final quizProvider = context.read<QuizProvider>();
    final currentQuiz = quizProvider.currentQuiz;

    if (currentQuiz == null || shuffledQuestions.isEmpty) {
      return;
    }

    // Get correct answer for current question
    final correctAnswer = questionInfo.getQuestionAnswer(shuffledQuestions);

    setState(() {
      _isAnswered = true; // Disable further answers

      if (userPickedAnswer == correctAnswer) {
        numberOfCorrectAnswers++;
        scoreKeeper.add(const Icon(Icons.check, color: Colors.green));
      } else {
        numberOfIncorrectAnswers++;
        scoreKeeper.add(const Icon(Icons.close, color: Colors.red));
      }

      // Small delay before moving to next question
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            if (questionInfo.isFinished()) {
              // Quiz completed - navigate to results
              Navigator.pushNamed(context, 'quiz_end');
              scoreKeeper = [];
              questionInfo.resetQuestion();
            } else {
              // Move to next question
              questionInfo.nextQuestion();
              _isAnswered = false;
            }
          });
        }
      });
    });
  }

  /// Build answer button with consistent styling
  Widget _buildAnswerButton({
    required String label,
    required Color color,
    required bool answered,
    required bool isCorrect,
    required VoidCallback onPressed,
  }) {
    final isSelected = answered && (label == 'True' ? isCorrect : !isCorrect);

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: TextButton(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(
              isSelected ? color.withOpacity(0.8) : color,
            ),
            shadowColor: WidgetStateProperty.all(Colors.black),
            elevation: WidgetStateProperty.all(answered ? 0 : 5),
          ),
          onPressed: answered ? null : onPressed,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<QuizProvider>(
      builder: (context, quizProvider, _) {
        final currentQuiz = quizProvider.currentQuiz;

        // Show error if no quiz selected
        if (currentQuiz == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Quiz'),
              backgroundColor: Colors.blueGrey,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No quiz selected'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, 'home_page'),
                    child: const Text('Back to Home'),
                  ),
                ],
              ),
            ),
          );
        }

        // Get current question text safely
        final questionText = questionInfo.getQuestionText(shuffledQuestions);

        return Scaffold(
          backgroundColor: Colors.blue,
          appBar: AppBar(
            backgroundColor: Colors.blueGrey,
            title: Text(
              currentQuiz.name,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            centerTitle: true,
            elevation: 10,
            shadowColor: Colors.black,
            actions: [
              // Progress indicator in app bar
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    questionInfo.getQuestionCount(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  _confirmExit(context);
                },
                icon: const Icon(Icons.home, color: Colors.white, size: 24),
                tooltip: 'Exit Quiz',
              ),
            ],
          ),
          body: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: questionInfo.getProgress(),
                  minHeight: 8,
                  backgroundColor: Colors.white30,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withOpacity(0.8),
                  ),
                ),
              ),

              // Question display
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
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
              _buildAnswerButton(
                label: 'True',
                color: Colors.green,
                answered: _isAnswered,
                isCorrect: true,
                onPressed: () => checkAnswer(true),
              ),

              // False button
              _buildAnswerButton(
                label: 'False',
                color: Colors.red,
                answered: _isAnswered,
                isCorrect: false,
                onPressed: () => checkAnswer(false),
              ),

              // Score keeper (shows correct/incorrect icons)
              SizedBox(
                height: 80,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: scoreKeeper.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: scoreKeeper[index],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Show confirm dialog before exiting quiz
  void _confirmExit(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Exit Quiz?'),
          content: const Text('Your progress will be lost.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                _resetQuiz();
                Navigator.pushNamed(context, 'home_page');
              },
              child: const Text('Exit', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  /// Reset quiz state
  void _resetQuiz() {
    numberOfCorrectAnswers = 0;
    numberOfIncorrectAnswers = 0;
    scoreKeeper = [];
    questionInfo.resetQuestion();
  }
}

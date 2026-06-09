import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quizler/models/questions.dart';
import 'package:quizler/quiz_provider.dart';
import 'package:quizler/question_info.dart';

// Global score tracking (shared with quiz_end.dart)
double numberOfCorrectAnswers = 0;
double numberOfIncorrectAnswers = 0;

/// Helper class to detect and parse multiple choice questions
class MCQuestionHelper {
  /// Check if question is multiple choice (encoded with |||)
  static bool isMultipleChoice(String questionText) {
    return questionText.contains('|||');
  }

  /// Parse multiple choice question
  /// Format: "question text|||option1|||option2|||option3|||option4|||correctIndex"
  static MCQuestion? parseMultipleChoice(String questionText) {
    try {
      final parts = questionText.split('|||');
      if (parts.length != 6) return null;

      final question = parts[0];
      final options = [parts[1], parts[2], parts[3], parts[4]];
      final correctIndex = int.parse(parts[5]);

      return MCQuestion(
        question: question,
        options: options,
        correctIndex: correctIndex,
      );
    } catch (e) {
      print('Error parsing MC question: $e');
      return null;
    }
  }

  /// Check if answer is correct
  static bool isAnswerCorrect(String questionText, int selectedIndex) {
    final mc = parseMultipleChoice(questionText);
    if (mc == null) return false;
    return selectedIndex == mc.correctIndex;
  }
}

/// Multiple Choice Question data class
class MCQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;

  MCQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
  });

  String getCorrectAnswer() => options[correctIndex];
}

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
  int? _selectedMCIndex; // Track selected MC option

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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamed(context, 'home_page');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No quiz selected')));
      });
      return;
    }

    // Create a copy of questions and shuffle them
    shuffledQuestions = List.from(currentQuiz.questionBank);
    shuffledQuestions.shuffle();

    // Initialize question info with quiz length
    questionInfo = QuestionInfo(initialQuizLength: shuffledQuestions.length);
  }

  /// Check True/False answer
  void _checkTrueFalseAnswer(bool userPickedAnswer) {
    if (_isAnswered) return;

    final quizProvider = context.read<QuizProvider>();
    final currentQuiz = quizProvider.currentQuiz;

    if (currentQuiz == null || shuffledQuestions.isEmpty) {
      return;
    }

    final correctAnswer = questionInfo.getQuestionAnswer(shuffledQuestions);

    setState(() {
      _isAnswered = true;

      if (userPickedAnswer == correctAnswer) {
        numberOfCorrectAnswers++;
        scoreKeeper.add(const Icon(Icons.check, color: Colors.green, size: 30));
      } else {
        numberOfIncorrectAnswers++;
        scoreKeeper.add(const Icon(Icons.close, color: Colors.red, size: 30));
      }

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _moveToNextQuestion();
        }
      });
    });
  }

  /// Check Multiple Choice answer
  void _checkMultipleChoiceAnswer(int selectedIndex) {
    if (_isAnswered) return;

    final question = questionInfo.getCurrentQuestion(shuffledQuestions);
    if (question == null) return;

    final isCorrect = MCQuestionHelper.isAnswerCorrect(
      question.q,
      selectedIndex,
    );

    setState(() {
      _isAnswered = true;
      _selectedMCIndex = selectedIndex;

      if (isCorrect) {
        numberOfCorrectAnswers++;
        scoreKeeper.add(const Icon(Icons.check, color: Colors.green, size: 30));
      } else {
        numberOfIncorrectAnswers++;
        scoreKeeper.add(const Icon(Icons.close, color: Colors.red, size: 30));
      }

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _moveToNextQuestion();
        }
      });
    });
  }

  /// Move to next question or finish quiz
  void _moveToNextQuestion() {
    if (mounted) {
      setState(() {
        if (questionInfo.isFinished()) {
          Navigator.pushNamed(context, 'quiz_end');
          scoreKeeper = [];
          questionInfo.resetQuestion();
        } else {
          questionInfo.nextQuestion();
          _isAnswered = false;
          _selectedMCIndex = null;
        }
      });
    }
  }

  /// Build True/False answer buttons
  Widget _buildTrueFalseSection() {
    return Column(
      children: [
        _buildAnswerButton(
          label: 'True',
          color: Colors.green,
          answered: _isAnswered,
          isCorrect: true,
          onPressed: () => _checkTrueFalseAnswer(true),
        ),
        _buildAnswerButton(
          label: 'False',
          color: Colors.red,
          answered: _isAnswered,
          isCorrect: false,
          onPressed: () => _checkTrueFalseAnswer(false),
        ),
      ],
    );
  }

  /// Build Multiple Choice buttons
  Widget _buildMultipleChoiceSection(MCQuestion mc) {
    return Column(
      children: List.generate(mc.options.length, (index) {
        final option = mc.options[index];
        final isSelected = _selectedMCIndex == index;
        final isCorrect = index == mc.correctIndex;

        // Determine color
        Color buttonColor;
        if (!_isAnswered) {
          buttonColor = Colors.blue[800]!;
        } else if (isSelected) {
          buttonColor = isCorrect ? Colors.green : Colors.red;
        } else if (isCorrect) {
          buttonColor = Colors.green; // Show correct answer
        } else {
          buttonColor = Colors.blue[300]!;
        }

        return Padding(
          padding: const EdgeInsets.all(10.0),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isAnswered
                  ? null
                  : () => _checkMultipleChoiceAnswer(index),
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                elevation: _isAnswered ? 0 : 5,
              ),
              child: Text(
                '${String.fromCharCode(65 + index)}) $option',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.left,
              ),
            ),
          ),
        );
      }),
    );
  }

  /// Build True/False answer button
  Widget _buildAnswerButton({
    required String label,
    required Color color,
    required bool answered,
    required bool isCorrect,
    required VoidCallback onPressed,
  }) {
    final isSelected = answered && (label == 'True' ? isCorrect : !isCorrect);

    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: SizedBox(
        width: double.infinity,
        height: 70,
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

        // Get current question
        final currentQuestion = questionInfo.getCurrentQuestion(
          shuffledQuestions,
        );
        final questionText = questionInfo.getQuestionText(shuffledQuestions);

        // Check if this is a multiple choice question
        final isMultipleChoice =
            currentQuestion != null &&
            MCQuestionHelper.isMultipleChoice(currentQuestion.q);

        final mcQuestion = isMultipleChoice
            ? MCQuestionHelper.parseMultipleChoice(currentQuestion!.q)
            : null;

        // Get display text (without MC encoding)
        final displayText = isMultipleChoice && mcQuestion != null
            ? mcQuestion.question
            : questionText;

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
                onPressed: () => _confirmExit(context),
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
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Center(
                    child: Text(
                      displayText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24.0,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              // Answer options (True/False or Multiple Choice)
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: isMultipleChoice && mcQuestion != null
                      ? _buildMultipleChoiceSection(mcQuestion)
                      : _buildTrueFalseSection(),
                ),
              ),

              // Score keeper
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
                Navigator.pop(context);
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

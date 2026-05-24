import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quizler/components/app_bar.dart';
import 'package:quizler/question_info.dart';
import 'package:quizler/quiz_questions_info/general_info.dart';
import 'package:quizler/quiz_questions_info/hockey_stats.dart';
import 'package:quizler/screens/customize_quiz.dart';
import 'package:quizler/screens/settings_page.dart';
import 'package:quizler/constants.dart';

List <String> quizNames = [
  'General Info quiz',
  'Hockey Stats quiz',
];
dynamic currentQuiz;
String quizName = '$currentQuiz !';
String searchParameter = '';

class ChangeSearchError extends ChangeNotifier {
  String _searchError = '';

  String get searchParameter => _searchError;

  void changeError() {
    if (_searchError == '') {
      _searchError = 'No quizes found';
    }
    else {
      _searchError = '';
    }
    notifyListeners();
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void showQuizs() {

  }

  AddQuizButton addQuizButton (VoidCallback onPressed, String name) {
    return AddQuizButton(onPressed: onPressed, name: name);
  }

  @override
  Widget build(BuildContext context) {
    final changeSearchError = context.watch<ChangeSearchError>();
    return Scaffold(
      backgroundColor: Colors.blue.shade600,
      appBar: ReusableAppBar(),
      drawer: const NavigationDrawer(),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              changeSearchError._searchError,
              style: TextStyle(
                color:Colors.red,
                fontSize: 20,
              )
            ),
            Padding(
              padding: EdgeInsets.all(15),
              child: TextField(
                decoration: kTextFieldDecoration,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                onChanged: (value) {
                  changeSearchError._searchError = value;
                  if (searchParameter == quizName) {
                    showQuizs();
                  }
                  else {
                    context.read<ChangeSearchError>().changeError();
                  }
                },
              )
            ),
            Center(
              child: Padding(
                padding: EdgeInsetsGeometry.all(15),
                child: Text(
                  'Public Quizes',
                  style: TextStyle(
                    color: kTextColor,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  )
                )
              ),
            ),
            AddQuizButton(
              name: 'General Info Quiz',
              onPressed: () {
                  currentQuiz = GeneralInfoQuiz();
                  quizLength = currentQuiz.questionBank.length;
                  questionAnswer = currentQuiz.questionBank;
                  Navigator.pushNamed(context, 'quiz_generator');
              }
            ),
            AddQuizButton(
              name: 'Hockey quiz',
              onPressed:() { 
                currentQuiz = HockeyStatsQuiz();
                quizLength = currentQuiz.questionBank.length;
                questionAnswer = currentQuiz.questionBank;
                Navigator.pushNamed(context, 'quiz_generator');
              }
            )
          ],
        ),
      ),
    );
  }
}

class NavigationDrawer extends StatelessWidget {
  const NavigationDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.blueGrey,
      width: 250,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blueGrey[400],
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: kTextColor,
                  fontSize: 30,
                )
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.settings,
                color: kTextColor,
              ),
              title: Text(
                'Make your own quiz'
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CustomizeQuiz()),
                );
              }
            ),
            ListTile(
              leading: Icon(
                Icons.settings,
                color: kTextColor,
              ),
              title: Text(
                'Settings Page'
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsPage()),
                );
              }
            ),           
          ],
        ),
      )
    );
  }
}

class AddQuizButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String name;
  const AddQuizButton({
    super.key,
    required this.onPressed,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: TextButton(
        onPressed: onPressed,
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(Colors.blue[800])
        ),
        child: const Text(
          ' ',
          style: TextStyle(
            color: kTextColor,
            fontSize: 25,
          ),
        ),
      ),
    );
  }
}
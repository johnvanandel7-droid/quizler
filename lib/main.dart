import 'package:flutter/material.dart';
import 'package:quizler/screens/customize_quiz.dart';
import 'package:quizler/screens/home_page.dart';
import 'package:quizler/screens/login_screen.dart';
import 'package:quizler/screens/my_profile.dart';
import 'package:quizler/screens/quiz_end.dart';
import 'package:quizler/screens/quiz_generator.dart';
import 'package:quizler/screens/registration_screen.dart';
import 'package:quizler/screens/settings_page.dart';
import 'package:provider/provider.dart';
import 'package:quizler/screens/welcome_screen.dart';

void main() {
  runApp(QuizlerApp());
}

class QuizlerApp extends StatelessWidget {
  const QuizlerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ChangeSearchError>(
      create: (_) => ChangeSearchError(),
      child: MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme(
            brightness: Brightness.light,
            primary: Colors.blueGrey,
            onPrimary: Colors.grey,
            secondary: Colors.black,
            onSecondary: Colors.white,
            error: Colors.red,
            onError: Colors.red,
            surface: Colors.blue,
            onSurface: Colors.black,
          ),
        ),
        debugShowCheckedModeBanner: false,
        initialRoute: 'welcome_page',
        routes: {
          'welcome_page': (context) => WelcomeScreen(),
          'registration_screen': (context) => RegistrationScreen(),
          'login_screen': (context) => LoginScreen(),
          'home_page': (context) => HomePage(),
          'settings': (context) => SettingsPage(),
          'customize': (context) => CustomizeQuiz(),
          'quiz_end': (context) => QuizEnd(),
          'quiz_generator': (context) =>
              QuizPageGenerator(appBarText: quizName),
          'my_profile': (context) => MyProfile(),
        },
      ),
    );
  }
}

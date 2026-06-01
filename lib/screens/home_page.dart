import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quizler/components/app_bar.dart';
import 'package:quizler/quiz_provider.dart';
import 'package:quizler/screens/customize_quiz.dart';
import 'package:quizler/screens/settings_page.dart';
import 'package:quizler/constants.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Refresh quizzes when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuizProvider>().refreshQuizzes();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh when returning to this page after navigation
    _refreshQuizzes();
  }

  /// Refresh quizzes when returning from other screens
  void _refreshQuizzes() {
    Future.microtask(() {
      if (mounted) {
        context.read<QuizProvider>().refreshQuizzes();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<QuizProvider>(
      builder: (context, quizProvider, _) {
        return WillPopScope(
          onWillPop: () async {
            // refresh when back button is pressed
            _refreshQuizzes();
            return true;
          },
          child: Scaffold(
            backgroundColor: Colors.blue.shade600,
            appBar: const ReusableAppBar(),
            drawer: const NavigationDrawer(),
            body: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Error message
                  if (quizProvider.errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              quizProvider.errorMessage,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              quizProvider.clearError();
                            },
                            icon: const Icon(Icons.close, color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: TextField(
                      decoration: kTextFieldDecoration,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      onChanged: (value) {
                        quizProvider.searchQuizzes(value);
                      },
                    ),
                  ),
                  // Title
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(15),
                      child: Text(
                        'Available Quizzes',
                        style: TextStyle(
                          color: kTextColor,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // Loading indicator
                  if (quizProvider.isLoading)
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  // Quiz list
                  // Quiz list
                  if (!quizProvider.isLoading)
                    Expanded(
                      child: quizProvider.filteredQuizzes.isEmpty
                          ? Center(
                              child: Text(
                                quizProvider.errorMessage.isEmpty
                                    ? 'No quizzes available'
                                    : quizProvider.errorMessage,
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.black,
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () => quizProvider.refreshQuizzes(),
                              child: ListView.builder(
                                itemCount: quizProvider.filteredQuizzes.length,
                                itemBuilder: (context, index) {
                                  final quiz =
                                      quizProvider.filteredQuizzes[index];
                                  return AddQuizButton(
                                    name: quiz.name,
                                    description: quiz.description,
                                    onPressed: () {
                                      quizProvider.setCurrentQuiz(quiz);
                                      Navigator.pushNamed(
                                        context,
                                        'quiz_generator',
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
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
              decoration: BoxDecoration(color: Colors.blueGrey[400]),
              child: Text(
                'Menu',
                style: TextStyle(color: kTextColor, fontSize: 30),
              ),
            ),
            ListTile(
              leading: Icon(Icons.settings, color: kTextColor),
              title: Text('Make your own quiz'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CustomizeQuiz()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: kTextColor),
              title: const Text('Settings Page'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class AddQuizButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String name;
  final String description;

  const AddQuizButton({
    super.key,
    required this.onPressed,
    required this.name,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[800],
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Column(
          children: [
            Text(
              name,
              style: const TextStyle(
                color: kTextColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(
                description,
                style: TextStyle(color: Colors.grey, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

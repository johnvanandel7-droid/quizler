import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quizler/components/app_bar.dart';
import 'package:quizler/quiz_provider.dart';
import 'package:quizler/constants.dart';
import 'package:quizler/screens/quiz_detail_screen.dart';

final auth = FirebaseAuth.instance;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Refresh quizzes when page loads only (not on every dependency change)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuizProvider>().refreshQuizzes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<QuizProvider>(
      builder: (context, quizProvider, _) {
        return WillPopScope(
          onWillPop: () async {
            quizProvider.refreshQuizzes();
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
                            onPressed: () => quizProvider.clearError(),
                            icon: const Icon(Icons.close, color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: Row(
                      children: [
                        Expanded(
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
                        const SizedBox(width: 10),
                        // Sort/filter menu button
                        IconButton(
                          onPressed: () => _showSearchOptions(context),
                          icon: const Icon(Icons.tune, size: 24),
                          tooltip: 'Sort & Filter',
                        ),
                      ],
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
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              QuizDetailScreen(quiz: quiz),
                                        ),
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
            Spacer(flex: 1),
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blueGrey[400]),
              child: const Text(
                'Menu',
                style: TextStyle(color: kTextColor, fontSize: 30),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add_circle_outline, color: kTextColor),
              title: const Text('Make your own quiz'),
              onTap: () {
                Navigator.pushNamed(context, 'customize');
              },
            ),
            Spacer(flex: 1),
            ListTile(
              leading: const Icon(Icons.settings, color: kTextColor),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pushNamed(context, 'settings');
              },
            ),
            Spacer(flex: 1),
            ListTile(
              leading: const Icon(Icons.person, color: kTextColor),
              title: const Text('My Profile'),
              onTap: () {
                Navigator.pushNamed(context, 'my_profile');
              },
            ),
            Spacer(flex: 2),
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
                style: const TextStyle(color: Colors.grey, fontSize: 14),
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

void _showSearchOptions(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Text('Sort & Filter'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.sort_by_alpha),
              title: const Text('Sort by Name'),
              onTap: () {
                context.read<QuizProvider>().sortByName();
                Navigator.pop(dialogContext);
              },
            ),
            ListTile(
              leading: const Icon(Icons.signal_cellular_alt),
              title: const Text('Sort by Difficulty'),
              onTap: () {
                context.read<QuizProvider>().sortByDifficulty();
                Navigator.pop(dialogContext);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Sort by Newest'),
              onTap: () {
                context.read<QuizProvider>().sortByDate();
                Navigator.pop(dialogContext);
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text('Favorite Quizzes'),
              onTap: () {
                context.read<QuizProvider>().showFavoriteQuizzes(
                  auth.currentUser!.uid,
                );
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Reset / Show All'),
              onTap: () {
                context.read<QuizProvider>().refreshQuizzes();
                Navigator.pop(dialogContext);
              },
            ),
          ],
        ),
      );
    },
  );
}

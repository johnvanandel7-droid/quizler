import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quizler/constants.dart';
import 'home_page.dart';

final auth = FirebaseAuth.instance;

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            },
            icon: const Icon(Icons.home, color: Colors.white),
          ),
        ],
        title: const Text('Settings'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),

          // Sign Out
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  auth.signOut();
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    'welcome_screen',
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Change Password
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showChangePasswordDialog(context),
                icon: const Icon(Icons.lock_outline),
                label: const Text(
                  'Change Password',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _showChangePasswordDialog(BuildContext context) {
  // Controllers are created here so they live with the dialog
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  String errorMessage = '';

  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      // StatefulBuilder lets us call setState inside the dialog
      return StatefulBuilder(
        builder: (statefulContext, setDialogState) {
          return AlertDialog(
            title: const Text('Change Password'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Current password
                  TextFormField(
                    controller: currentPasswordController,
                    obscureText: true,
                    decoration: kInputDecoration.copyWith(
                      hintText: 'Current password',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your current password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // New password
                  TextFormField(
                    controller: newPasswordController,
                    obscureText: true,
                    decoration: kInputDecoration.copyWith(
                      hintText: 'New password',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a new password';
                      }
                      if (value.trim().length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Confirm new password
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: kInputDecoration.copyWith(
                      hintText: 'Confirm new password',
                    ),
                    validator: (value) {
                      if (value != newPasswordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),

                  // Error message
                  if (errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      errorMessage,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  setDialogState(() => errorMessage = '');

                  if (!formKey.currentState!.validate()) return;

                  final user = auth.currentUser;
                  if (user == null || user.email == null) {
                    setDialogState(() => errorMessage = 'No user logged in');
                    return;
                  }

                  // Show loading
                  setDialogState(() => errorMessage = 'Saving...');

                  try {
                    // Step 1: re-authenticate (Firebase requires this before
                    // sensitive operations like password change)
                    final credential = EmailAuthProvider.credential(
                      email: user.email!,
                      password: currentPasswordController.text.trim(),
                    );
                    await user.reauthenticateWithCredential(credential);

                    // Step 2: update the password
                    await user.updatePassword(
                      newPasswordController.text.trim(),
                    );

                    // Step 3: success — close dialog then show snackbar
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Password updated successfully!'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                  } on FirebaseAuthException catch (e) {
                    // Map Firebase error codes to readable messages
                    String message;
                    switch (e.code) {
                      case 'wrong-password':
                      case 'invalid-credential':
                        message = 'Current password is incorrect';
                        break;
                      case 'weak-password':
                        message = 'New password must be at least 6 characters';
                        break;
                      case 'requires-recent-login':
                        message =
                            'Session expired — please log out and back in';
                        break;
                      case 'too-many-requests':
                        message = 'Too many attempts, try again later';
                        break;
                      default:
                        // Show the raw Firebase message so nothing is hidden
                        message = 'Firebase error (${e.code}): ${e.message}';
                    }
                    setDialogState(() => errorMessage = message);
                  } catch (e) {
                    // Catch any other unexpected error — previously these were
                    // swallowed silently which made it look like nothing happened
                    setDialogState(() => errorMessage = 'Unexpected error: $e');
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.blue),
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  ).then((_) {
    // Dispose controllers when dialog closes
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
  });
}

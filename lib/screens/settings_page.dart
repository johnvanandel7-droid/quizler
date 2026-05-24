import 'package:flutter/material.dart';
import 'home_page.dart';

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
                MaterialPageRoute(builder: (context) => HomePage())
              );
            },
            icon: Icon(
              Icons.home, 
              color: Colors.white
            )
          )
        ],
        title: Text('Settings'),
      ),
    );
  }
}
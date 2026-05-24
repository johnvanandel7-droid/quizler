import 'package:flutter/material.dart';
import 'package:quizler/components/app_bar.dart';
import 'package:quizler/components/reusable_card.dart';

class MyProfile extends StatelessWidget {
  const MyProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ReusableAppBar(),
      body: Column(
        children: [
          ReusableCard(
            colour: Colors.blue, 
            cardChild: Text('My Quizes'), 
            onPress: () {}
          )
        ],
      ),
    );
  }
}
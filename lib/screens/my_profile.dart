import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quizler/components/app_bar.dart';
import 'package:quizler/components/section_header.dart';
import 'package:firebase_auth/firebase_auth.dart';

final auth = FirebaseAuth.instance;
final firestore = FirebaseFirestore.instance;

class MyProfile extends StatefulWidget {
  const MyProfile({super.key});

  @override
  State<MyProfile> createState() => _MyProfileState();
}

class _MyProfileState extends State<MyProfile> {
  bool showQuizes = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ReusableAppBar(),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(15),
            child: Text(
              auth.currentUser?.email!.split('@')[0] ?? 'no_name',
              style: TextStyle(fontSize: 25),
            ),
          ),
          SectionHeader(
            title: 'My Quizes',
            isExpanded: showQuizes,
            onToggle: () {
              setState(() {
                showQuizes = !showQuizes;
              });
            },
          ),
          if (showQuizes == true) SizedBox(height: 10),
          MyQuizesList(),
          if (showQuizes == false) SizedBox(),
        ],
      ),
    );
  }
}

class MyQuizesList extends StatelessWidget {
  const MyQuizesList({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: firestore
          .collection('quizes')
          .where(auth.currentUser!.uid, isEqualTo: 'createdBy')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No quizes yet"));
        }

        final docs = snapshot.data!.docs; // already ordered by query

        List<QuizTemplate> quizes = [];

        for (var doc in docs) {
          try {
            final data = doc.data() as Map<String, dynamic>;

            final plays = data['plays'] as int;

            quizes.add(QuizTemplate(plays: plays));
          } catch (e) {
            print(e);
          }
        }
        return ListView(
          reverse: false,
          padding: const EdgeInsets.all(10),
          children: quizes,
        );
      },
    );
  }
}

class QuizTemplate extends StatelessWidget {
  final int plays;

  const QuizTemplate({super.key, required this.plays});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      child: Column(children: [Text('your quiz has been played $plays')]),
    );
  }
}

import 'package:flutter/material.dart';

const kTextColor = Colors.black;

const kTextFieldDecoration = InputDecoration(
  icon: Icon(Icons.search),
  hintText: 'Quiz name',
  hintStyle: TextStyle(color: Colors.grey),
  border: OutlineInputBorder(),
  focusColor: Colors.blueGrey,
  iconColor: Colors.black,
);

const kTextFieldDecoration2 = InputDecoration(
  hintText: 'Quiz name',
  hintStyle: TextStyle(color: Colors.grey),
  border: OutlineInputBorder(),
  focusColor: Colors.blueGrey,
  iconColor: Colors.black,
);

final kButtonStyle = ButtonStyle(
  shadowColor: WidgetStateProperty.all(Colors.black),
  elevation: WidgetStateProperty.all(10),
  backgroundColor: WidgetStateProperty.all(Colors.grey),
);

const kTrueInactiveCardColor = Colors.green;

const kTrueActiveCardColor = Color(0xff256a19);

const kFalseInactiveCardColor = Colors.red;

const kFalseActiveCardColor = Color(0xff8b1414);

const kInputDecoration = InputDecoration(
  hintText: 'Enter your password.',
  hintStyle: TextStyle(color: Colors.grey),
  labelStyle: TextStyle(color: Colors.black),
  contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(32.0)),
  ),
  enabledBorder: OutlineInputBorder(
    borderSide: BorderSide(color: Colors.lightBlueAccent, width: 1.0),
    borderRadius: BorderRadius.all(Radius.circular(32.0)),
  ),
  focusedBorder: OutlineInputBorder(
    borderSide: BorderSide(color: Colors.lightBlueAccent, width: 2.0),
    borderRadius: BorderRadius.all(Radius.circular(32.0)),
  ),
);

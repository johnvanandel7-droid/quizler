import 'package:flutter/material.dart';

const kTextColor = Colors.black;

const kTextFieldDecoration = InputDecoration(
  icon:Icon(Icons.search),
  hintText: 'Quiz name',
  hintStyle:TextStyle(
    color:Colors.grey,
  ),
  border: OutlineInputBorder(),
  focusColor: Colors.blueGrey,
  iconColor: Colors.black,
);

const kTextFieldDecoration2 = InputDecoration(
  hintText: 'Quiz name',
  hintStyle:TextStyle(
    color:Colors.grey,
  ),
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
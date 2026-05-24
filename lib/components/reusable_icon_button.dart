import 'package:flutter/material.dart';

class ReusableIconButton extends StatelessWidget {

  final Icon icon;
  final VoidCallback onPressed;

  const ReusableIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: icon,
      onPressed: onPressed,
      padding: EdgeInsets.all(5),
      splashColor: Colors.black,
      focusColor: Colors.black,
      color: Colors.grey[800],
    );
  }
}
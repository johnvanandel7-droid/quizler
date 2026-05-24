import 'package:flutter/material.dart';
import 'reusable_icon_button.dart';

class ReusableAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ReusableAppBar ({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.grey,
      actions: [
        ReusableIconButton(
          icon: Icon(Icons.home), 
          onPressed: () {
            Navigator.pushNamed(context, 'home_page');
          },
        ),
        ReusableIconButton(
          icon: Icon(Icons.dashboard_customize), 
          onPressed: () {
            Navigator.pushNamed(context, 'customize');
          },
        ),
        ReusableIconButton(
          icon: Icon(Icons.person), 
          onPressed: () {
            Navigator.pushNamed(context, 'my_profile');
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(80);
}
import 'package:flutter/material.dart';
import 'core/app_theme.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const UMSkillLinkApp());
}

class UMSkillLinkApp extends StatefulWidget {
  const UMSkillLinkApp({super.key});

  @override
  State<UMSkillLinkApp> createState() => _UMSkillLinkAppState();
}

class _UMSkillLinkAppState extends State<UMSkillLinkApp> {


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UM SkillLink Super Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
    );
  }
}

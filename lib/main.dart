import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/app_theme.dart';
import 'screens/login_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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

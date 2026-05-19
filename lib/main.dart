import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/app_theme.dart';
import 'screens/login_screen.dart';
import 'firebase_options.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'widgets/student_layout.dart';

import 'models/mock_data.dart';
import 'screens/super_admin/super_admin_portal.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await MockData.initializeFromFirestore();
  } catch (e) {
    debugPrint('Firebase or MockData initialization failed: $e');
  }
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
      title: 'UM SkillLink',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Firebase.apps.isEmpty
          ? const LoginScreen()
          : StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryRed,
                        ),
                      ),
                    ),
                  );
                }
                if (snapshot.hasData && snapshot.data != null) {
                  if (snapshot.data!.email ==
                      "j.antukan.549054@umindanao.edu.ph") {
                    return const SuperAdminPortal();
                  }
                  return const StudentLayout();
                }
                return const LoginScreen();
              },
            ),
    );
  }
}

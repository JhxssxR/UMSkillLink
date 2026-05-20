import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/app_theme.dart';
import 'screens/login_screen.dart';
import 'firebase_options.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/student_layout.dart';
import 'widgets/tutor_layout.dart';
import 'screens/admin/admin_portal.dart';

import 'models/mock_data.dart';
import 'screens/super_admin/super_admin_portal.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await dotenv.load(fileName: ".env");
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
                  final user = snapshot.data!;
                  if (user.email == "j.antukan.549054@umindanao.edu.ph") {
                    return const SuperAdminPortal();
                  }

                  return StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.email!)
                        .snapshots(),
                    builder: (context, userSnapshot) {
                      if (userSnapshot.connectionState == ConnectionState.waiting) {
                        return const Scaffold(
                          body: Center(
                            child: CircularProgressIndicator(color: AppTheme.primaryRed),
                          ),
                        );
                      }

                      if (userSnapshot.hasData && userSnapshot.data!.exists) {
                        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                        final lastPortal = userData['lastPortal'] ?? 'student';
                        final role = userData['role'] ?? 'student';

                        if (lastPortal == 'tutor' && role == 'tutor') {
                          return const TutorLayout();
                        }
                        
                        if (role == 'admin' || role == 'superadmin') {
                           // Keep original logic for super admin if needed, but here's general portal check
                        }
                      }
                      return const StudentLayout();
                    },
                  );
                }
                return const LoginScreen();
              },
            ),
    );
  }
}

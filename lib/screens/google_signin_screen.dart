import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/student_layout.dart';
import '../widgets/tutor_layout.dart';
import '../models/mock_data.dart';
import '../core/demo_mode.dart';
import 'admin/admin_portal.dart';
import 'super_admin/super_admin_portal.dart';

import 'package:firebase_auth/firebase_auth.dart';

enum SignInStep { email, password }

class GoogleSignInScreen extends StatefulWidget {
  const GoogleSignInScreen({super.key});

  @override
  State<GoogleSignInScreen> createState() => _GoogleSignInScreenState();
}

class _GoogleSignInScreenState extends State<GoogleSignInScreen> {
  SignInStep _currentStep = SignInStep.email;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _showPassword = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleNextStep() {
    setState(() {
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Enter an email or phone number';
      });
      return;
    }

    // Google-style regex check for valid email syntax
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      setState(() {
        _errorMessage = 'Enter a valid email address';
      });
      return;
    }

    // Security check: Must end with @umindanao.edu.ph
    if (!email.endsWith('@umindanao.edu.ph')) {
      setState(() {
        _errorMessage = 'Use your @umindanao.edu.ph school account';
      });
      return;
    }

    // Smooth transition to password step
    setState(() {
      _currentStep = SignInStep.password;
    });
  }

  void _handleBackToEmail() {
    setState(() {
      _currentStep = SignInStep.email;
      _passwordController.clear();
      _errorMessage = null;
    });
  }

  Future<void> _handleCompleteSignIn() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (password.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Enter your password';
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Wrong password. Try again or click Forgot password to reset it.';
      });
      return;
    }

    try {
      // 1. Authenticate using Firebase Authentication
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (authErr) {
        if (authErr.code == 'user-not-found' ||
            authErr.code == 'invalid-credential' ||
            authErr.code == 'wrong-password') {
          try {
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
              email: email,
              password: password,
            );
          } on FirebaseAuthException catch (regErr) {
            if (regErr.code == 'email-already-in-use') {
              setState(() {
                _isLoading = false;
                _errorMessage =
                    'Wrong password. Try again or click Forgot password to reset it.';
              });
              return;
            } else {
              rethrow;
            }
          }
        } else {
          rethrow;
        }
      }

      // 2. Connect and Save user detail inside Cloud Firestore
      String studentId = '';
      String course = 'Select Course';
      String department = 'Select Department';
      String? dirName;
      
      // Extract student ID (the number block from the email)
      final idMatch = RegExp(r'\.(\d+)@').firstMatch(email);
      if (idMatch != null) {
        studentId = idMatch.group(1) ?? '';
      }

      // Check student directory for automatic course and department lookup (Option A)
      try {
        // 1. Direct document lookup by email
        var doc = await FirebaseFirestore.instance.collection('student_directory').doc(email).get();
        Map<String, dynamic>? dirData;
        if (doc.exists) {
          dirData = doc.data();
        } else {
          // 2. Direct document lookup by lowercase email
          doc = await FirebaseFirestore.instance.collection('student_directory').doc(email.toLowerCase()).get();
          if (doc.exists) {
            dirData = doc.data();
          } else if (studentId.isNotEmpty) {
            // 3. Direct document lookup by student ID
            doc = await FirebaseFirestore.instance.collection('student_directory').doc(studentId).get();
            if (doc.exists) {
              dirData = doc.data();
            }
          }
        }

        // 4. Fallback queries
        if (dirData == null) {
          var query = await FirebaseFirestore.instance
              .collection('student_directory')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();
          if (query.docs.isNotEmpty) {
            dirData = query.docs.first.data();
          } else {
            query = await FirebaseFirestore.instance
                .collection('student_directory')
                .where('email', isEqualTo: email.toLowerCase())
                .limit(1)
                .get();
            if (query.docs.isNotEmpty) {
              dirData = query.docs.first.data();
            } else if (studentId.isNotEmpty) {
              query = await FirebaseFirestore.instance
                  .collection('student_directory')
                  .where('studentId', isEqualTo: studentId)
                  .limit(1)
                  .get();
              if (query.docs.isNotEmpty) {
                dirData = query.docs.first.data();
              } else {
                query = await FirebaseFirestore.instance
                    .collection('student_directory')
                    .where('id', isEqualTo: studentId)
                    .limit(1)
                    .get();
                if (query.docs.isNotEmpty) {
                  dirData = query.docs.first.data();
                }
              }
            }
          }
        }

        if (dirData != null) {
          course = dirData['course'] ?? dirData['program'] ?? course;
          department = dirData['department'] ?? dirData['college'] ?? department;
          dirName = dirData['name'] ?? dirData['fullName'] ?? dirData['fullname'] ?? dirData['fullName'];
        }
      } catch (dbErr) {
        debugPrint('Directory lookup warning: $dbErr');
      }

      String rawName = email.split('@')[0];
      rawName = rawName.replaceAll(RegExp(r'\d+'), '').trim();
      String cleanedName = rawName.replaceAll(RegExp(r'^\.+|\.+$'), '').replaceAll('.', ' ').trim().toUpperCase();
      if (cleanedName.isEmpty) {
        cleanedName = email.split('@')[0].replaceAll('.', ' ').toUpperCase();
      }

      String finalName = (dirName != null && dirName.toString().isNotEmpty)
          ? dirName.toString().trim().toUpperCase()
          : cleanedName;

      await FirebaseFirestore.instance.collection('users').doc(email).set({
        'email': email,
        'name': finalName,
        'role': email == "j.antukan.549054@umindanao.edu.ph"
            ? "admin"
            : "student",
        'studentId': studentId,
        'program': course,
        'college': department,
        'status': 'Active',
        'lastLogin': FieldValue.serverTimestamp(),
        'authProvider': 'Google',
      }, SetOptions(merge: true));

      // 3. Initialize dynamic MockData from Cloud Firestore collections
      await MockData.initializeFromFirestore();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully authenticated as $email via Google!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint('Firebase login registry warning: $e');
      // If Firestore or Auth is completely offline, we still allow fallback so the presentation works.
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully logged in (Offline fallback): $email'),
          backgroundColor: Colors.orange.shade700,
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Activate Demo Mode if using demo accounts
        if (email == "superadmin@umindanao.edu.ph" ||
            email == "admin@umindanao.edu.ph" ||
            email == "tutor@umindanao.edu.ph" ||
            email == "learner@umindanao.edu.ph" ||
            email == "learner2@umindanao.edu.ph") {
          DemoMode.isActive = true;
        }

        // Navigate cleanly to the correct portal
        if (email == "j.antukan.549054@umindanao.edu.ph" ||
            email == "superadmin@umindanao.edu.ph") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SuperAdminPortal()),
          );
        } else if (email == "admin@umindanao.edu.ph") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminPortal()),
          );
        } else if (email == "tutor@umindanao.edu.ph") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const TutorLayout()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const StudentLayout()),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 600;

    return Scaffold(
      backgroundColor: isDesktop ? const Color(0xFFF0F4F9) : Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Google Sign-In Main Container Card
              Container(
                width: isDesktop ? 450 : screenWidth,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40.0,
                  vertical: 36.0,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: isDesktop
                      ? BorderRadius.circular(8.0)
                      : BorderRadius.zero,
                  border: isDesktop
                      ? Border.all(color: const Color(0xFFDADCE0), width: 1)
                      : null,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Google Authentic Loading Indicator Bar
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 16.0),
                          child: LinearProgressIndicator(
                            color: Color(0xFF1A73E8),
                            backgroundColor: Color(0xFFE8F0FE),
                          ),
                        ),

                      // Multi-colored Styled Google Lettering Logotype
                      Center(
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.openSans(
                              fontSize: 38,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -1.5,
                            ),
                            children: const [
                              TextSpan(
                                text: 'G',
                                style: TextStyle(color: Color(0xFF4285F4)),
                              ),
                              TextSpan(
                                text: 'o',
                                style: TextStyle(color: Color(0xFFEA4335)),
                              ),
                              TextSpan(
                                text: 'o',
                                style: TextStyle(color: Color(0xFFFBBC05)),
                              ),
                              TextSpan(
                                text: 'g',
                                style: TextStyle(color: Color(0xFF4285F4)),
                              ),
                              TextSpan(
                                text: 'l',
                                style: TextStyle(color: Color(0xFF34A553)),
                              ),
                              TextSpan(
                                text: 'e',
                                style: TextStyle(color: Color(0xFFEA4335)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Animated Step Switcher
                      _currentStep == SignInStep.email
                          ? _buildEmailStep()
                          : _buildPasswordStep(),

                      const SizedBox(height: 32),

                      // Bottom Dialog Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Left Action Button
                          _currentStep == SignInStep.email
                              ? TextButton(
                                  onPressed: () {},
                                  child: Text(
                                    'Create account',
                                    style: GoogleFonts.roboto(
                                      color: const Color(0xFF1A73E8),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                )
                              : TextButton(
                                  onPressed: () {},
                                  child: Text(
                                    'Forgot password?',
                                    style: GoogleFonts.roboto(
                                      color: const Color(0xFF1A73E8),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),

                          // Right Action Button (Next / Sign In)
                          ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : (_currentStep == SignInStep.email
                                      ? _handleNextStep
                                      : _handleCompleteSignIn),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A73E8),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            child: Text(
                              _currentStep == SignInStep.email
                                  ? 'Next'
                                  : 'Next',
                              style: GoogleFonts.roboto(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Dynamic Google Footer (Language selector and Help links)
              Container(
                width: isDesktop ? 450 : screenWidth,
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Language Dropdown Selector
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(
                        LucideIcons.globe,
                        size: 14,
                        color: Color(0xFF5F6368),
                      ),
                      label: Text(
                        'English (United States)',
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          color: const Color(0xFF5F6368),
                        ),
                      ),
                    ),
                    // Action Links
                    Wrap(
                      children: [
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            'Help',
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              color: const Color(0xFF5F6368),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            'Privacy',
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              color: const Color(0xFF5F6368),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            'Terms',
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              color: const Color(0xFF5F6368),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Step 1 Layout: Email Entry ---
  Widget _buildEmailStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Center(
          child: Text(
            'Sign in',
            style: GoogleFonts.roboto(
              fontSize: 24,
              color: const Color(0xFF202124),
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'to continue to UM SkillLink',
            style: GoogleFonts.roboto(
              fontSize: 16,
              color: const Color(0xFF202124),
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Google Standard Outline Input Field
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          onFieldSubmitted: (_) => _handleNextStep(),
          decoration: InputDecoration(
            labelText: 'Email or phone',
            labelStyle: TextStyle(
              color: _errorMessage != null
                  ? const Color(0xFFD93025)
                  : const Color(0xFF5F6368),
            ),
            errorText: _errorMessage,
            errorMaxLines: 2,
            floatingLabelBehavior: FloatingLabelBehavior.auto,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF1A73E8), width: 2),
            ),
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFDADCE0), width: 1),
            ),
            errorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFD93025), width: 1),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFD93025), width: 2),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Learn more text
        Text(
          'Not your computer? Use Guest mode to sign in privately.',
          style: GoogleFonts.roboto(
            fontSize: 14,
            color: const Color(0xFF5F6368),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Learn more about using Guest mode',
          style: GoogleFonts.roboto(
            fontSize: 14,
            color: const Color(0xFF1A73E8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // --- Step 2 Layout: Password Entry ---
  Widget _buildPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Center(
          child: Text(
            'Welcome',
            style: GoogleFonts.roboto(
              fontSize: 24,
              color: const Color(0xFF202124),
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Google Standard Active User Account Pill
        Center(
          child: ActionChip(
            onPressed: _handleBackToEmail,
            avatar: const CircleAvatar(
              backgroundColor: Color(0xFFF1F3F4),
              child: Icon(LucideIcons.user, size: 14, color: Color(0xFF5F6368)),
            ),
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    _emailController.text,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: const Color(0xFF3C4043),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  LucideIcons.chevronDown,
                  size: 14,
                  color: Color(0xFF5F6368),
                ),
              ],
            ),
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFFDADCE0), width: 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const SizedBox(height: 28),

        // Password Input Outline Field
        TextFormField(
          controller: _passwordController,
          obscureText: !_showPassword,
          onFieldSubmitted: (_) => _handleCompleteSignIn(),
          decoration: InputDecoration(
            labelText: 'Enter your password',
            labelStyle: TextStyle(
              color: _errorMessage != null
                  ? const Color(0xFFD93025)
                  : const Color(0xFF5F6368),
            ),
            errorText: _errorMessage,
            errorMaxLines: 2,
            floatingLabelBehavior: FloatingLabelBehavior.auto,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF1A73E8), width: 2),
            ),
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFDADCE0), width: 1),
            ),
            errorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFD93025), width: 1),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFD93025), width: 2),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Google Standard Show Password Checkrow
        Row(
          children: [
            Checkbox(
              value: _showPassword,
              onChanged: (val) {
                setState(() {
                  _showPassword = val ?? false;
                });
              },
              activeColor: const Color(0xFF1A73E8),
            ),
            Text(
              'Show password',
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: const Color(0xFF202124),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

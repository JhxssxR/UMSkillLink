import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/app_theme.dart';
import '../../models/mock_data.dart';
import '../login_screen.dart';
import '../../widgets/student_layout.dart';
import '../../widgets/tutor_layout.dart';
import '../tutor/tutor_application_screen.dart';
import 'payment_methods_screen.dart';
import 'subscription_payment_screen.dart';
import '../../services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../components/custom_app_bar.dart';

class ProfileScreen extends StatefulWidget {
  final bool isTutorMode;

  const ProfileScreen({super.key, this.isTutorMode = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    if (widget.isTutorMode) {
      return _buildTutorProfile(context);
    } else {
      return _buildStudentProfile(context);
    }
  }

  // --- STUDENT PROFILE MODE ---
  Widget _buildStudentProfile(BuildContext context) {
    bool hasFirebase = false;
    User? user;
    try {
      if (Firebase.apps.isNotEmpty) {
        user = FirebaseAuth.instance.currentUser;
        hasFirebase = true;
      }
    } catch (_) {}

    final String email = (user?.email ?? 'student@umindanao.edu.ph').toLowerCase();

    final stream = hasFirebase
        ? FirebaseFirestore.instance.collection('users').doc(email).snapshots()
        : const Stream<DocumentSnapshot>.empty();

    return StreamBuilder<DocumentSnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        String name = 'Juan Dela Cruz';
        String program = 'BS Computer Science';
        String role = hasFirebase ? 'student' : 'tutor';
        String college = '';
        String studentId = '';

        bool isNewAccount = hasFirebase;

        List<dynamic> goalsList = [];

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          name = data['name'] ?? name;
          program = data['program'] ?? data['course'] ?? program;
          role = data['role'] ?? role;
          college = data['college'] ?? college;
          studentId = data['studentId'] ?? studentId;
          // Determine if account is new based on missing learning stats
          isNewAccount = data['completedSessions'] == null;
          goalsList = data['academicGoals'] ?? [];

          // Auto-healing logic: if name contains digits, or if program/college is placeholder,
          // we attempt to fetch from student_directory and update Firestore in the background.
          String healedName = name;
          if (RegExp(r'\d+').hasMatch(name)) {
            String rawName = name.replaceAll(RegExp(r'\d+'), '').trim();
            healedName = rawName.replaceAll(RegExp(r'^\.+|\.+$'), '').replaceAll('.', ' ').trim().toUpperCase();
            if (healedName.isEmpty) {
              healedName = name;
            }
          }

          if (healedName != name || program == 'Select Course' || college == 'Select Department' || college.isEmpty) {
            _healProfileData(email, studentId, healedName, name, program, college);
          }
        } else {
          if (user?.displayName != null && user!.displayName!.isNotEmpty) {
            name = user.displayName!;
          } else if (user?.email != null) {
            final parts = user!.email!.split('@')[0].split('.');
            if (parts.isNotEmpty) {
              name = parts
                  .map((part) {
                    if (part.isEmpty) return '';
                    return part[0].toUpperCase() + part.substring(1);
                  })
                  .join(' ');
            }
          }
        }

        // Academic Goals list should only contain what's in Firestore
        if (goalsList.isEmpty) {
          goalsList = [];
        }

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: const CustomAppBar(
            title: 'Student Profile',
            showBackButton: false,
            centerTitle: false,
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            children: [
              // Hero Profile Header Card
              Stack(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEEEFF0)),
                    ),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            CircleAvatar(
                              radius: 46,
                              backgroundColor: AppTheme.primaryRed.withOpacity(
                                0.15,
                              ),
                              child: CircleAvatar(
                                radius: 40,
                                backgroundColor: Colors.grey.shade300,
                                backgroundImage: NetworkImage(
                                  'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=BE1E2D&color=ffffff',
                                ),
                                onBackgroundImageError: (exception, stackTrace) {},
                              ),
                            ),
                            StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance.collection('users').doc(email).snapshots(),
                              builder: (context, userSnap) {
                                String tier = 'Free';
                                if (userSnap.hasData && userSnap.data!.exists) {
                                  tier = (userSnap.data!.data() as Map<String, dynamic>)['subscriptionTier'] ?? 'Free';
                                }
                                
                                if (tier == 'Free') {
                                  return Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: AppTheme.secondaryGold,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        LucideIcons.check,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  );
                                }

                                return Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: tier == 'Tutor Pro' ? AppTheme.primaryRed : AppTheme.secondaryGold,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: Icon(
                                      tier == 'Tutor Pro' ? Icons.stars : LucideIcons.award,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          name,
                          style: GoogleFonts.manrope(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.neutralColor,
                          ),
                        ),
                        Text(
                          program,
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (college.isNotEmpty && college != 'Select Department') ...[
                          const SizedBox(height: 4),
                          Text(
                            college,
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryRed,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        if (studentId.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F3F5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'STUDENT ID: $studentId',
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF495057),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          email,
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: IconButton(
                      icon: const Icon(
                        LucideIcons.pencil,
                        size: 18,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        _showEditProfileModal(context, email, name, program, college, hasFirebase);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Subscription Upgrade Section
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(email).snapshots(),
                builder: (context, userSnap) {
                  bool isSubscribed = false;
                  if (userSnap.hasData && userSnap.data!.exists) {
                    isSubscribed = (userSnap.data!.data() as Map<String, dynamic>)['isSubscribed'] ?? false;
                  }

                  if (isSubscribed) return const SizedBox.shrink();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A1C1E), Color(0xFF2D3136)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.secondaryGold.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(LucideIcons.sparkles, color: AppTheme.secondaryGold, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Learner Lite',
                              style: GoogleFonts.manrope(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '₱49/mo',
                              style: GoogleFonts.manrope(
                                color: AppTheme.secondaryGold,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSubscriptionBenefit(LucideIcons.check, 'Premium Learner Badge'),
                        _buildSubscriptionBenefit(LucideIcons.check, 'Up to 5 active bookings'),
                        _buildSubscriptionBenefit(LucideIcons.check, 'Priority "Urgent" request tag'),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SubscriptionPaymentScreen(
                                    planName: 'Learner Lite',
                                    amount: 49.0,
                                    isTutor: false,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryRed,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            child: Text(
                              'Upgrade Now',
                              style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Learning Statistics Section
              _buildSectionTitle('Learning Statistics'),
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('bookings')
                    .where('status', isEqualTo: 'Completed')
                    .snapshots(),
                builder: (context, snapshot) {
                  int sessions = 0;
                  double totalHours = 0;

                  if (snapshot.hasData) {
                    final String userEmail = email.toLowerCase();
                    // Filter in code to support legacy 'learnerEmail' or 'studentEmail' 
                    // and to handle potential case sensitivity issues in legacy data
                    final userBookings = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final sEmail = (data['studentEmail'] ?? '').toString().toLowerCase();
                      final lEmail = (data['learnerEmail'] ?? '').toString().toLowerCase();
                      return sEmail == userEmail || lEmail == userEmail;
                    }).toList();

                    sessions = userBookings.length;
                    for (var doc in userBookings) {
                      final data = doc.data() as Map<String, dynamic>;
                      // Default to 1 hour if duration is missing for completed sessions
                      totalHours += (data['duration'] ?? 1).toDouble();
                    }
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Completed',
                          '$sessions Sessions',
                          LucideIcons.checkCircle2,
                          AppTheme.primaryRed,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Duration',
                          '${totalHours.toStringAsFixed(totalHours % 1 == 0 ? 0 : 1)} Hours',
                          LucideIcons.clock,
                          AppTheme.tertiaryIndigo,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Academic Goals Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle('Academic Goals'),
                  IconButton(
                    icon: const Icon(
                      LucideIcons.plus,
                      color: AppTheme.primaryRed,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      _showAddGoalModal(context, email, hasFirebase);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEEEFF0)),
                ),
                child: goalsList.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'No academic goals set yet.',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (int i = 0; i < goalsList.length; i++) ...[
                            _buildGoalItem(
                              i,
                              goalsList[i]['title'] ?? '',
                              'Target: ${goalsList[i]['target'] ?? ''}',
                              email,
                              hasFirebase,
                              goalsList,
                            ),
                            if (i < goalsList.length - 1)
                              const Divider(
                                height: 20,
                                color: Color(0xFFEEEFF0),
                              ),
                          ],
                        ],
                      ),
              ),
              const SizedBox(height: 24),

              // Active Bookings Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle('Active Bookings'),
                  GestureDetector(
                    onTap: () {
                      final state = context.findAncestorStateOfType<StudentLayoutState>();
                      if (state != null) {
                        state.setIndex(1);
                      }
                    },
                    child: Text(
                      'View All',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryRed,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('bookings')
                    .where('studentEmail', isEqualTo: email.toLowerCase())
                    .where('isUpcoming', isEqualTo: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primaryRed,
                        ),
                      ),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'No active bookings.',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: docs.take(3).map((doc) {
                      final booking = doc.data() as Map<String, dynamic>;
                      return _buildBookingCard(booking);
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Favorite Tutors Section
              _buildSectionTitle('Favorite Tutors'),
              const SizedBox(height: 12),
              if (isNewAccount)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'No favorite tutors yet.',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 130,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: MockData.tutors.length,
                    itemBuilder: (context, index) {
                      final tutor = MockData.tutors[index];
                      return _buildFavTutorCard(tutor);
                    },
                  ),
                ),
              const SizedBox(height: 16),

              // Tutor Application Promotion Card
              if (role != 'tutor')
                hasFirebase
                    ? StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('tutor_applications')
                            .where('email', isEqualTo: email)
                            .snapshots(),
                        builder: (context, snapshot) {
                          bool isPending = false;
                          bool isApproved = false;
                          DocumentSnapshot? pendingDoc;
                          if (snapshot.hasData &&
                              snapshot.data!.docs.isNotEmpty) {
                            for (var doc in snapshot.data!.docs) {
                              final status = doc['status'];
                              if (status == 'pending') {
                                isPending = true;
                                pendingDoc = doc;
                                break;
                              } else if (status == 'approved') {
                                isApproved = true;
                              }
                            }
                          }

                            if (isApproved) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  // Also ensure the role is set to tutor and save lastPortal
                                  if (hasFirebase) {
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(email)
                                        .set({
                                          'role': 'tutor',
                                          'lastPortal': 'tutor',
                                        }, SetOptions(merge: true));
                                  }
                                  if (context.mounted) {
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const TutorLayout(),
                                      ),
                                      (route) => false,
                                    );
                                  }
                                },
                                icon: const Icon(
                                  LucideIcons.briefcase,
                                  size: 18,
                                ),
                                label: Text(
                                  'Switch to Tutor Mode',
                                  style: GoogleFonts.manrope(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.secondaryGold,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  elevation: 0,
                                  minimumSize: const Size(double.infinity, 48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            );
                          }

                          if (isPending && pendingDoc != null) {
                            final docId = pendingDoc.id;
                            final appData =
                                pendingDoc.data() as Map<String, dynamic>;
                            final bool isAdmin =
                                role.toLowerCase() == 'admin' ||
                                role.toLowerCase() == 'superadmin' ||
                                role.toLowerCase() == 'super_admin';

                            return Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.orange.shade200,
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade100,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          LucideIcons.clock,
                                          color: Colors.orange.shade800,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Application Pending',
                                              style: GoogleFonts.manrope(
                                                color: Colors.orange.shade900,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              isAdmin
                                                  ? 'Simulate administrative review'
                                                  : 'Submitted for credentials review',
                                              style: GoogleFonts.manrope(
                                                color: Colors.orange.shade700,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    isAdmin
                                        ? 'Your tutor application is currently under administrative verification. As a developer, you can quickly review and action it below:'
                                        : 'Your peer tutor application has been successfully submitted and is currently under administrative verification. You will be notified once our team validates your credentials.',
                                    style: GoogleFonts.manrope(
                                      color: Colors.orange.shade900.withOpacity(
                                        0.85,
                                      ),
                                      fontSize: 13,
                                      height: 1.4,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (isAdmin) ...[
                                    const SizedBox(height: 18),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () async {
                                              try {
                                                // 1. Update status
                                                await FirebaseFirestore.instance
                                                    .collection(
                                                      'tutor_applications',
                                                    )
                                                    .doc(docId)
                                                    .update({
                                                      'status': 'approved',
                                                    });
                                                // 2. Add to tutors collection
                                                await FirebaseFirestore.instance
                                                    .collection('tutors')
                                                    .doc(docId)
                                                    .set({
                                                      'id': docId,
                                                      'name':
                                                          appData['name'] ??
                                                          'Verified Peer Tutor',
                                                      'college':
                                                          appData['college'] ??
                                                          'College of Engineering',
                                                      'skills':
                                                          appData['skills'] ??
                                                          [
                                                            'Calculus',
                                                            'Physics',
                                                          ],
                                                      'bio':
                                                          appData['bio'] ??
                                                          'Comprehensive academic peer guidance.',
                                                      'hourlyRate':
                                                          appData['hourlyRate'] ??
                                                          200.0,
                                                      'rating': 5.0,
                                                      'reviewsCount': 0,
                                                      'isFavorite': false,
                                                      'status': 'active',
                                                      'verifiedAt':
                                                          FieldValue.serverTimestamp(),
                                                    }, SetOptions(merge: true));
                                                // 3. Log audit event
                                                await FirebaseFirestore.instance
                                                    .collection('audit_logs')
                                                    .add({
                                                      'action':
                                                          'Approved Peer Tutor Application for ${appData['name']} (via Profile Simulator)',
                                                      'timestamp':
                                                          FieldValue.serverTimestamp(),
                                                      'adminEmail':
                                                          'simulation-admin@umindanao.edu.ph',
                                                    });
                                                // 4. Update user role with set merge: true
                                                await FirebaseFirestore.instance
                                                    .collection('users')
                                                    .doc(email)
                                                    .set({
                                                      'role': 'tutor',
                                                    }, SetOptions(merge: true));

                                                // 5. Add notification to user
                                                await FirebaseFirestore.instance
                                                    .collection('notifications')
                                                    .add({
                                                      'email': email,
                                                      'title':
                                                          'Tutor Application Approved! 🎉',
                                                      'message':
                                                          'Congratulations! Your peer tutor application has been approved. You can now switch to tutor mode in your profile settings.',
                                                      'read': false,
                                                      'timestamp':
                                                          FieldValue.serverTimestamp(),
                                                    });

                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Tutor application approved and live! Welcome to Peer Tutoring!',
                                                    ),
                                                    backgroundColor:
                                                        Colors.green,
                                                  ),
                                                );
                                              } catch (e) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Verification error: $e',
                                                    ),
                                                    backgroundColor:
                                                        AppTheme.primaryRed,
                                                  ),
                                                );
                                              }
                                            },
                                            icon: const Icon(
                                              LucideIcons.checkCircle,
                                              size: 16,
                                              color: Colors.white,
                                            ),
                                            label: Text(
                                              'Quick Approve',
                                              style: GoogleFonts.manrope(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.green.shade700,
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 12,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () async {
                                              try {
                                                // Update status
                                                await FirebaseFirestore.instance
                                                    .collection(
                                                      'tutor_applications',
                                                    )
                                                    .doc(docId)
                                                    .update({
                                                      'status': 'rejected',
                                                    });
                                                // Log audit event
                                                await FirebaseFirestore.instance
                                                    .collection('audit_logs')
                                                    .add({
                                                      'action':
                                                          'Rejected Peer Tutor Application for ${appData['name']} (via Profile Simulator)',
                                                      'timestamp':
                                                          FieldValue.serverTimestamp(),
                                                      'adminEmail':
                                                          'simulation-admin@umindanao.edu.ph',
                                                    });

                                                // Add notification to user
                                                await FirebaseFirestore.instance
                                                    .collection('notifications')
                                                    .add({
                                                      'email': email,
                                                      'title':
                                                          'Tutor Application Update 📝',
                                                      'message':
                                                          'Thank you for applying. Unfortunately, your peer tutor application has been rejected during administrative credentials review.',
                                                      'read': false,
                                                      'timestamp':
                                                          FieldValue.serverTimestamp(),
                                                    });

                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Tutor application rejected.',
                                                    ),
                                                    backgroundColor:
                                                        AppTheme.primaryRed,
                                                  ),
                                                );
                                              } catch (e) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Error rejecting application: $e',
                                                    ),
                                                    backgroundColor:
                                                        AppTheme.primaryRed,
                                                  ),
                                                );
                                              }
                                            },
                                            icon: const Icon(
                                              LucideIcons.xCircle,
                                              size: 16,
                                              color: AppTheme.primaryRed,
                                            ),
                                            label: Text(
                                              'Reject',
                                              style: GoogleFonts.manrope(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              side: const BorderSide(
                                                color: AppTheme.primaryRed,
                                                width: 1.5,
                                              ),
                                              foregroundColor:
                                                  AppTheme.primaryRed,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 12,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primaryRed,
                                  AppTheme.primaryRed.withOpacity(0.85),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryRed.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        LucideIcons.award,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Earn as a Peer Tutor',
                                      style: GoogleFonts.manrope(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Share your academic expertise with peers. Get accredited, choose your rate, and empower the UM community.',
                                  style: GoogleFonts.manrope(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const TutorApplicationScreen(),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: AppTheme.primaryRed,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      'Apply Now • Tutor Application',
                                      style: GoogleFonts.manrope(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    : Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryRed,
                              AppTheme.primaryRed.withOpacity(0.85),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryRed.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    LucideIcons.award,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Earn as a Peer Tutor',
                                  style: GoogleFonts.manrope(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Share your academic expertise with peers. Get accredited, choose your rate, and empower the UM community.',
                              style: GoogleFonts.manrope(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const TutorApplicationScreen(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppTheme.primaryRed,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  'Apply Now • Tutor Application',
                                  style: GoogleFonts.manrope(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              if (role != 'tutor') const SizedBox(height: 24),

              // Mode Switcher Button
              if (role == 'tutor') ...[
                ElevatedButton.icon(
                  onPressed: () async {
                    if (hasFirebase) {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(email)
                          .set({
                        'lastPortal': 'tutor',
                      }, SetOptions(merge: true));
                    }
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TutorLayout(),
                        ),
                        (route) => false,
                      );
                    }
                  },
                  icon: const Icon(LucideIcons.briefcase, size: 18),
                  label: Text(
                    'Switch to Tutor Mode',
                    style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryGold,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Settings Options
              _buildSettingsItem(
                context,
                LucideIcons.sparkles,
                'Manage Subscription',
                onTap: () {
                  _showSubscriptionModal(context, email, name, false);
                },
              ),
              _buildSettingsItem(
                context,
                LucideIcons.settings,
                'Account Settings',
                onTap: () {
                  _showAccountSettingsModal(
                    context: context,
                    email: email,
                    currentName: name,
                    currentDetail: program,
                    isTutorMode: false,
                    hasFirebase: hasFirebase,
                  );
                },
              ),
              _buildSettingsItem(
                context,
                LucideIcons.bell,
                'Notifications',
                onTap: () {
                  _showNotificationsModal(context);
                },
              ),
              _buildSettingsItem(
                context,
                LucideIcons.creditCard,
                'Payment Methods',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          PaymentMethodsScreen(isNewAccount: isNewAccount),
                    ),
                  );
                },
              ),
              _buildSettingsItem(
                context,
                LucideIcons.helpCircle,
                'Help & Support',
                onTap: () {
                  _showHelpSupportModal(context);
                },
              ),

              const SizedBox(height: 24),

              OutlinedButton.icon(
                onPressed: () async {
                  try {
                    await FirebaseAuth.instance.signOut();
                  } catch (e) {
                    debugPrint('Error signing out of Firebase: $e');
                  }
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(LucideIcons.logOut, size: 18),
                label: Text(
                  'Log Out',
                  style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryRed,
                  side: const BorderSide(color: AppTheme.primaryRed),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- PREMIUM TUTOR PROFILE MODE (Image 3: Maria Santos) ---
  Widget _buildTutorProfile(BuildContext context) {
    bool hasFirebase = false;
    User? user;
    try {
      if (Firebase.apps.isNotEmpty) {
        user = FirebaseAuth.instance.currentUser;
        hasFirebase = true;
      }
    } catch (_) {}

    final String email = (user?.email ?? 'tutor@umindanao.edu.ph').toLowerCase();

    final stream = hasFirebase
        ? FirebaseFirestore.instance.collection('users').doc(email).snapshots()
        : const Stream<DocumentSnapshot>.empty();

    return StreamBuilder<DocumentSnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        String name = 'Peer Tutor';
        String program = 'University of Mindanao';
        String tutorAbout = '';
        List<String> tutorExpertise = [];
        String tutorAvailabilityDays = '';
        String tutorAvailabilityHours = '';
        String tutorAvailabilityType = 'NOT SET';

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          name = data['name'] ?? name;
          program = data['program'] ?? data['course'] ?? program;
          tutorAbout = data['tutorAbout'] ?? data['about'] ?? tutorAbout;
          if (data['tutorExpertise'] != null) {
            tutorExpertise = List<String>.from(data['tutorExpertise']);
          } else if (data['expertise'] != null) {
            tutorExpertise = List<String>.from(data['expertise']);
          }
          tutorAvailabilityDays = data['tutorAvailabilityDays'] ?? data['availabilityDays'] ?? tutorAvailabilityDays;
          tutorAvailabilityHours = data['tutorAvailabilityHours'] ?? data['availabilityHours'] ?? tutorAvailabilityHours;
          tutorAvailabilityType = data['tutorAvailabilityType'] ?? data['availabilityType'] ?? tutorAvailabilityType;
        } else {
          if (user?.displayName != null && user!.displayName!.isNotEmpty) {
            name = user.displayName!;
          } else if (user?.email != null) {
            final parts = user!.email!.split('@')[0].split('.');
            if (parts.isNotEmpty) {
              name = parts
                  .map((part) {
                    if (part.isEmpty) return '';
                    return part[0].toUpperCase() + part.substring(1);
                  })
                  .join(' ');
            }
          }
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: CustomAppBar(
            subtitle: 'TUTOR PORTAL',
            centerTitle: false,
            showBackButton: false,
            leading: Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    LucideIcons.menu,
                    color: Colors.black,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Menu accessed.',
                          style: GoogleFonts.manrope(),
                        ),
                        backgroundColor: AppTheme.neutralColor,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ),
            ),
            actions: [
              hasFirebase
                  ? StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('notifications')
                          .where('email', isEqualTo: email)
                          .orderBy('timestamp', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        final docs = snapshot.data?.docs ?? [];
                        final hasUnread = docs.any(
                          (doc) => doc['read'] == false || doc['read'] == null,
                        );

                        return IconButton(
                          icon: Stack(
                            children: [
                              const Icon(
                                LucideIcons.bell,
                                color: AppTheme.primaryRed,
                                size: 22,
                              ),
                              if (hasUnread)
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.secondaryGold,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          onPressed: () {
                            _showUserNotificationsModal(context, docs);
                          },
                        );
                      },
                    )
                  : IconButton(
                      icon: const Icon(
                        LucideIcons.bell,
                        color: AppTheme.primaryRed,
                        size: 22,
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'No new notifications.',
                              style: GoogleFonts.manrope(),
                            ),
                            backgroundColor: AppTheme.primaryRed,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
              IconButton(
                icon: const Icon(
                  LucideIcons.pencil,
                  color: AppTheme.primaryRed,
                  size: 20,
                ),
                onPressed: () {
                  _showEditProfileModal(
                    context,
                    email,
                    name,
                    program,
                    '',
                    hasFirebase,
                    isTutorMode: true,
                    currentAbout: tutorAbout,
                    currentExpertise: tutorExpertise,
                    currentDays: tutorAvailabilityDays,
                    currentHours: tutorAvailabilityHours,
                    currentType: tutorAvailabilityType,
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Scrollable Content
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    children: [
                      Center(
                        child: Column(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 4,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 54,
                                    backgroundColor: Colors.grey.shade300,
                                    backgroundImage: NetworkImage(
                                      'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=BE1E2D&color=ffffff',
                                    ),
                                    onBackgroundImageError:
                                        (exception, stackTrace) {},
                                  ),
                                ),
                                Positioned(
                                  bottom: 2,
                                  right: 2,
                                  child: StreamBuilder<DocumentSnapshot>(
                                    stream: FirebaseFirestore.instance.collection('users').doc(email).snapshots(),
                                    builder: (context, userSnap) {
                                      String tier = 'Free';
                                      if (userSnap.hasData && userSnap.data!.exists) {
                                        tier = (userSnap.data!.data() as Map<String, dynamic>)['subscriptionTier'] ?? 'Free';
                                      }
                                      
                                      return Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: tier == 'Tutor Pro' ? AppTheme.primaryRed : const Color(0xFFFBB03B),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                        ),
                                        child: Icon(
                                          tier == 'Tutor Pro' ? Icons.stars : LucideIcons.award,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              name,
                              style: GoogleFonts.manrope(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1A1C1E),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              program,
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF7A7C80),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Horizontal Badges Row
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildHorizontalBadge(
                                    label: 'Student Verified',
                                    backgroundColor: const Color(0xFFFFF4EB),
                                    iconColor: const Color(0xFFD97706),
                                    icon: LucideIcons.shieldCheck,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildHorizontalBadge(
                                    label: 'Top Rated Tutor',
                                    backgroundColor: const Color(0xFFF3E8FF),
                                    iconColor: const Color(0xFF8B5CF6),
                                    icon: LucideIcons.star,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildHorizontalBadge(
                                    label: 'Dean\'s List',
                                    backgroundColor: const Color(0xFFE0F2FE),
                                    iconColor: const Color(0xFF0284C7),
                                    icon: LucideIcons.graduationCap,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Subscription Upgrade Section (Tutor)
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance.collection('users').doc(email).snapshots(),
                        builder: (context, userSnap) {
                          bool isSubscribed = false;
                          if (userSnap.hasData && userSnap.data!.exists) {
                            isSubscribed = (userSnap.data!.data() as Map<String, dynamic>)['isSubscribed'] ?? false;
                          }

                          if (isSubscribed) return const SizedBox.shrink();

                          return Container(
                            margin: const EdgeInsets.only(bottom: 24),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1A1C1E), Color(0xFF2D3136)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppTheme.secondaryGold.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(LucideIcons.zap, color: AppTheme.secondaryGold, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Tutor Pro',
                                      style: GoogleFonts.manrope(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '₱99/mo',
                                      style: GoogleFonts.manrope(
                                        color: AppTheme.secondaryGold,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildSubscriptionBenefit(LucideIcons.check, 'Featured Tutor Badge'),
                                _buildSubscriptionBenefit(LucideIcons.check, 'Rank higher in search results'),
                                _buildSubscriptionBenefit(LucideIcons.check, 'Up to 5 subject listings'),
                                _buildSubscriptionBenefit(LucideIcons.check, '3% Commission (Keep more pay)'),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const SubscriptionPaymentScreen(
                                            planName: 'Tutor Pro',
                                            amount: 99.0,
                                            isTutor: true,
                                          ),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryRed,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      elevation: 0,
                                    ),
                                    child: Text(
                                      'Upgrade to Pro',
                                      style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      // "About Me" Card
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFF5E1E1),
                            width: 1.2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  LucideIcons.user,
                                  color: AppTheme.primaryRed,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'About Me',
                                  style: GoogleFonts.manrope(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: const Color(0xFF1A1C1E),
                                  ),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () {
                                    _showEditTutorProfileDialog(
                                      context: context,
                                      email: email,
                                      currentAbout: tutorAbout,
                                      currentExpertise: tutorExpertise,
                                      currentDays: tutorAvailabilityDays,
                                      currentHours: tutorAvailabilityHours,
                                      currentType: tutorAvailabilityType,
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEE2E2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(
                                      LucideIcons.edit2,
                                      color: AppTheme.primaryRed,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              tutorAbout.isEmpty 
                                ? 'Your profile bio is empty. Tap the edit icon to tell students about yourself!' 
                                : tutorAbout,
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                height: 1.5,
                                color: tutorAbout.isEmpty ? Colors.grey : const Color(0xFF495057),
                                fontWeight: tutorAbout.isEmpty ? FontWeight.w400 : FontWeight.w500,
                                fontStyle: tutorAbout.isEmpty ? FontStyle.italic : FontStyle.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Expertise & Availability Side-by-Side Cards
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              height: 160,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFEEEFF0),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        LucideIcons.bookOpen,
                                        color: AppTheme.primaryRed,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Expertise',
                                        style: GoogleFonts.manrope(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                          color: const Color(0xFF1A1C1E),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Expanded(
                                    child: tutorExpertise.isEmpty
                                      ? Center(
                                          child: Text(
                                            'No expertise listed',
                                            style: GoogleFonts.manrope(
                                              fontSize: 12,
                                              color: Colors.grey,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        )
                                      : Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: tutorExpertise.take(3).map((item) => Padding(
                                            padding: const EdgeInsets.only(bottom: 6.0),
                                            child: _buildExpertiseItem(item),
                                          )).toList(),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              height: 160,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFEEEFF0),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        LucideIcons.clock,
                                        color: AppTheme.primaryRed,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Availability',
                                        style: GoogleFonts.manrope(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                          color: const Color(0xFF1A1C1E),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    tutorAvailabilityDays.isEmpty ? 'Not set' : tutorAvailabilityDays,
                                    style: GoogleFonts.manrope(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: tutorAvailabilityDays.isEmpty ? Colors.grey : const Color(0xFF1A1C1E),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    tutorAvailabilityHours.isEmpty ? 'Tap to edit' : tutorAvailabilityHours,
                                    style: GoogleFonts.manrope(
                                      fontSize: 12,
                                      color: const Color(0xFF7A7C80),
                                      fontWeight: FontWeight.w500,
                                      fontStyle: tutorAvailabilityHours.isEmpty ? FontStyle.italic : FontStyle.normal,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const Spacer(),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: tutorAvailabilityType == 'NOT SET' ? Colors.grey.shade100 : const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      tutorAvailabilityType.toUpperCase(),
                                      style: GoogleFonts.manrope(
                                        color: tutorAvailabilityType == 'NOT SET' ? Colors.grey : const Color(0xFFD97706),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 8.5,
                                        letterSpacing: 0.2,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Dynamic Reviews Section from Firestore
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(email)
                            .collection('reviews')
                            .orderBy('timestamp', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.primaryRed,
                                  ),
                                ),
                              ),
                            );
                          }

                          final reviewDocs = snapshot.data?.docs ?? [];

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Student Reviews',
                                    style: GoogleFonts.manrope(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF1A1C1E),
                                    ),
                                  ),
                                  if (reviewDocs.isNotEmpty)
                                    GestureDetector(
                                      onTap: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Viewing all ${reviewDocs.length} student reviews.',
                                              style: GoogleFonts.manrope(),
                                            ),
                                            backgroundColor: AppTheme.neutralColor,
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      },
                                      child: Text(
                                        'View All',
                                        style: GoogleFonts.manrope(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.primaryRed,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (reviewDocs.isEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFEEEFF0), width: 1),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        LucideIcons.messageSquare,
                                        color: Colors.grey.shade400,
                                        size: 28,
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'No reviews yet',
                                        style: GoogleFonts.manrope(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: const Color(0xFF495057),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Share your knowledge to earn feedback!',
                                        style: GoogleFonts.manrope(
                                          fontSize: 11,
                                          color: const Color(0xFF7A7C80),
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                )
                              else
                                ...reviewDocs.take(3).map((doc) {
                                  final rev = doc.data() as Map<String, dynamic>;
                                  final rName = rev['studentName'] ?? 'Anonymous student';
                                  final rComment = rev['comment'] ?? '';
                                  final rStars = rev['rating'] ?? 5;
                                  final initials = rName.isNotEmpty 
                                      ? rName.substring(0, (rName.length > 2 ? 2 : rName.length)).toUpperCase() 
                                      : 'ST';
                                  
                                  String rTime = 'Just now';
                                  if (rev['timestamp'] != null) {
                                    final ts = rev['timestamp'] as Timestamp;
                                    final diff = DateTime.now().difference(ts.toDate());
                                    if (diff.inDays > 7) {
                                      rTime = '${(diff.inDays / 7).floor()} weeks ago';
                                    } else if (diff.inDays > 0) {
                                      rTime = '${diff.inDays} days ago';
                                    } else if (diff.inHours > 0) {
                                      rTime = '${diff.inHours} hours ago';
                                    } else if (diff.inMinutes > 0) {
                                      rTime = '${diff.inMinutes} minutes ago';
                                    }
                                  }

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _buildTutorReviewCard(
                                      initials: initials,
                                      avatarColor: const Color(0xFFE2E8F0),
                                      name: rName,
                                      stars: rStars is int ? rStars : 5,
                                      time: rTime,
                                      comment: rComment,
                                    ),
                                  );
                                }).toList(),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // Switch Mode
                      ElevatedButton.icon(
                        onPressed: () async {
                          if (hasFirebase) {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(email)
                                .set({
                              'lastPortal': 'student',
                            }, SetOptions(merge: true));
                          }
                          if (context.mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const StudentLayout(),
                              ),
                              (route) => false,
                            );
                          }
                        },
                        icon: const Icon(LucideIcons.graduationCap, size: 18),
                        label: Text(
                          'Switch to Student Mode',
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      _buildSettingsItem(
                        context,
                        LucideIcons.sparkles,
                        'Manage Subscription',
                        onTap: () {
                          _showSubscriptionModal(context, email, name, true);
                        },
                      ),
                      _buildSettingsItem(
                        context,
                        LucideIcons.settings,
                        'Account Settings',
                        onTap: () {
                          _showAccountSettingsModal(
                            context: context,
                            email: email,
                            currentName: name,
                            currentDetail: program,
                            isTutorMode: true,
                            hasFirebase: hasFirebase,
                          );
                        },
                      ),
                      _buildSettingsItem(
                        context,
                        LucideIcons.bell,
                        'Notifications',
                        onTap: () {
                          _showNotificationsModal(context);
                        },
                      ),
                      _buildSettingsItem(
                        context,
                        LucideIcons.wallet,
                        'Earnings & Payouts',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const PaymentMethodsScreen(),
                            ),
                          );
                        },
                      ),
                      _buildSettingsItem(
                        context,
                        LucideIcons.helpCircle,
                        'Help & Support',
                        onTap: () {
                          _showHelpSupportModal(context);
                        },
                      ),
                      const SizedBox(height: 16),

                      OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            await FirebaseAuth.instance.signOut();
                          } catch (e) {
                            debugPrint('Error signing out of Firebase: $e');
                          }
                          if (context.mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                              (route) => false,
                            );
                          }
                        },
                        icon: const Icon(LucideIcons.logOut, size: 18),
                        label: Text(
                          'Log Out',
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryRed,
                          side: const BorderSide(color: AppTheme.primaryRed),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHorizontalBadge({
    required String label,
    required Color backgroundColor,
    required Color iconColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.manrope(
              color: iconColor,
              fontWeight: FontWeight.w800,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpertiseItem(String subject) {
    return Row(
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            color: AppTheme.primaryRed,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          subject,
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: const Color(0xFF495057),
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionBenefit(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.secondaryGold, size: 14),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.manrope(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _handleUpgrade(BuildContext context, String email, String plan, double amount) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed)),
    );

    try {
      final now = DateTime.now();
      final expiry = DateTime(now.year, now.month + 1, now.day);

      // 1. Update User Document - use subscriptionTier for consistency with details screen
      await FirebaseFirestore.instance.collection('users').doc(email.toLowerCase()).set({
        'isSubscribed': true,
        'subscriptionTier': plan,
        'subscriptionPlan': plan,
        'commissionRate': plan == 'Tutor Pro' ? 0.03 : 0.05,
      }, SetOptions(merge: true));

      // 2. Add to Subscriptions Collection (for Admin to see)
      await FirebaseFirestore.instance.collection('subscriptions').add({
        'userName': email.split('@')[0].replaceAll('.', ' ').toUpperCase(),
        'userEmail': email.toLowerCase(),
        'tutorName': email.split('@')[0].replaceAll('.', ' ').toUpperCase(), 
        'tutorEmail': email.toLowerCase(),
        'plan': plan,
        'amount': amount, // Store as number for admin stats
        'status': 'Active',
        'billingCycle': 'Monthly',
        'nextBilling': Timestamp.fromDate(expiry),
        'subscribedAt': FieldValue.serverTimestamp(),
      });

      // 3. Log to Transactions (for Admin revenue tracking)
      await FirebaseFirestore.instance.collection('transactions').add({
        'user': email.toLowerCase(),
        'amount': amount,
        'type': 'Subscription: $plan',
        'status': 'Completed',
        'date': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        Navigator.pop(context); // Pop loading
        Navigator.pop(context); // Pop modal if open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome to $plan! Features activated.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Pop loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upgrade failed: $e'), backgroundColor: AppTheme.primaryRed),
        );
      }
    }
  }

  void _showSubscriptionModal(BuildContext context, String email, String name, bool isTutor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(email).snapshots(),
          builder: (context, snapshot) {
            String currentTier = 'Free';
            bool isSubscribed = false;
            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>;
              currentTier = data['subscriptionTier'] ?? data['subscriptionPlan'] ?? 'Free';
              isSubscribed = data['isSubscribed'] ?? false;
            }

            return Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isTutor ? 'Tutor Pro Subscription' : 'Learner Lite Subscription',
                        style: GoogleFonts.manrope(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.neutralColor,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x, color: Colors.grey),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isTutor 
                      ? 'Boost your tutoring visibility and keep more of your earnings.'
                      : 'Unlock priority requests and extended booking limits.',
                    style: GoogleFonts.manrope(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  
                  if (!isTutor)
                    // Learner Lite Card
                    _buildTierCard(
                      context,
                      title: 'Learner Lite',
                      price: '₱49/mo',
                      benefits: [
                        'Premium Learner Badge',
                        'Up to 5 active bookings',
                        'Priority "Urgent" request tag',
                      ],
                      color: AppTheme.secondaryGold,
                      isCurrent: currentTier == 'Learner Lite',
                      onUpgrade: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SubscriptionPaymentScreen(
                              planName: 'Learner Lite',
                              amount: 49.0,
                              isTutor: false,
                            ),
                          ),
                        );
                      },
                    ),
                  
                  if (isTutor)
                    // Tutor Pro Card
                    _buildTierCard(
                      context,
                      title: 'Tutor Pro',
                      price: '₱99/mo',
                      benefits: [
                        'Featured Tutor Badge',
                        'Rank higher in search results',
                        'Up to 5 subject listings',
                        '3% Commission (Keep more pay)',
                      ],
                      color: AppTheme.primaryRed,
                      isCurrent: currentTier == 'Tutor Pro',
                      onUpgrade: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SubscriptionPaymentScreen(
                              planName: 'Tutor Pro',
                              amount: 99.0,
                              isTutor: true,
                            ),
                          ),
                        );
                      },
                    ),
                  
                  const SizedBox(height: 24),
                  if (isSubscribed && ((isTutor && currentTier == 'Tutor Pro') || (!isTutor && currentTier == 'Learner Lite')))
                    Center(
                      child: TextButton(
                        onPressed: () => _handleCancellation(context, email, currentTier),
                        child: Text(
                          'Cancel Subscription',
                          style: GoogleFonts.manrope(color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _handleCancellation(BuildContext context, String email, String currentTier) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed)),
    );

    try {
      final batch = FirebaseFirestore.instance.batch();

      // 1. Update User Document
      batch.set(
        FirebaseFirestore.instance.collection('users').doc(email.toLowerCase()),
        {
          'isSubscribed': false,
          'subscriptionTier': 'Free',
          'subscriptionPlan': 'Free',
          'commissionRate': 0.05,
        },
        SetOptions(merge: true),
      );

      // 2. Add Transaction Log (Optional: show as Cancelled)
      final transRef = FirebaseFirestore.instance.collection('transactions').doc();
      batch.set(transRef, {
        'id': transRef.id,
        'user': email.toLowerCase(),
        'amount': 0.0,
        'type': 'Subscription Cancelled: $currentTier',
        'status': 'Cancelled',
        'date': FieldValue.serverTimestamp(),
      });

      // 3. Update active subscription record in database
      final subDocs = await FirebaseFirestore.instance
          .collection('subscriptions')
          .where('userEmail', isEqualTo: email.toLowerCase())
          .where('status', isEqualTo: 'Active')
          .get();
      
      for (var doc in subDocs.docs) {
        batch.update(doc.reference, {'status': 'Cancelled', 'cancelledAt': FieldValue.serverTimestamp()});
      }

      await batch.commit();

      // 4. Notify Admin about the cancellation
      await NotificationService.sendAdminNotification(
        'Subscription Cancelled ⚠️',
        '$email has cancelled their $currentTier subscription.',
        'subscription_cancelled',
      );

      if (context.mounted) {
        Navigator.pop(context); // Pop loading
        Navigator.pop(context); // Pop modal
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription successfully cancelled.'),
            backgroundColor: AppTheme.neutralColor,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Pop loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cancellation failed: $e'), backgroundColor: AppTheme.primaryRed),
        );
      }
    }
  }

  Widget _buildTierCard(
    BuildContext context, {
    required String title,
    required String price,
    required List<String> benefits,
    required Color color,
    required bool isCurrent,
    required VoidCallback onUpgrade,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1C1E),
        borderRadius: BorderRadius.circular(16),
        border: isCurrent ? Border.all(color: color, width: 2) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                price,
                style: GoogleFonts.manrope(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...benefits.map((b) => _buildSubscriptionBenefit(LucideIcons.check, b)).toList(),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isCurrent ? null : onUpgrade,
              style: ElevatedButton.styleFrom(
                backgroundColor: isCurrent ? Colors.grey : AppTheme.primaryRed,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: Text(
                isCurrent ? 'Current Plan' : 'Upgrade Now',
                style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTutorReviewCard({
    required String initials,
    required Color avatarColor,
    required String name,
    required int stars,
    required String time,
    required String comment,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEFF0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: avatarColor,
                child: Text(
                  initials,
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                name,
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: const Color(0xFF1A1C1E),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < stars ? Icons.star : Icons.star_border,
                    color: AppTheme.secondaryGold,
                    size: 11,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                time,
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '“$comment”',
            style: GoogleFonts.manrope(
              fontSize: 12.5,
              fontStyle: FontStyle.italic,
              color: const Color(0xFF495057),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppTheme.neutralColor,
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEFF0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.neutralColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalItem(int index, String text, String target, String email, bool hasFirebase, List<dynamic> goalsList) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.neutralColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                target,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.primaryRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Active',
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryRed,
            ),
          ),
        ),
        const SizedBox(width: 10),
        IconButton(
          icon: const Icon(
            LucideIcons.pencil,
            size: 16,
            color: Colors.grey,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () {
            _showEditGoalModal(context, index, text, target.replaceAll('Target: ', ''), email, hasFirebase, goalsList);
          },
        ),
        const SizedBox(width: 12),
        IconButton(
          icon: Icon(
            LucideIcons.trash2,
            size: 16,
            color: Colors.red.shade400,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () {
            _showDeleteGoalConfirmation(context, index, text, email, hasFirebase, goalsList);
          },
        ),
      ],
    );
  }

  void _showEditGoalModal(
    BuildContext context,
    int index,
    String currentTitle,
    String currentTarget,
    String email,
    bool hasFirebase,
    List<dynamic> goalsList,
  ) {
    final titleController = TextEditingController(text: currentTitle);
    final targetController = TextEditingController(text: currentTarget);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            top: 24,
            left: 24,
            right: 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Academic Goal',
                style: GoogleFonts.manrope(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.neutralColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Update your goal and timeframe settings.',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Goal Title',
                  labelStyle: GoogleFonts.manrope(color: Colors.grey.shade500),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primaryRed),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: targetController,
                decoration: InputDecoration(
                  labelText: 'Target Timeframe',
                  labelStyle: GoogleFonts.manrope(color: Colors.grey.shade500),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primaryRed),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    final target = targetController.text.trim();
                    if (title.isEmpty || target.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Please fill in all fields',
                            style: GoogleFonts.manrope(),
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    List<dynamic> updatedGoals = List.from(goalsList);
                    updatedGoals[index] = {'title': title, 'target': target};

                    if (hasFirebase) {
                      try {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(email)
                            .set({
                          'academicGoals': updatedGoals,
                        }, SetOptions(merge: true));
                      } catch (e) {
                        debugPrint('Error updating academic goal: $e');
                      }
                    } else {
                      if (index < MockData.academicGoals.length) {
                        MockData.academicGoals[index] = {'title': title, 'target': target};
                      }
                    }

                    Navigator.pop(context);
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Goal updated successfully!',
                          style: GoogleFonts.manrope(),
                        ),
                        backgroundColor: AppTheme.primaryRed,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRed,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Save Changes',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteGoalConfirmation(
    BuildContext context,
    int index,
    String title,
    String email,
    bool hasFirebase,
    List<dynamic> goalsList,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Delete Goal',
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.bold,
              color: AppTheme.neutralColor,
            ),
          ),
          content: Text(
            'Are you sure you want to delete the goal "$title"?',
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                List<dynamic> updatedGoals = List.from(goalsList);
                updatedGoals.removeAt(index);

                if (hasFirebase) {
                  try {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(email)
                        .set({
                      'academicGoals': updatedGoals,
                    }, SetOptions(merge: true));
                  } catch (e) {
                    debugPrint('Error deleting academic goal: $e');
                  }
                } else {
                  if (index < MockData.academicGoals.length) {
                    MockData.academicGoals.removeAt(index);
                  }
                }

                Navigator.pop(context);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Goal deleted successfully',
                      style: GoogleFonts.manrope(),
                    ),
                    backgroundColor: AppTheme.primaryRed,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRed,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Delete',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final bool isUpcoming = booking['isUpcoming'] ?? false;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEFF0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isUpcoming
                  ? AppTheme.primaryRed.withOpacity(0.1)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isUpcoming ? LucideIcons.calendar : LucideIcons.checkSquare,
              color: isUpcoming ? AppTheme.primaryRed : Colors.grey.shade600,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking['subject'],
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.neutralColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tutor: ${booking['tutorName']} • ${booking['time']}',
                  style: GoogleFonts.manrope(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isUpcoming
                  ? const Color(0xFFE3F2FD)
                  : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              booking['status'],
              style: GoogleFonts.manrope(
                color: isUpcoming
                    ? Colors.blue.shade800
                    : Colors.green.shade800,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavTutorCard(Map<String, dynamic> tutor) {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEFF0)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppTheme.tertiaryIndigo.withOpacity(0.1),
            child: const Icon(
              LucideIcons.user,
              color: AppTheme.tertiaryIndigo,
              size: 22,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tutor['name'],
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: AppTheme.neutralColor,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: AppTheme.secondaryGold, size: 12),
              const SizedBox(width: 2),
              Text(
                tutor['rating'].toString(),
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.neutralColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context,
    IconData icon,
    String title, {
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEEEFF0)),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.grey.shade600, size: 20),
        title: Text(
          title,
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppTheme.neutralColor,
          ),
        ),
        trailing: Icon(
          LucideIcons.chevronRight,
          color: Colors.grey.shade400,
          size: 18,
        ),
        onTap:
            onTap ??
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Opening $title...',
                    style: GoogleFonts.manrope(),
                  ),
                  backgroundColor: AppTheme.neutralColor,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 1),
                ),
              );
            },
      ),
    );
  }

  void _showAddGoalModal(BuildContext context, String email, bool hasFirebase) {
    final titleController = TextEditingController();
    final targetController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            top: 24,
            left: 24,
            right: 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Academic Goal',
                style: GoogleFonts.manrope(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.neutralColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Set a new goal to track your academic progress.',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  hintText: 'e.g. Master Python Programming',
                  hintStyle: GoogleFonts.manrope(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primaryRed),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: targetController,
                decoration: InputDecoration(
                  hintText: 'Target timeframe (e.g. End of Term)',
                  hintStyle: GoogleFonts.manrope(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primaryRed),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    final target = targetController.text.trim();
                    if (title.isEmpty || target.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Please fill in all fields',
                            style: GoogleFonts.manrope(),
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final newGoal = {'title': title, 'target': target};

                    if (hasFirebase) {
                      try {
                        final docRef = FirebaseFirestore.instance
                            .collection('users')
                            .doc(email);
                        final docSnap = await docRef.get();
                        List<dynamic> currentGoals = [];
                        if (docSnap.exists) {
                          final data = docSnap.data() as Map<String, dynamic>;
                          currentGoals = List.from(data['academicGoals'] ?? []);
                        }
                        currentGoals.add(newGoal);
                        await docRef.set({
                          'academicGoals': currentGoals,
                        }, SetOptions(merge: true));
                      } catch (e) {
                        debugPrint('Error saving academic goal: $e');
                      }
                    } else {
                      MockData.addMockGoal(newGoal);
                    }

                    Navigator.pop(context);
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Goal added successfully!',
                          style: GoogleFonts.manrope(),
                        ),
                        backgroundColor: AppTheme.primaryRed,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRed,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Save Goal',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAccountSettingsModal({
    required BuildContext context,
    required String email,
    required String currentName,
    required String currentDetail,
    required bool isTutorMode,
    required bool hasFirebase,
  }) {
    final nameController = TextEditingController(text: currentName);
    final detailController = TextEditingController(text: currentDetail);
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 24,
                left: 24,
                right: 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Account Settings',
                        style: GoogleFonts.manrope(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.neutralColor,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x, color: Colors.grey),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: AppTheme.primaryRed.withOpacity(
                            0.15,
                          ),
                          child: CircleAvatar(
                            radius: 36,
                            backgroundColor: AppTheme.primaryRed,
                            child: Text(
                              currentName.isNotEmpty
                                  ? currentName[0].toUpperCase()
                                  : 'U',
                              style: GoogleFonts.manrope(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppTheme.secondaryGold,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.camera,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Email Address',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      email,
                      style: GoogleFonts.manrope(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Full Name',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Juan Dela Cruz',
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryRed,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isTutorMode
                        ? 'About Me / Bio'
                        : 'Academic Program / Course',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: detailController,
                    decoration: InputDecoration(
                      hintText: isTutorMode
                          ? 'e.g. Passionate Calc II Tutor...'
                          : 'e.g. BS Computer Science',
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryRed,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              final newName = nameController.text.trim();
                              final newDetail = detailController.text.trim();
                              if (newName.isEmpty || newDetail.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Please fill in all fields',
                                      style: GoogleFonts.manrope(),
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              setModalState(() {
                                isLoading = true;
                              });

                              if (hasFirebase) {
                                try {
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(email)
                                      .set({
                                        'name': newName,
                                        'program': newDetail,
                                        'course': newDetail,
                                      }, SetOptions(merge: true));
                                } catch (e) {
                                  debugPrint('Error updating user info: $e');
                                }
                              }

                              setModalState(() {
                                isLoading = false;
                              });

                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Account details saved successfully!',
                                    style: GoogleFonts.manrope(),
                                  ),
                                  backgroundColor: AppTheme.primaryRed,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryRed,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              'Save Changes',
                              style: GoogleFonts.manrope(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEditTutorProfileDialog({
    required BuildContext context,
    required String email,
    required String currentAbout,
    required List<String> currentExpertise,
    required String currentDays,
    required String currentHours,
    required String currentType,
  }) {
    final aboutController = TextEditingController(text: currentAbout);
    final expertiseController = TextEditingController(text: currentExpertise.join(', '));
    final daysController = TextEditingController(text: currentDays);
    final hoursController = TextEditingController(text: currentHours);
    String selectedType = currentType.toUpperCase();
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 24,
                left: 24,
                right: 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Edit Tutor Profile',
                          style: GoogleFonts.manrope(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.neutralColor,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.x, color: Colors.grey),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Introduction / About Me',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: aboutController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Describe yourself and your tutoring methodology...',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryRed,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Expertise (comma separated)',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: expertiseController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Calculus II, Physics, General Chemistry',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryRed,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Availability Days',
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: daysController,
                                decoration: InputDecoration(
                                  hintText: 'e.g. Mon - Fri',
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade200),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade200),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppTheme.primaryRed,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Availability Hours',
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: hoursController,
                                decoration: InputDecoration(
                                  hintText: 'e.g. After 5:00 PM',
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade200),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade200),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppTheme.primaryRed,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Delivery Mode',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedType,
                          isExpanded: true,
                          style: GoogleFonts.manrope(
                            color: AppTheme.neutralColor,
                            fontWeight: FontWeight.w600,
                          ),
                          icon: const Icon(LucideIcons.chevronDown, size: 18),
                          items: const [
                            DropdownMenuItem(
                              value: 'ON-CAMPUS ONLY',
                              child: Text('ON-CAMPUS ONLY'),
                            ),
                            DropdownMenuItem(
                              value: 'ONLINE ONLY',
                              child: Text('ONLINE ONLY'),
                            ),
                            DropdownMenuItem(
                              value: 'HYBRID',
                              child: Text('HYBRID'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() {
                                selectedType = val;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () async {
                                final newAbout = aboutController.text.trim();
                                final newExpertiseString = expertiseController.text.trim();
                                final newDays = daysController.text.trim();
                                final newHours = hoursController.text.trim();

                                if (newAbout.isEmpty || newExpertiseString.isEmpty || newDays.isEmpty || newHours.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Please fill in all fields',
                                        style: GoogleFonts.manrope(),
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                final List<String> newExpertise = newExpertiseString
                                    .split(',')
                                    .map((e) => e.trim())
                                    .where((e) => e.isNotEmpty)
                                    .toList();

                                setModalState(() {
                                  isLoading = true;
                                });

                                try {
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(email)
                                      .set({
                                        'tutorAbout': newAbout,
                                        'tutorExpertise': newExpertise,
                                        'tutorAvailabilityDays': newDays,
                                        'tutorAvailabilityHours': newHours,
                                        'tutorAvailabilityType': selectedType,
                                      }, SetOptions(merge: true));
                                } catch (e) {
                                  debugPrint('Error updating tutor profile: $e');
                                }

                                setModalState(() {
                                  isLoading = false;
                                });

                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Tutor profile updated successfully!',
                                        style: GoogleFonts.manrope(),
                                      ),
                                      backgroundColor: AppTheme.primaryRed,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryRed,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                'Save Tutor Details',
                                style: GoogleFonts.manrope(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showNotificationsModal(BuildContext context) {
    bool pushVal = true;
    bool emailVal = false;
    bool smsVal = true;
    bool soundVal = true;
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Notification Settings',
                        style: GoogleFonts.manrope(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.neutralColor,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x, color: Colors.grey),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose how you would like to be notified about sessions, messages, and platform updates.',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SwitchListTile.adaptive(
                    value: pushVal,
                    activeColor: AppTheme.primaryRed,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Push Notifications',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.neutralColor,
                      ),
                    ),
                    subtitle: Text(
                      'Receive real-time alerts for bookings and chats on your device.',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    onChanged: (val) {
                      setModalState(() {
                        pushVal = val;
                      });
                    },
                  ),
                  const Divider(height: 24),
                  SwitchListTile.adaptive(
                    value: emailVal,
                    activeColor: AppTheme.primaryRed,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Email Recaps & Updates',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.neutralColor,
                      ),
                    ),
                    subtitle: Text(
                      'Get weekly recaps of your sessions and learning progress.',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    onChanged: (val) {
                      setModalState(() {
                        emailVal = val;
                      });
                    },
                  ),
                  const Divider(height: 24),
                  SwitchListTile.adaptive(
                    value: smsVal,
                    activeColor: AppTheme.primaryRed,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'SMS Session Reminders',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.neutralColor,
                      ),
                    ),
                    subtitle: Text(
                      'Get a text message 15 minutes before your booked slots.',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    onChanged: (val) {
                      setModalState(() {
                        smsVal = val;
                      });
                    },
                  ),
                  const Divider(height: 24),
                  SwitchListTile.adaptive(
                    value: soundVal,
                    activeColor: AppTheme.primaryRed,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'In-App Audio Feedback',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.neutralColor,
                      ),
                    ),
                    subtitle: Text(
                      'Play micro-interaction sounds for button clicks and success triggers.',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    onChanged: (val) {
                      setModalState(() {
                        soundVal = val;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              setModalState(() {
                                isLoading = true;
                              });
                              await Future.delayed(
                                const Duration(milliseconds: 600),
                              );
                              setModalState(() {
                                isLoading = false;
                              });
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Notification preferences updated successfully!',
                                    style: GoogleFonts.manrope(),
                                  ),
                                  backgroundColor: AppTheme.primaryRed,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryRed,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              'Save Preferences',
                              style: GoogleFonts.manrope(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showHelpSupportModal(BuildContext context) {
    int expandedIndex = -1;
    final ticketController = TextEditingController();
    bool isSubmitting = false;

    final faqs = [
      {
        'q': 'How do I request a peer tutor?',
        'a':
            'Simply head to the Marketplace from the main dashboard, search for subjects or click on a tutor card, and tap the "Book Session" button to select your slot and submit.',
      },
      {
        'q': 'How do I verify my academic status?',
        'a':
            'Go to the Account Verification portal, enter your UMindanao Student ID, and upload a photo of your Certificate of Registration (COR) for prompt Super Admin approval.',
      },
      {
        'q': 'What is the commission rate for tutors?',
        'a':
            'UM SkillLink currently takes a nominal flat transaction service fee of 5.0% on processed peer-tutoring session payouts to fund platform development and infrastructure.',
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 24,
                left: 24,
                right: 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Help & FAQ Support',
                        style: GoogleFonts.manrope(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.neutralColor,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x, color: Colors.grey),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Frequently Asked Questions',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.neutralColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    children: List.generate(faqs.length, (idx) {
                      final isOpen = expandedIndex == idx;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: isOpen
                              ? AppTheme.primaryRed.withOpacity(0.03)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isOpen
                                ? AppTheme.primaryRed.withOpacity(0.3)
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              title: Text(
                                faqs[idx]['q']!,
                                style: GoogleFonts.manrope(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppTheme.neutralColor,
                                ),
                              ),
                              trailing: Icon(
                                isOpen
                                    ? LucideIcons.chevronUp
                                    : LucideIcons.chevronDown,
                                size: 16,
                                color: isOpen
                                    ? AppTheme.primaryRed
                                    : Colors.grey,
                              ),
                              onTap: () {
                                setModalState(() {
                                  expandedIndex = isOpen ? -1 : idx;
                                });
                              },
                            ),
                            if (isOpen)
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 16,
                                  right: 16,
                                  bottom: 16,
                                ),
                                child: Text(
                                  faqs[idx]['a']!,
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    height: 1.5,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Submit Support Ticket',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.neutralColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: ticketController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Describe your issue or custom request here...',
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryRed,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final message = ticketController.text.trim();
                              if (message.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please write down your question or issue first.',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              setModalState(() {
                                isSubmitting = true;
                              });
                              await Future.delayed(
                                const Duration(milliseconds: 700),
                              );
                              setModalState(() {
                                isSubmitting = false;
                              });

                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Support ticket submitted successfully! We\'ll email you shortly.',
                                    style: GoogleFonts.manrope(),
                                  ),
                                  backgroundColor: AppTheme.primaryRed,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryRed,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              'Submit Custom Ticket',
                              style: GoogleFonts.manrope(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showUserNotificationsModal(
    BuildContext context,
    List<QueryDocumentSnapshot> notifications,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final unreadDocs = notifications
                .where((doc) => doc['read'] == false || doc['read'] == null)
                .toList();

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Notifications',
                          style: GoogleFonts.manrope(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.neutralColor,
                          ),
                        ),
                        if (unreadDocs.isNotEmpty)
                          TextButton(
                            onPressed: () async {
                              for (var doc in unreadDocs) {
                                await doc.reference.update({'read': true});
                              }
                              setModalState(() {});
                            },
                            child: Text(
                              'Mark all as read',
                              style: GoogleFonts.manrope(
                                color: AppTheme.primaryRed,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: notifications.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  LucideIcons.bellOff,
                                  size: 48,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No new notifications.',
                                  style: GoogleFonts.manrope(
                                    color: Colors.grey.shade600,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            itemCount: notifications.length,
                            itemBuilder: (context, index) {
                              final doc = notifications[index];
                              final data = doc.data() as Map<String, dynamic>;
                              final title = data['title'] ?? 'Notification';
                              final message = data['message'] ?? '';
                              final isRead = data['read'] ?? false;
                              final timestamp = data['timestamp'] as Timestamp?;

                              String timeAgo = 'Just now';
                              if (timestamp != null) {
                                final diff = DateTime.now().difference(
                                  timestamp.toDate(),
                                );
                                if (diff.inMinutes < 1) {
                                  timeAgo = 'Just now';
                                } else if (diff.inMinutes < 60) {
                                  timeAgo = '${diff.inMinutes}m ago';
                                } else if (diff.inHours < 24) {
                                  timeAgo = '${diff.inHours}h ago';
                                } else {
                                  timeAgo = '${diff.inDays}d ago';
                                }
                              }

                              return Card(
                                elevation: 0,
                                color: isRead
                                    ? Colors.white
                                    : Colors.red.shade50.withOpacity(0.4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: isRead
                                        ? Colors.grey.shade200
                                        : Colors.red.shade100,
                                    width: 1,
                                  ),
                                ),
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () async {
                                    if (!isRead) {
                                      await doc.reference.update({
                                        'read': true,
                                      });
                                      setModalState(() {});
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: isRead
                                                ? Colors.grey.shade100
                                                : Colors.red.shade100,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            LucideIcons.bell,
                                            size: 18,
                                            color: isRead
                                                ? Colors.grey.shade600
                                                : AppTheme.primaryRed,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      title,
                                                      style:
                                                          GoogleFonts.manrope(
                                                            fontWeight: isRead
                                                                ? FontWeight
                                                                      .bold
                                                                : FontWeight
                                                                      .w800,
                                                            fontSize: 14,
                                                            color: AppTheme
                                                                .neutralColor,
                                                          ),
                                                    ),
                                                  ),
                                                  Text(
                                                    timeAgo,
                                                    style: GoogleFonts.manrope(
                                                      fontSize: 11,
                                                      color:
                                                          Colors.grey.shade500,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                message,
                                                style: GoogleFonts.manrope(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade700,
                                                  height: 1.4,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEditProfileModal(
    BuildContext context,
    String email,
    String currentName,
    String currentProgram,
    String currentCollege,
    bool hasFirebase, {
    bool isTutorMode = false,
    String currentAbout = '',
    List<String> currentExpertise = const [],
    String currentDays = '',
    String currentHours = '',
    String currentType = '',
  }) {
    final nameController = TextEditingController(text: currentName);
    final programController = TextEditingController(text: currentProgram);
    final collegeController = TextEditingController(text: currentCollege);
    final aboutController = TextEditingController(text: currentAbout);
    final expertiseController = TextEditingController(text: currentExpertise.join(', '));
    final daysController = TextEditingController(text: currentDays);
    final hoursController = TextEditingController(text: currentHours);
    final typeController = TextEditingController(text: currentType);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            top: 24,
            left: 24,
            right: 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isTutorMode ? 'Edit Tutor Profile' : 'Edit Profile Info',
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.neutralColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isTutorMode
                      ? 'Update your tutor details and availability settings.'
                      : 'Update your name, course, and department.',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    labelStyle: GoogleFonts.manrope(color: Colors.grey.shade500),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.primaryRed),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: programController,
                  decoration: InputDecoration(
                    labelText: 'Course / Program',
                    labelStyle: GoogleFonts.manrope(color: Colors.grey.shade500),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.primaryRed),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: collegeController,
                  decoration: InputDecoration(
                    labelText: 'College / Department',
                    labelStyle: GoogleFonts.manrope(color: Colors.grey.shade500),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.primaryRed),
                    ),
                  ),
                ),
                if (isTutorMode) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: aboutController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'About Me (Bio)',
                      labelStyle: GoogleFonts.manrope(color: Colors.grey.shade500),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.primaryRed),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: expertiseController,
                    decoration: InputDecoration(
                      labelText: 'Expertise / Subjects (comma separated)',
                      labelStyle: GoogleFonts.manrope(color: Colors.grey.shade500),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.primaryRed),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: daysController,
                    decoration: InputDecoration(
                      labelText: 'Availability Days (e.g., Mon - Fri)',
                      labelStyle: GoogleFonts.manrope(color: Colors.grey.shade500),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.primaryRed),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: hoursController,
                    decoration: InputDecoration(
                      labelText: 'Availability Hours (e.g., After 5:00 PM)',
                      labelStyle: GoogleFonts.manrope(color: Colors.grey.shade500),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.primaryRed),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: typeController,
                    decoration: InputDecoration(
                      labelText: 'Availability Type (e.g., ON-CAMPUS ONLY)',
                      labelStyle: GoogleFonts.manrope(color: Colors.grey.shade500),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.primaryRed),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final nameVal = nameController.text.trim();
                      final progVal = programController.text.trim();
                      final collVal = collegeController.text.trim();
                      final aboutVal = aboutController.text.trim();
                      final expertiseVal = expertiseController.text.trim();
                      final daysVal = daysController.text.trim();
                      final hoursVal = hoursController.text.trim();
                      final typeVal = typeController.text.trim();

                      if (nameVal.isEmpty || progVal.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Name and Course/Program cannot be empty',
                              style: GoogleFonts.manrope(),
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      if (hasFirebase) {
                        try {
                          final Map<String, dynamic> data = {
                            'name': nameVal,
                            'program': progVal,
                            'college': collVal,
                          };
                          if (isTutorMode) {
                            data['tutorAbout'] = aboutVal;
                            data['tutorExpertise'] = expertiseVal
                                .split(',')
                                .map((e) => e.trim())
                                .where((e) => e.isNotEmpty)
                                .toList();
                            data['tutorAvailabilityDays'] = daysVal;
                            data['tutorAvailabilityHours'] = hoursVal;
                            data['tutorAvailabilityType'] = typeVal;
                          }
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(email)
                              .set(data, SetOptions(merge: true));
                        } catch (e) {
                          debugPrint('Error updating profile: $e');
                        }
                      }

                      Navigator.pop(context);
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Profile updated successfully!',
                            style: GoogleFonts.manrope(),
                          ),
                          backgroundColor: AppTheme.primaryRed,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryRed,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Save Info',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _healProfileData(
    String email,
    String studentId,
    String cleanedName,
    String currentName,
    String currentProgram,
    String currentCollege,
  ) async {
    try {
      String resolvedCourse = currentProgram;
      String resolvedDept = currentCollege;
      String resolvedStudentId = studentId;

      if (resolvedStudentId.isEmpty) {
        final idMatch = RegExp(r'\.(\d+)@').firstMatch(email);
        if (idMatch != null) {
          resolvedStudentId = idMatch.group(1) ?? '';
        }
      }

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
        } else if (resolvedStudentId.isNotEmpty) {
          // 3. Direct document lookup by student ID
          doc = await FirebaseFirestore.instance.collection('student_directory').doc(resolvedStudentId).get();
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
          } else if (resolvedStudentId.isNotEmpty) {
            query = await FirebaseFirestore.instance
                .collection('student_directory')
                .where('studentId', isEqualTo: resolvedStudentId)
                .limit(1)
                .get();
            if (query.docs.isNotEmpty) {
              dirData = query.docs.first.data();
            } else {
              query = await FirebaseFirestore.instance
                  .collection('student_directory')
                  .where('id', isEqualTo: resolvedStudentId)
                  .limit(1)
                  .get();
              if (query.docs.isNotEmpty) {
                dirData = query.docs.first.data();
              }
            }
          }
        }
      }

      Map<String, dynamic> updates = {};

      if (dirData != null) {
        final fetchedCourse = dirData['course'] ?? dirData['program'];
        final fetchedDept = dirData['department'] ?? dirData['college'];
        final fetchedName = dirData['name'] ?? dirData['fullName'] ?? dirData['fullname'] ?? dirData['fullName'];

        if (fetchedCourse != null && fetchedCourse.toString().isNotEmpty && fetchedCourse != currentProgram) {
          updates['program'] = fetchedCourse;
        }
        if (fetchedDept != null && fetchedDept.toString().isNotEmpty && fetchedDept != currentCollege) {
          updates['college'] = fetchedDept;
        }
        if (fetchedName != null && fetchedName.toString().isNotEmpty && fetchedName.toString().trim() != currentName) {
          updates['name'] = fetchedName.toString().trim().toUpperCase();
        }
      }

      if (!updates.containsKey('name') && cleanedName != currentName) {
        updates['name'] = cleanedName;
      }
      if (resolvedStudentId.isNotEmpty && studentId != resolvedStudentId) {
        updates['studentId'] = resolvedStudentId;
      }

      if (updates.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(email)
            .set(updates, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Background profile auto-healing warning: $e');
    }
  }
}

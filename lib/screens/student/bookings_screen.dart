import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/app_theme.dart';
import '../../widgets/student_layout.dart';
import '../../components/custom_app_bar.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'feedback_screen.dart';
import '../../models/mock_data.dart';
import '../../components/notification_bell.dart';
import '../../services/notification_service.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  bool _isUpcomingTab = true;
  bool _hasPendingRequest = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: CustomAppBar(
        showBackButton: false,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: GestureDetector(
            onTap: () {
              final state = context
                  .findAncestorStateOfType<StudentLayoutState>();
              if (state != null) {
                state.setIndex(3);
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StudentLayout(initialIndex: 3),
                  ),
                );
              }
            },
            child: !Firebase.apps.isNotEmpty
                ? CircleAvatar(
                    radius: 18,
                    backgroundColor: AppTheme.primaryRed.withOpacity(0.15),
                    child: const Text(
                      'S',
                      style: TextStyle(
                        color: AppTheme.primaryRed,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  )
                : StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(
                          FirebaseAuth.instance.currentUser?.email ??
                              'student@umindanao.edu.ph',
                        )
                        .snapshots(),
                    builder: (context, snapshot) {
                      String firstLetter = 'S';
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final data =
                            snapshot.data!.data() as Map<String, dynamic>;
                        final name = data['name'] as String?;
                        if (name != null && name.isNotEmpty) {
                          firstLetter = name[0].toUpperCase();
                        }
                      } else {
                        final email = FirebaseAuth.instance.currentUser?.email;
                        if (email != null && email.isNotEmpty) {
                          firstLetter = email[0].toUpperCase();
                        }
                      }

                      final photoUrl =
                          FirebaseAuth.instance.currentUser?.photoURL;
                      if (photoUrl != null) {
                        return CircleAvatar(
                          radius: 18,
                          backgroundColor: AppTheme.primaryRed.withOpacity(
                            0.15,
                          ),
                          backgroundImage: NetworkImage(photoUrl),
                        );
                      }

                      return CircleAvatar(
                        radius: 18,
                        backgroundColor: AppTheme.primaryRed.withOpacity(0.15),
                        child: Text(
                          firstLetter,
                          style: const TextStyle(
                            color: AppTheme.primaryRed,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
        actions: [
          const NotificationBell(),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Section
              Text(
                'My Bookings',
                style: GoogleFonts.manrope(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1C1E),
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage your scheduled tutoring and skill-sharing sessions.',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: const Color(0xFF7A7C80),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),

              // Sliding Capsule Tab Switcher
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9ECEF).withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isUpcomingTab = true;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _isUpcomingTab
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _isUpcomingTab
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Text(
                            'Upcoming',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: _isUpcomingTab
                                  ? AppTheme.primaryRed
                                  : const Color(0xFF495057),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isUpcomingTab = false;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !_isUpcomingTab
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: !_isUpcomingTab
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Text(
                            'Completed',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: !_isUpcomingTab
                                  ? AppTheme.primaryRed
                                  : const Color(0xFF495057),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Booking List Cards
              if (_isUpcomingTab) ...[
                ...MockData.learnerBookings
                    .where((booking) => booking['isUpcoming'] == true)
                    .map((booking) {
                      String datePart = 'Upcoming';
                      String timePart = booking['time'] ?? 'TBD';
                      final timeStr = booking['time']?.toString() ?? '';
                      if (timeStr.contains('•')) {
                        final parts = timeStr.split('•');
                        datePart = parts[0].trim();
                        timePart = parts[1].trim();
                      } else if (timeStr.contains(',')) {
                        final parts = timeStr.split(',');
                        datePart = parts[0].trim();
                        timePart = parts[1].trim();
                      }

                      final isPending = booking['status'] == 'Pending';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: _buildUpcomingCard(
                          subject: booking['subject'] ?? 'Tutoring Session',
                          tutorName: booking['tutorName'] ?? 'Tutor',
                          status: booking['status'] ?? 'Confirmed',
                          statusColor: isPending
                              ? const Color(0xFF7A7C80)
                              : const Color(0xFFFBB03B),
                          date: datePart,
                          time: timePart,
                          imageUrl:
                              booking['imagePath'] ??
                              'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100',
                          actionButtons: isPending
                              ? [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          MockData.learnerBookings.removeWhere(
                                            (b) => b['id'] == booking['id'],
                                          );
                                          MockData.tutorRequests.removeWhere(
                                            (r) => r['id'] == booking['id'],
                                          );
                                        });

                                        // Trigger notification to tutor
                                        final tutorEmail = booking['tutorEmail'] ?? 'tutor_sarah@umindanao.edu.ph';
                                        NotificationService.sendNotification(
                                          tutorEmail,
                                          'Booking Cancelled ℹ️',
                                          'The booking request by Gabriel Reyes for ${booking['subject']} has been cancelled.',
                                          'booking_cancelled',
                                        );
                                        MockData.syncBookingDeleted(
                                          booking['id'].toString(),
                                        );
                                        MockData.syncTutorRequestDeleted(
                                          booking['id'].toString(),
                                        );
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Booking request successfully cancelled.',
                                              style: GoogleFonts.manrope(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            backgroundColor:
                                                AppTheme.primaryRed,
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFFF1F3F5,
                                        ),
                                        foregroundColor: const Color(
                                          0xFF495057,
                                        ),
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        'Cancel Request',
                                        style: GoogleFonts.manrope(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                ]
                              : [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Launching digital peer session conference room...',
                                              style: GoogleFonts.manrope(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryRed,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        'Join Session',
                                        style: GoogleFonts.manrope(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Request to reschedule session submitted to tutor.',
                                              style: GoogleFonts.manrope(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            backgroundColor:
                                                AppTheme.secondaryGold,
                                          ),
                                        );
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(
                                          0xFF495057,
                                        ),
                                        side: const BorderSide(
                                          color: Color(0xFFCED4DA),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        'Reschedule',
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
                    })
                    .toList(),

                if (MockData.learnerBookings
                    .where((booking) => booking['isUpcoming'] == true)
                    .isEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(
                            LucideIcons.calendarX,
                            color: Colors.grey,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No upcoming sessions booked.',
                            style: GoogleFonts.manrope(
                              color: Colors.grey,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Dotted Exploration Panel "Book New Session"
                GestureDetector(
                  onTap: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const StudentLayout(initialIndex: 0),
                      ),
                      (route) => false,
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 28,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFDF9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.primaryRed.withOpacity(0.2),
                        width: 1.5,
                        style: BorderStyle
                            .solid, // simulated dotted style visually with harmonious parameters
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryRed.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            LucideIcons.plusCircle,
                            color: AppTheme.primaryRed,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Book New Session',
                          style: GoogleFonts.manrope(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryRed,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Need help with another subject?',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: const Color(0xFF7A7C80),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const StudentLayout(initialIndex: 0),
                              ),
                              (route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryRed,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            'Explore Tutors',
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                ...MockData.learnerBookings
                    .where((booking) => booking['isUpcoming'] == false)
                    .map((booking) {
                      String datePart = 'Completed';
                      String timePart = booking['time'] ?? 'TBD';
                      final timeStr = booking['time']?.toString() ?? '';
                      if (timeStr.contains('•')) {
                        final parts = timeStr.split('•');
                        datePart = parts[0].trim();
                        timePart = parts[1].trim();
                      } else if (timeStr.contains(',')) {
                        final parts = timeStr.split(',');
                        datePart = parts[0].trim();
                        timePart = parts[1].trim();
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: _buildUpcomingCard(
                          subject: booking['subject'] ?? 'Tutoring Session',
                          tutorName: booking['tutorName'] ?? 'Tutor',
                          status: booking['status'] ?? 'Completed',
                          statusColor: Colors.green,
                          date: datePart,
                          time: timePart,
                          imageUrl:
                              booking['imagePath'] ??
                              'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100',
                          actionButtons: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const FeedbackScreen(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.secondaryGold,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  'Write Review',
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
                    })
                    .toList(),

                if (MockData.learnerBookings
                    .where((booking) => booking['isUpcoming'] == false)
                    .isEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(
                            LucideIcons.history,
                            color: Colors.grey,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No completed sessions yet.',
                            style: GoogleFonts.manrope(
                              color: Colors.grey,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingCard({
    required String subject,
    required String tutorName,
    required String status,
    required Color statusColor,
    required String date,
    required String time,
    required String imageUrl,
    required List<Widget> actionButtons,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEFF0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: imageUrl.startsWith('assets/')
                    ? AssetImage(imageUrl) as ImageProvider
                    : NetworkImage(imageUrl),
                onBackgroundImageError: (exception, stackTrace) {},
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            subject,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1A1C1E),
                            ),
                          ),
                        ),
                        // Status Pill Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status == 'Confirmed' ? '• Confirmed' : status,
                            style: GoogleFonts.manrope(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          'with $tutorName',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: const Color(0xFF7A7C80),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Verified badge label
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBB03B).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                LucideIcons.award,
                                color: Color(0xFFFBB03B),
                                size: 10,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'VERIFIED',
                                style: GoogleFonts.manrope(
                                  color: const Color(0xFFFBB03B),
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Date / Time Grid block
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFEEEFF0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          LucideIcons.calendar,
                          color: AppTheme.primaryRed,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DATE',
                            style: GoogleFonts.manrope(
                              color: const Color(0xFFADB5BD),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            date,
                            style: GoogleFonts.manrope(
                              color: const Color(0xFF495057),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFEEEFF0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          LucideIcons.clock,
                          color: AppTheme.primaryRed,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TIME',
                            style: GoogleFonts.manrope(
                              color: const Color(0xFFADB5BD),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            time,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(
                              color: const Color(0xFF495057),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Actions Row
          Row(children: actionButtons),
        ],
      ),
    );
  }
}

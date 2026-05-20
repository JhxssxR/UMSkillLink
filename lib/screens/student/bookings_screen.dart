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
import 'chat_screen.dart';
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

  void _showEndSessionConfirmation(BuildContext context, Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'End Session',
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Confirm that the tutoring session with ${booking['tutorName']} for ${booking['subject']} has finished? Once both you and the tutor confirm, the session will be marked as complete.',
          style: GoogleFonts.manrope(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: GoogleFonts.manrope(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              _processMutualEnd(context, booking);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Confirm End'),
          ),
        ],
      ),
    );
  }

  void _processMutualEnd(BuildContext context, Map<String, dynamic> booking) async {
    final String requestId = booking['id'];
    final String studentEmail = FirebaseAuth.instance.currentUser?.email ?? '';
    final String tutorEmail = booking['tutorEmail'] ?? '';

    if (studentEmail.isEmpty || tutorEmail.isEmpty) return;

    // Show loading overlay
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (dialogContext) => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryRed),
        ),
      );
    }

    bool success = false;

    try {
      // 1. Finalize the session immediately (Unpend money)
      await MockData.finalizeSession(requestId, tutorEmail).timeout(const Duration(seconds: 10));
      success = true;
    } catch (e) {
      debugPrint('Error during session finalization: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Update failed: $e'),
            backgroundColor: AppTheme.primaryRed,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      // ALWAYS close loading dialog by popping from root navigator
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }

    if (success) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session completed! Money has been released to the tutor.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // 2. Notify Tutor (In background, don't block UI)
      NotificationService.sendNotification(
        tutorEmail,
        'Session Completed! ✅',
        'Student has confirmed the end of the session for ${booking['subject']}. Funds have been released.',
        'session_completed',
      );
    }
  }

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
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('bookings')
                    .where(
                      'studentEmail',
                      isEqualTo: FirebaseAuth.instance.currentUser?.email ??
                          'student@umindanao.edu.ph',
                    )
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(color: AppTheme.primaryRed),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error loading bookings.', style: GoogleFonts.manrope(color: Colors.grey)),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];
                  final allBookings = docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    data['id'] = doc.id; // ensure we have the doc ID
                    return data;
                  }).toList();

                  final upcomingBookings = allBookings
                      .where((booking) => booking['isUpcoming'] == true)
                      .toList();
                  final completedBookings = allBookings
                      .where((booking) => booking['isUpcoming'] == false)
                      .toList();

                  if (_isUpcomingTab) {
                    return Column(
                      children: [
                        ...upcomingBookings.map((booking) {
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
                              imageUrl: booking['imagePath'] ??
                                  booking['avatar'] ??
                                  'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100',
                              actionButtons: isPending
                                  ? [
                                      Expanded(
                                        child: Column(
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: OutlinedButton.icon(
                                                    onPressed: () {
                                                      final tutorName = booking['tutorName'] ?? 'Tutor';
                                                      
                                                      // 1. Add to MockData.messages if not already present
                                                      final bool exists = MockData.messages.any((m) => m['name'] == tutorName);
                                                      if (!exists) {
                                                        MockData.messages.insert(0, {
                                                          'name': tutorName,
                                                          'message': 'Starting a new conversation...',
                                                          'time': 'Just now',
                                                          'isUnread': false,
                                                        });
                                                      }

                                                      // 2. Switch to Messages Tab
                                                      final layoutState = context.findAncestorStateOfType<StudentLayoutState>();
                                                      if (layoutState != null) {
                                                        layoutState.setIndex(2);
                                                      }
                                                    },
                                                    icon: const Icon(LucideIcons.messageCircle, size: 16),
                                                    label: const Text('Message'),
                                                    style: OutlinedButton.styleFrom(
                                                      foregroundColor: AppTheme.primaryRed,
                                                      side: const BorderSide(color: AppTheme.primaryRed),
                                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: OutlinedButton.icon(
                                                    onPressed: () {
                                                      // Trigger notification to tutor
                                                      final tutorEmail = booking['tutorEmail'] ?? 'tutor_sarah@umindanao.edu.ph';
                                                      NotificationService.sendNotification(
                                                        tutorEmail,
                                                        'Reschedule Request 🗓️',
                                                        'Student has requested to reschedule the session for ${booking['subject']}.',
                                                        'booking_reschedule',
                                                      );

                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            'Reschedule request sent to ${booking['tutorName']}.',
                                                            style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
                                                          ),
                                                          backgroundColor: AppTheme.secondaryGold,
                                                        ),
                                                      );
                                                    },
                                                    icon: const Icon(LucideIcons.calendar, size: 16),
                                                    label: const Text('Reschedule'),
                                                    style: OutlinedButton.styleFrom(
                                                      foregroundColor: const Color(0xFF495057),
                                                      side: const BorderSide(color: Color(0xFFCED4DA)),
                                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  final bookingId = booking['id'];
                                                  if (bookingId != null) {
                                                    FirebaseFirestore.instance
                                                        .collection('bookings')
                                                        .doc(bookingId)
                                                        .delete();
                                                  }
                                                  
                                                  // Trigger notification to tutor
                                                  final tutorEmail = booking['tutorEmail'] ?? 'tutor_sarah@umindanao.edu.ph';
                                                  NotificationService.sendNotification(
                                                    tutorEmail,
                                                    'Booking Cancelled ℹ️',
                                                    'The booking request for ${booking['subject']} has been cancelled.',
                                                    'booking_cancelled',
                                                  );
                                                  
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'Booking request successfully cancelled.',
                                                        style: GoogleFonts.manrope(
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      backgroundColor: AppTheme.primaryRed,
                                                    ),
                                                  );
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFFF1F3F5),
                                                  foregroundColor: const Color(0xFF495057),
                                                  elevation: 0,
                                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
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
                                          ],
                                        ),
                                      ),
                                    ]
                                  : [
                                      Expanded(
                                        child: StreamBuilder<DocumentSnapshot>(
                                          stream: FirebaseFirestore.instance.collection('bookings').doc(booking['id']).snapshots(),
                                          builder: (context, snap) {
                                            bool endRequested = false;
                                            bool isAutoCompleted = false;
                                            if (snap.hasData && snap.data!.exists) {
                                              final d = snap.data!.data() as Map<String, dynamic>;
                                              endRequested = d['endRequestedAt'] != null;
                                              
                                              if (endRequested && d['status'] == 'Confirmed') {
                                                final Timestamp ts = d['endRequestedAt'];
                                                final diff = DateTime.now().difference(ts.toDate());
                                                if (diff.inMinutes >= 5) {
                                                  isAutoCompleted = true;
                                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                                    MockData.finalizeSession(booking['id'], booking['tutorEmail']);
                                                  });
                                                }
                                              }
                                            }

                                            return Column(
                                              children: [
                                                // Primary Action Row (End Session / Confirm)
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: ElevatedButton(
                                                        onPressed: !endRequested || isAutoCompleted ? null : () {
                                                          _showEndSessionConfirmation(context, booking);
                                                        },
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: !endRequested ? Colors.grey.shade300 : AppTheme.primaryRed,
                                                          foregroundColor: Colors.white,
                                                          elevation: 0,
                                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(8),
                                                          ),
                                                        ),
                                                        child: Text(
                                                          isAutoCompleted ? 'Completed' : (endRequested ? 'Confirm End & Pay' : 'End Session'),
                                                          style: GoogleFonts.manrope(
                                                            fontWeight: FontWeight.w800,
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    if (endRequested && !isAutoCompleted) ...[
                                                      const SizedBox(width: 8),
                                                      SizedBox(
                                                        width: 52,
                                                        height: 52,
                                                        child: OutlinedButton(
                                                          onPressed: () {
                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              const SnackBar(content: Text('Complain submitted to Admin. Money will remain pending.')),
                                                            );
                                                          },
                                                          style: OutlinedButton.styleFrom(
                                                            foregroundColor: Colors.red,
                                                            side: const BorderSide(color: Colors.red, width: 1.5),
                                                            padding: EdgeInsets.zero,
                                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                          ),
                                                          child: const Icon(LucideIcons.alertOctagon, size: 20),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                                const SizedBox(height: 12),
                                                // Secondary Actions Row (Message / Reschedule)
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: OutlinedButton.icon(
                                                        onPressed: () {
                                                          final tutorName = booking['tutorName'] ?? 'Tutor';
                                                          final bool exists = MockData.messages.any((m) => m['name'] == tutorName);
                                                          if (!exists) {
                                                            MockData.messages.insert(0, {
                                                              'name': tutorName,
                                                              'message': 'Starting a new conversation...',
                                                              'time': 'Just now',
                                                              'isUnread': false,
                                                            });
                                                          }
                                                          final layoutState = context.findAncestorStateOfType<StudentLayoutState>();
                                                          if (layoutState != null) {
                                                            layoutState.setIndex(2);
                                                          }
                                                        },
                                                        icon: const Icon(LucideIcons.messageCircle, size: 16),
                                                        label: const Text('Message'),
                                                        style: OutlinedButton.styleFrom(
                                                          foregroundColor: AppTheme.primaryRed,
                                                          side: const BorderSide(color: AppTheme.primaryRed),
                                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: OutlinedButton.icon(
                                                        onPressed: () {
                                                          final tutorEmail = booking['tutorEmail'] ?? 'tutor_sarah@umindanao.edu.ph';
                                                          NotificationService.sendNotification(
                                                            tutorEmail,
                                                            'Reschedule Request 🗓️',
                                                            'Student has requested to reschedule the session for ${booking['subject']}.',
                                                            'booking_reschedule',
                                                          );

                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                'Request to reschedule session submitted to tutor.',
                                                                style: GoogleFonts.manrope(
                                                                  fontWeight: FontWeight.bold,
                                                                ),
                                                              ),
                                                              backgroundColor: AppTheme.secondaryGold,
                                                            ),
                                                          );
                                                        },
                                                        icon: const Icon(LucideIcons.calendar, size: 16),
                                                        label: const Text('Reschedule'),
                                                        style: OutlinedButton.styleFrom(
                                                          foregroundColor: const Color(0xFF495057),
                                                          side: const BorderSide(color: Color(0xFFCED4DA)),
                                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(8),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            );
                                          }
                                        ),
                                      ),
                                    ],
                            ),
                          );
                        }),
                        if (upcomingBookings.isEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Center(
                              child: Column(
                                children: [
                                  const Icon(LucideIcons.calendarX, color: Colors.grey, size: 48),
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
                                builder: (context) => const StudentLayout(initialIndex: 0),
                              ),
                              (route) => false,
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFDF9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppTheme.primaryRed.withOpacity(0.2),
                                width: 1.5,
                                style: BorderStyle.solid,
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
                                  child: const Icon(LucideIcons.plusCircle, color: AppTheme.primaryRed, size: 24),
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
                                        builder: (context) => const StudentLayout(initialIndex: 0),
                                      ),
                                      (route) => false,
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryRed,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
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
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        ...completedBookings.map((booking) {
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
                              imageUrl: booking['imagePath'] ??
                                  booking['avatar'] ??
                                  'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100',
                              actionButtons: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => FeedbackScreen(booking: booking),
                                        ),
                                      );
                                    },
                                    icon: const Icon(LucideIcons.star, size: 16),
                                    label: const Text('Feedback'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.secondaryGold,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => FeedbackScreen(
                                            booking: booking,
                                            initialComplaint: true,
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(LucideIcons.alertTriangle, size: 16),
                                    label: const Text('Complain'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        if (completedBookings.isEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Center(
                              child: Column(
                                children: [
                                  const Icon(LucideIcons.history, color: Colors.grey, size: 48),
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
                    );
                  }
                },
              ),
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

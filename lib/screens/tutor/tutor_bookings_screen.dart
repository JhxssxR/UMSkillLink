import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/app_theme.dart';
import '../../models/mock_data.dart';
import '../../components/custom_app_bar.dart';
import '../../services/notification_service.dart';

class TutorBookingsScreen extends StatefulWidget {
  const TutorBookingsScreen({super.key});

  @override
  State<TutorBookingsScreen> createState() => _TutorBookingsScreenState();
}

class _TutorBookingsScreenState extends State<TutorBookingsScreen> {
  int _activeTab = 0; // 0 for Incoming, 1 for Confirmed
  List<Map<String, dynamic>> _requests = [];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  void _loadRequests() {
    setState(() {
      _requests = MockData.tutorRequests;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: CustomAppBar(
        subtitle: 'TUTOR PORTAL',
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.helpCircle, color: Color(0xFF7A7C80)),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(
                    'Need Help?',
                    style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
                  ),
                  content: Text(
                    'Here you can manage incoming session bookings from students. Accepting a request will add it to your confirmed schedule, and declining will notify the student to choose another slot.',
                    style: GoogleFonts.manrope(),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Got it',
                        style: GoogleFonts.manrope(
                          color: AppTheme.primaryRed,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Text(
                'Session Requests',
                style: GoogleFonts.manrope(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.neutralColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Manage your upcoming tutoring appointments and new inquiries.',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: const Color(0xFF7A7C80),
                ),
              ),
              const SizedBox(height: 24),

              // Tab headers with line indicators
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _activeTab = 0;
                        });
                      },
                      child: Column(
                        children: [
                          Text(
                            'Incoming (${_requests.where((r) => r['status'] == 'Pending').length})',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: _activeTab == 0
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: _activeTab == 0
                                  ? AppTheme.primaryRed
                                  : const Color(0xFF7A7C80),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Container(
                            height: 2,
                            color: _activeTab == 0
                                ? AppTheme.primaryRed
                                : Colors.transparent,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _activeTab = 1;
                        });
                      },
                      child: Column(
                        children: [
                          Text(
                            'Confirmed (${_requests.where((r) => r['status'] == 'Confirmed').length})',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: _activeTab == 1
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: _activeTab == 1
                                  ? AppTheme.primaryRed
                                  : const Color(0xFF7A7C80),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Container(
                            height: 2,
                            color: _activeTab == 1
                                ? AppTheme.primaryRed
                                : Colors.transparent,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Active Tab List contents
              _activeTab == 0 ? _buildIncomingList() : _buildConfirmedList(),
              const SizedBox(height: 32),

              // Upcoming Confirmed Heading Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Upcoming Confirmed',
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.neutralColor,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _activeTab = 1;
                      });
                    },
                    child: Row(
                      children: [
                        Text(
                          'View Schedule',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryRed,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          LucideIcons.arrowRight,
                          size: 14,
                          color: AppTheme.primaryRed,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Premium purple next session card
              _buildUpcomingCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIncomingList() {
    final pending = _requests.where((r) => r['status'] == 'Pending').toList();
    if (pending.isEmpty) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.inbox, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              'No new incoming requests',
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: pending.length,
      itemBuilder: (context, index) {
        final request = pending[index];
        return _buildRequestCard(request);
      },
    );
  }

  Widget _buildConfirmedList() {
    final confirmed = _requests
        .where((r) => r['status'] == 'Confirmed')
        .toList();
    if (confirmed.isEmpty) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        child: Text(
          'No confirmed sessions yet.',
          style: GoogleFonts.manrope(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: confirmed.length,
      itemBuilder: (context, index) {
        final request = confirmed[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: NetworkImage(
                  request['avatar'] ??
                      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
                ),
                onBackgroundImageError: (exception, stackTrace) {},
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request['learnerName'] ?? '',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.neutralColor,
                      ),
                    ),
                    Text(
                      request['subject'] ?? '',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        color: const Color(0xFF7A7C80),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.calendar,
                          size: 14,
                          color: AppTheme.primaryRed,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${request['time']} • ${request['timeDetail']}',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryRed,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Confirmed',
                  style: GoogleFonts.manrope(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
          // Header Row: Avatar, Name, Degree, Badges
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: NetworkImage(request['avatar'] ?? ''),
                onBackgroundImageError: (exception, stackTrace) {},
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          request['learnerName'] ?? '',
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: AppTheme.neutralColor,
                          ),
                        ),
                        if (request['verified'] == true) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.verified,
                            color: Color(0xFF3B82F6),
                            size: 16,
                          ),
                        ],
                        if (request['topLearner'] == true) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFB800).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'TOP LEARNER',
                              style: GoogleFonts.manrope(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFFD97706),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      request['degree'] ?? '',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF7A7C80),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          const SizedBox(height: 16),

          // SUBJECT row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SUBJECT',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF7A7C80),
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  request['subject'] ?? '',
                  style: GoogleFonts.manrope(
                    color: AppTheme.primaryRed,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          // Location (if present)
          if (request['location'] != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Location',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF7A7C80),
                  ),
                ),
                Row(
                  children: [
                    const Icon(
                      LucideIcons.mapPin,
                      color: AppTheme.primaryRed,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      request['location'] ?? '',
                      style: GoogleFonts.manrope(
                        color: AppTheme.primaryRed,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],

          // Note (if present)
          if (request['note'] != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Note',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF7A7C80),
                  ),
                ),
                Text(
                  '"${request['note']}"',
                  style: GoogleFonts.manrope(
                    color: const Color(0xFF1A1C1E),
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),

          // Date & Time row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                request['location'] != null ? 'Scheduled' : 'Date & Time',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF7A7C80),
                ),
              ),
              Text(
                '${request['time']}, ${request['timeDetail']}',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: AppTheme.neutralColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Decline / Accept Buttons Row
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _declineRequest(request),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryRed,
                    side: const BorderSide(
                      color: AppTheme.primaryRed,
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Decline',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _acceptRequest(request),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Accept',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingCard() {
    // Get the first confirmed request dynamically
    final confirmed = _requests
        .where((r) => r['status'] == 'Confirmed')
        .toList();
    final String sessionSubject = confirmed.isNotEmpty
        ? (confirmed.first['subject'] ?? 'Tutoring Session')
        : 'No Upcoming Session';
    final String sessionWith = confirmed.isNotEmpty
        ? 'with ${confirmed.first['learnerName']} • ${confirmed.first['timeDetail'] ?? 'TBD'}'
        : 'Accept a request to see your next session';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4A47A3), Color(0xFF6B66C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A47A3).withOpacity(0.25),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  LucideIcons.calendarCheck,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NEXT SESSION',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withOpacity(0.7),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sessionSubject,
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sessionWith,
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: confirmed.isNotEmpty
                  ? () {
                      _launchVirtualRoom();
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF4A47A3),
                disabledBackgroundColor: Colors.white.withOpacity(0.3),
                disabledForegroundColor: Colors.white.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'Launch Virtual Room',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _declineRequest(Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Decline Request',
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to decline ${request['learnerName']}\'s session request for ${request['subject']}?',
          style: GoogleFonts.manrope(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.manrope(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                request['status'] = 'Declined';
              });
              for (var booking in MockData.learnerBookings) {
                if (booking['id'] == request['id']) {
                  setState(() {
                    booking['status'] = 'Declined';
                    booking['isUpcoming'] = false;
                  });
                  break;
                }
              }
              MockData.syncTutorRequestUpdated(
                request['id'].toString(),
                'Declined',
              );
              MockData.syncBookingStatusUpdated(
                request['id'].toString(),
                'Declined',
                isUpcoming: false,
              );
              
              // Trigger notification to student
              final studentEmail = request['studentEmail'] ?? 'gabriel.reyes@umindanao.edu.ph';
              NotificationService.sendNotification(
                studentEmail,
                'Booking Update ❌',
                'Your booking request for ${request['subject']} on ${request['time']} has been declined by the tutor.',
                'booking_declined',
              );

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${request['learnerName']}\'s request declined.',
                  ),
                  backgroundColor: AppTheme.primaryRed,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Decline'),
          ),
        ],
      ),
    );
  }

  void _acceptRequest(Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Accept Request',
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Do you want to accept ${request['learnerName']}\'s tutoring request for ${request['subject']}?',
          style: GoogleFonts.manrope(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.manrope(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                request['status'] = 'Confirmed';
              });
              for (var booking in MockData.learnerBookings) {
                if (booking['id'] == request['id']) {
                  setState(() {
                    booking['status'] = 'Confirmed';
                    booking['isUpcoming'] = true;
                  });
                  break;
                }
              }
              MockData.syncTutorRequestUpdated(
                request['id'].toString(),
                'Confirmed',
              );
              MockData.syncBookingStatusUpdated(
                request['id'].toString(),
                'Confirmed',
                isUpcoming: true,
              );

              // Trigger notification to student
              final studentEmail = request['studentEmail'] ?? 'gabriel.reyes@umindanao.edu.ph';
              NotificationService.sendNotification(
                studentEmail,
                'Booking Confirmed! 🎉',
                'Your booking request for ${request['subject']} on ${request['time']} has been confirmed by the tutor!',
                'booking_confirmed',
              );

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Session request accepted! Added to schedule.'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  void _launchVirtualRoom() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        Timer(const Duration(seconds: 3), () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Connected to Peer Virtual Conference successfully!',
              ),
              backgroundColor: Colors.green,
            ),
          );
        });

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Color(0xFF4A47A3)),
                const SizedBox(height: 20),
                Text(
                  'Launching Virtual Room...',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Preparing your secure peer study portal...',
                  style: GoogleFonts.manrope(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

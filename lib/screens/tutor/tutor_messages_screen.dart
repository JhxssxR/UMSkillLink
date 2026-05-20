import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/app_theme.dart';
import '../../components/tutor_app_bar.dart';
import '../student/chat_screen.dart';

class TutorMessagesScreen extends StatelessWidget {
  const TutorMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String tutorEmail = FirebaseAuth.instance.currentUser?.email?.toLowerCase() ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: const TutorAppBar(
        showBackButton: false,
        centerTitle: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tutor_requests')
            .where('tutorEmail', isEqualTo: tutorEmail)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed));
          }

          final allRequests = snapshot.data?.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                data['id'] = doc.id;
                return data;
              }).toList() ?? [];

          final confirmedBookings = allRequests.where((r) => 
            r['status'] == 'Confirmed' || r['status'] == 'Pending'
          ).toList();

          // Group by student email to avoid duplicate chat entries
          final Map<String, Map<String, dynamic>> uniqueLearners = {};
          for (var booking in confirmedBookings) {
            final email = booking['studentEmail'] ?? '';
            if (email.isNotEmpty && !uniqueLearners.containsKey(email)) {
              uniqueLearners[email] = booking;
            }
          }

          final learnersList = uniqueLearners.values.toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Text(
                  'Tutor Messages',
                  style: GoogleFonts.manrope(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A1C1E),
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEEEFF0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      icon: const Icon(LucideIcons.search, size: 18, color: Color(0xFF7A7C80)),
                      hintText: 'Search learners...',
                      hintStyle: GoogleFonts.manrope(
                        color: const Color(0xFFADB5BD),
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Active Learners (Horizontal)
              if (learnersList.isNotEmpty)
                SizedBox(
                  height: 90,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: learnersList.length,
                    itemBuilder: (context, index) {
                      final learner = learnersList[index];
                      final name = learner['learnerName'] ?? 'Learner';
                      
                      return Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: GestureDetector(
                          onTap: () => _openChat(context, learner),
                          child: Column(
                            children: [
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: AppTheme.primaryRed.withOpacity(0.1),
                                    child: Text(
                                      name[0],
                                      style: GoogleFonts.manrope(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryRed,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: 2,
                                    bottom: 2,
                                    child: Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2ECC71),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                name.split(' ')[0],
                                textAlign: TextAlign.center,
                                style: GoogleFonts.manrope(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF495057),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

              const Divider(height: 32, color: Color(0xFFF1F3F5), thickness: 1),

              // Conversations List
              Expanded(
                child: learnersList.isEmpty 
                  ? _buildEmptyState()
                  : ListView.builder(
                      itemCount: learnersList.length,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemBuilder: (context, index) {
                        return _buildMessageItem(context, learnersList[index]);
                      },
                    ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openChat(BuildContext context, Map<String, dynamic> learner) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          name: learner['learnerName'] ?? 'Learner',
          peerEmail: learner['studentEmail'] ?? '',
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.messageSquare, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No conversations yet',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Confirm a booking request to start chatting.',
            style: GoogleFonts.manrope(color: Colors.grey.shade400, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(BuildContext context, Map<String, dynamic> learner) {
    final String name = learner['learnerName'] ?? 'Learner';
    final String subject = learner['subject'] ?? 'Tutoring';

    return GestureDetector(
      onTap: () => _openChat(context, learner),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEEEFF0)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppTheme.primaryRed.withOpacity(0.1),
              child: Text(
                name[0],
                style: GoogleFonts.manrope(
                  color: AppTheme.primaryRed,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1A1C1E),
                        ),
                      ),
                      Text(
                        'Just now',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFADB5BD),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Confirmed session: $subject',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
      ),
    );
  }
}

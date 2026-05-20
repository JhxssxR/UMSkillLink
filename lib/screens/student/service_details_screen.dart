import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import '../../core/app_theme.dart';
import '../../components/custom_app_bar.dart';
import 'booking_screen.dart';

class ServiceDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> tutor;

  const ServiceDetailsScreen({super.key, required this.tutor});

  // Helper to build image widget from URL or Base64
  Widget _buildServiceImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return const Icon(LucideIcons.image, color: AppTheme.primaryRed, size: 64);
    }
    
    if (imageUrl.startsWith('data:image')) {
      try {
        final String base64Data = imageUrl.split(',').last;
        return Image.memory(
          base64Decode(base64Data),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(LucideIcons.imageOff),
        );
      } catch (e) {
        return const Icon(LucideIcons.imageOff);
      }
    }
    
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => const Icon(
        LucideIcons.image,
        color: AppTheme.primaryRed,
        size: 64,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String email = tutor['tutorEmail'] ?? tutor['email'] ?? 'tutor@umindanao.edu.ph';
    final String? currentUserEmail = FirebaseAuth.instance.currentUser?.email;
    final bool isOwnService = currentUserEmail != null && currentUserEmail == email;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(email).snapshots(),
      builder: (context, snapshot) {
        String tutorAbout = tutor['about'] ?? 'Third-year Engineering student with a passion for deconstructing complex structural concepts. I believe peer tutoring is the most effective way to master challenging STEM subjects while building university camaraderie.';
        List<String> tutorExpertise = ['Calculus II', 'Physics', 'Eng. Mech.'];
        String tutorAvailabilityDays = 'Mon - Fri';
        String tutorAvailabilityHours = 'After 5:00 PM';
        String tutorAvailabilityType = 'ON-CAMPUS ONLY';
        String subscriptionTier = 'Free';
        double tutorRating = (tutor['rating'] ?? 5.0).toDouble();
        int tutorReviews = (tutor['reviews'] ?? 0).toInt();

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          tutorAbout = data['tutorAbout'] ?? data['about'] ?? tutorAbout;
          if (data['tutorExpertise'] != null) {
            tutorExpertise = List<String>.from(data['tutorExpertise']);
          } else if (data['expertise'] != null) {
            tutorExpertise = List<String>.from(data['expertise']);
          }
          tutorAvailabilityDays = data['tutorAvailabilityDays'] ?? data['availabilityDays'] ?? tutorAvailabilityDays;
          tutorAvailabilityHours = data['tutorAvailabilityHours'] ?? data['availabilityHours'] ?? tutorAvailabilityHours;
          tutorAvailabilityType = data['tutorAvailabilityType'] ?? data['availabilityType'] ?? tutorAvailabilityType;
          subscriptionTier = data['subscriptionTier'] ?? 'Free';
          tutorRating = (data['rating'] ?? tutorRating).toDouble();
          tutorReviews = (data['reviews'] ?? tutorReviews).toInt();
        }

        // Clean name display fallback
        final String tutorName = tutor['name'] ?? 'Peer Tutor';

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: CustomAppBar(
            title: 'Service Details',
            centerTitle: false,
            actions: [
              IconButton(
                icon: const Icon(LucideIcons.heart, color: Colors.black),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(LucideIcons.share2, color: Colors.black),
                onPressed: () {},
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  color: AppTheme.primaryRed.withOpacity(0.05),
                  child: _buildServiceImage(
                    tutor['imageUrl'] ?? tutor['image'] ?? tutor['avatarUrl'] ?? tutor['avatar']
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tutor['subject'] ?? 'Tutoring Service',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1C1E),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 12,
                            backgroundColor: AppTheme.primaryRed,
                            child: Icon(
                              LucideIcons.user,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            tutorName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          if (subscriptionTier == 'Tutor Pro') ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFBB03B).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: const Color(0xFFFBB03B), width: 0.5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.stars, color: Color(0xFFFBB03B), size: 10),
                                  SizedBox(width: 2),
                                  Text(
                                    'FEATURED',
                                    style: TextStyle(
                                      color: Color(0xFFFBB03B),
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const Spacer(),
                          if (tutorReviews > 0) ...[
                            const Icon(
                              Icons.star,
                              color: Color(0xFFFBB03B),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$tutorRating ($tutorReviews reviews)',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ] else
                            const Text(
                              'New',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryRed,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      const Text(
                        'About Service',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        tutorAbout.replaceAll('Peer Tutor', tutorName),
                        style: TextStyle(color: Colors.grey.shade700, height: 1.6),
                      ),
                      const SizedBox(height: 32),

                      if (tutorExpertise.isNotEmpty) ...[
                        const Text(
                          'Tutor Expertise',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: tutorExpertise.map((subject) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryRed.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.primaryRed.withOpacity(0.15)),
                            ),
                            child: Text(
                              subject,
                              style: const TextStyle(
                                color: AppTheme.primaryRed,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )).toList(),
                        ),
                        const SizedBox(height: 32),
                      ],

                      const Text(
                        'Availability',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(LucideIcons.calendar, '$tutorAvailabilityDays, $tutorAvailabilityHours'),
                      _buildInfoRow(LucideIcons.mapPin, tutorAvailabilityType.toUpperCase()),
                      _buildInfoRow(
                        LucideIcons.languages,
                        'English, Tagalog, Bisaya',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Price',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    Text(
                      (tutor['price'] == '0' || tutor['price'] == 0)
                          ? 'FREE'
                          : '₱${tutor['price']} / hr',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: (tutor['price'] == '0' || tutor['price'] == 0)
                            ? Colors.green
                            : AppTheme.primaryRed,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isOwnService ? null : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookingScreen(tutor: {
                            ...tutor,
                            'name': tutorName,
                            'about': tutorAbout,
                            'availabilityDays': tutorAvailabilityDays,
                            'availabilityHours': tutorAvailabilityHours,
                            'availabilityType': tutorAvailabilityType,
                          }),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isOwnService ? Colors.grey : AppTheme.primaryRed,
                      disabledBackgroundColor: Colors.grey.shade300,
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.grey,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isOwnService ? 'Your Own Service' : 'Book Session',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryRed),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(fontSize: 14, color: Color(0xFF1A1C1E)),
          ),
        ],
      ),
    );
  }
}

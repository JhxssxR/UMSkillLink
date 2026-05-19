import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/app_theme.dart';
import '../../components/custom_app_bar.dart';
import 'booking_screen.dart';

class ServiceDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> tutor;

  const ServiceDetailsScreen({super.key, required this.tutor});

  @override
  Widget build(BuildContext context) {
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
            // Header Image Placeholder
            Container(
              height: 200,
              width: double.infinity,
              color: AppTheme.primaryRed.withOpacity(0.05),
              child: Image.network(
                tutor['avatarUrl'] ?? tutor['avatar'] ?? 'https://res.cloudinary.com/demo/image/upload/v1312461204/sample.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  LucideIcons.image,
                  color: AppTheme.primaryRed,
                  size: 64,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tutor['subject'],
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
                        tutor['name'],
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      if ((tutor['reviews'] ?? 0) > 0) ...[
                        const Icon(
                          Icons.star,
                          color: Color(0xFFFBB03B),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${tutor['rating']} (${tutor['reviews']} reviews)',
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
                    tutor['about'].toString().replaceAll('Peer Tutor', tutor['name'] ?? 'The tutor'),
                    style: TextStyle(color: Colors.grey.shade700, height: 1.6),
                  ),
                  const SizedBox(height: 32),

                  const Text(
                    'Availability',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(LucideIcons.calendar, 'Mon-Fri, 5PM - 8PM'),
                  _buildInfoRow(LucideIcons.mapPin, 'UM Main Library / Online'),
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
              color: Colors.black.withValues(alpha: 0.05),
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
                  '₱${tutor['price']} / hr',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryRed,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookingScreen(tutor: tutor),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRed,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Book Session',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
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

  Widget _buildReviewCard(String name, String comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              const Icon(Icons.star, color: Color(0xFFFBB03B), size: 12),
              const Icon(Icons.star, color: Color(0xFFFBB03B), size: 12),
              const Icon(Icons.star, color: Color(0xFFFBB03B), size: 12),
              const Icon(Icons.star, color: Color(0xFFFBB03B), size: 12),
              const Icon(Icons.star, color: Color(0xFFFBB03B), size: 12),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

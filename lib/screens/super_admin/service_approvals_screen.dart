import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_theme.dart';
import '../../services/notification_service.dart';

class ServiceApprovalsScreen extends StatefulWidget {
  final bool isSuperAdmin;
  const ServiceApprovalsScreen({super.key, this.isSuperAdmin = false});

  @override
  State<ServiceApprovalsScreen> createState() => _ServiceApprovalsScreenState();
}

class _ServiceApprovalsScreenState extends State<ServiceApprovalsScreen> {
  void _approveApplication(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
  ) async {
    try {
      // 1. Update status of the tutor application to approved
      await FirebaseFirestore.instance
          .collection('tutor_applications')
          .doc(docId)
          .update({'status': 'approved'});

      // 2. Insert as a live active Tutor Listing in marketplace tutors collection
      await FirebaseFirestore.instance.collection('tutors').doc(docId).set({
        'id': docId,
        'name': data['name'] ?? 'Verified Peer Tutor',
        'college': data['college'] ?? 'College of Engineering',
        'skills': data['skills'] ?? ['Calculus', 'Physics'],
        'bio':
            data['bio'] ??
            'Comprehensive academic peer guidance and skill tutoring sessions.',
        'hourlyRate': data['hourlyRate'] ?? 200.0,
        'rating': 5.0,
        'reviewsCount': 0,
        'isFavorite': false,
        'status': 'active',
        'verifiedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 3. Log audit event
      await FirebaseFirestore.instance.collection('audit_logs').add({
        'action': 'Approved Peer Tutor Application for ${data['name']}',
        'timestamp': FieldValue.serverTimestamp(),
        'adminEmail': 'j.antukan.549054@umindanao.edu.ph',
      });

      // 4. Update user role to tutor using set with merge: true
      if (data['email'] != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(data['email'])
            .set({'role': 'tutor'}, SetOptions(merge: true))
            .catchError((e) {
              debugPrint('Failed to update user role: $e');
            });

        // 5. Notify the user of approval using central NotificationService
        await NotificationService.sendNotification(
          data['email'],
          'Tutor Application Approved! 🎉',
          'Congratulations! Your peer tutor application has been approved. You can now switch to tutor mode in your profile settings.',
          'application_approved',
        ).catchError((e) {
          debugPrint('Failed to add approval notification: $e');
        });
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${data['name']} has been approved and listed on the marketplace!',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error approving tutor listing: $e'),
          backgroundColor: AppTheme.primaryRed,
        ),
      );
    }
  }

  void _rejectApplication(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
  ) async {
    try {
      // Update status of the tutor application to rejected
      await FirebaseFirestore.instance
          .collection('tutor_applications')
          .doc(docId)
          .update({'status': 'rejected'});

      // Log audit event
      await FirebaseFirestore.instance.collection('audit_logs').add({
        'action': 'Rejected Peer Tutor Application for ${data['name']}',
        'timestamp': FieldValue.serverTimestamp(),
        'adminEmail': 'j.antukan.549054@umindanao.edu.ph',
      });

      // Notify the user of rejection using central NotificationService
      if (data['email'] != null) {
        await NotificationService.sendNotification(
          data['email'],
          'Tutor Application Update 📝',
          'Thank you for applying. Unfortunately, your peer tutor application has been rejected during administrative credentials review.',
          'application_rejected',
        ).catchError((e) {
          debugPrint('Failed to add rejection notification: $e');
        });
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Application for ${data['name']} has been rejected.'),
          backgroundColor: Colors.orange.shade800,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error rejecting application: $e'),
          backgroundColor: AppTheme.primaryRed,
        ),
      );
    }
  }

  void _showImageDialog(BuildContext context, String title, String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No image attached.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(title, style: const TextStyle(color: Colors.white)),
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: InteractiveViewer(
                child: imageUrl.startsWith('data:image')
                    ? Image.memory(
                        base64Decode(imageUrl.split(',').last),
                        fit: BoxFit.contain,
                      )
                    : Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
                                child: Icon(Icons.broken_image,
                                    size: 100, color: Colors.white)),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailsDialog(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
  ) {
    final skills = List<String>.from(data['skills'] ?? []);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Tutor Application Details',
            style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInfoField('Full Name', data['name'] ?? 'N/A'),
                _buildInfoField('University ID', data['universityId'] ?? 'N/A'),
                _buildInfoField('College/Department', data['college'] ?? 'N/A'),
                _buildInfoField(
                  'Hourly Rate',
                  '₱${data['hourlyRate'] ?? 0.0}/hr',
                ),
                const SizedBox(height: 12),
                Text(
                  'Expertise & Skills:',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: skills.map((skill) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryRed.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        skill,
                        style: GoogleFonts.manrope(
                          color: AppTheme.primaryRed,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                _buildInfoField(
                  'teaching Experience / Bio',
                  data['bio'] ?? 'No bio provided.',
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => _showImageDialog(
                    context,
                    'University ID Card',
                    data['idImageUrl'],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.fileCheck,
                          size: 16,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'University ID Card Verified',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: AppTheme.primaryRed,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        const Icon(
                          LucideIcons.eye,
                          size: 14,
                          color: AppTheme.primaryRed,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _showImageDialog(
                    context,
                    'Proof of Expertise',
                    data['expertiseImageUrl'],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.fileCheck,
                          size: 16,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Academic proof of expertise uploaded',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: AppTheme.primaryRed,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        const Icon(
                          LucideIcons.eye,
                          size: 14,
                          color: AppTheme.primaryRed,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: GoogleFonts.manrope(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.primaryRed),
                foregroundColor: AppTheme.primaryRed,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                _rejectApplication(context, docId, data);
              },
              child: Text(
                'Reject Application',
                style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                _approveApplication(context, docId, data);
              },
              child: Text(
                'Approve Peer Tutor',
                style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Dynamic Service Approvals',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('tutor_applications')
                  .where('status', isEqualTo: 'pending')
                  .snapshots(),
              builder: (context, snapshot) {
                final count = snapshot.data?.docs.length ?? 0;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Pending ($count)',
                    style: GoogleFonts.manrope(
                      color: AppTheme.secondaryGold,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Live stream builder from tutor_applications Firestore collection
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('tutor_applications')
              .orderBy('submittedAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(48.0),
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryRed),
                ),
              );
            }

            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(32.0),
                child: Center(
                  child: Text(
                    'Error loading applications: ${snapshot.error}',
                    style: GoogleFonts.manrope(
                      color: AppTheme.primaryRed,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(48.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        LucideIcons.fileCheck,
                        size: 48,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'All applications have been processed!',
                        style: GoogleFonts.manrope(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'When prospective tutors submit peer applications from the Tutor Screen, they will populate here instantly.',
                        style: GoogleFonts.manrope(
                          color: Colors.grey.shade400,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;
                final docId = doc.id;

                final name = data['name'] ?? 'prospective Peer Tutor';
                final college = data['college'] ?? 'College of Engineering';
                final bio =
                    data['bio'] ??
                    'Comprehensive subject and skill training provider...';
                final hourlyRate = data['hourlyRate'] ?? 0.0;
                final status = data['status'] ?? 'pending';
                final skills = List<String>.from(data['skills'] ?? []);

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: status == 'pending' ? 3 : 1,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            status == 'approved'
                                ? LucideIcons.checkCircle2
                                : (status == 'rejected'
                                      ? LucideIcons.xCircle
                                      : LucideIcons.fileText),
                            color: status == 'approved'
                                ? Colors.green
                                : (status == 'rejected'
                                      ? AppTheme.primaryRed
                                      : Colors.blueGrey),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.tertiaryIndigo
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      college,
                                      style: GoogleFonts.manrope(
                                        color: AppTheme.tertiaryIndigo,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  _buildStatusBadge(status),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                name,
                                style: GoogleFonts.manrope(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Subjects: ${skills.join(", ")} • Rate: ₱$hourlyRate/hr',
                                style: GoogleFonts.manrope(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                bio,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.manrope(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        if (status == 'pending') ...[
                          Column(
                            children: [
                              ElevatedButton(
                                onPressed: () =>
                                    _showDetailsDialog(context, docId, data),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryRed,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(130, 40),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  'Review Application',
                                  style: GoogleFonts.manrope(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton(
                                onPressed: () =>
                                    _approveApplication(context, docId, data),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(130, 40),
                                  side: const BorderSide(color: Colors.green),
                                  foregroundColor: Colors.green,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  'Quick Approve',
                                  style: GoogleFonts.manrope(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () =>
                                    _rejectApplication(context, docId, data),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.primaryRed,
                                ),
                                child: Text(
                                  'Reject',
                                  style: GoogleFonts.manrope(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 24,
                            ),
                            child: Text(
                              status == 'approved' ? 'APPROVED' : 'REJECTED',
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w800,
                                color: status == 'approved'
                                    ? Colors.green
                                    : AppTheme.primaryRed,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'approved':
        color = Colors.green;
        break;
      case 'pending':
        color = AppTheme.secondaryGold;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.manrope(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

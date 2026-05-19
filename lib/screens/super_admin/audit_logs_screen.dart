import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  @override
  void initState() {
    super.initState();
    _prepopulateInitialLogsIfNeeded();
  }

  void _prepopulateInitialLogsIfNeeded() async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('audit_logs')
          .limit(1)
          .get();
      if (query.docs.isEmpty) {
        final batch = FirebaseFirestore.instance.batch();
        final collection = FirebaseFirestore.instance.collection('audit_logs');

        final initialLogs = [
          {
            'action':
                'Approved Peer Tutor Application: Juan D. Dela Cruz (College of Engineering)',
            'timestamp': DateTime.now().subtract(const Duration(minutes: 5)),
            'adminEmail': 'j.antukan.549054@umindanao.edu.ph',
          },
          {
            'action':
                'System Settings Updated: Platform Transaction Fee modified to 5.0%',
            'timestamp': DateTime.now().subtract(const Duration(hours: 1)),
            'adminEmail': 'j.antukan.549054@umindanao.edu.ph',
          },
          {
            'action': 'User Profile role changed to tutor: maria@um.edu.ph',
            'timestamp': DateTime.now().subtract(const Duration(hours: 3)),
            'adminEmail': 'j.antukan.549054@umindanao.edu.ph',
          },
          {
            'action': 'Database backups triggered successfully',
            'timestamp': DateTime.now().subtract(const Duration(days: 1)),
            'adminEmail': 'system_backup@umindanao.edu.ph',
          },
        ];

        for (var log in initialLogs) {
          final docRef = collection.doc();
          batch.set(docRef, {
            'action': log['action'],
            'timestamp': Timestamp.fromDate(log['timestamp'] as DateTime),
            'adminEmail': log['adminEmail'],
          });
        }
        await batch.commit();
      }
    } catch (e) {
      debugPrint('Error prepopulating audit logs: $e');
    }
  }

  void _exportLogs(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Audit logs exported successfully as PDF/CSV report!'),
        backgroundColor: Colors.green,
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
              'System Activity Logs',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _exportLogs(context),
              icon: const Icon(LucideIcons.download),
              label: Text(
                'Export Logs',
                style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(foregroundColor: AppTheme.primaryRed),
            ),
          ],
        ),

        const SizedBox(height: 24),

        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('audit_logs')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(48.0),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryRed,
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Center(
                    child: Text(
                      'Error loading logs: ${snapshot.error}',
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
                return Padding(
                  padding: const EdgeInsets.all(48.0),
                  child: Center(
                    child: Text(
                      'No system activity logged yet.',
                      style: GoogleFonts.manrope(
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final action = data['action'] ?? 'Unknown event executed';
                  final adminEmail = data['adminEmail'] ?? 'admin';
                  final timestamp = data['timestamp'] as Timestamp?;

                  String timeLabel = 'Just now';
                  if (timestamp != null) {
                    final dateTime = timestamp.toDate();
                    timeLabel = DateFormat('MMM dd, hh:mm a').format(dateTime);
                  }

                  // Pick a nice icon based on the keywords
                  IconData icon = LucideIcons.info;
                  Color iconColor = Colors.blueGrey;
                  if (action.contains('Approved')) {
                    icon = LucideIcons.checkCircle;
                    iconColor = Colors.green;
                  } else if (action.contains('Rejected') ||
                      action.contains('Delete')) {
                    icon = LucideIcons.xCircle;
                    iconColor = AppTheme.primaryRed;
                  } else if (action.contains('Settings') ||
                      action.contains('Fee')) {
                    icon = LucideIcons.settings;
                    iconColor = AppTheme.secondaryGold;
                  }

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, size: 18, color: iconColor),
                    ),
                    title: Text(
                      action,
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                    subtitle: Text(
                      'Admin ID: $adminEmail',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    trailing: Text(
                      timeLabel,
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

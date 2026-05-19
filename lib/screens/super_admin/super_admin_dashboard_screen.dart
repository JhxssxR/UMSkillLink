import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';

class SuperAdminDashboardScreen extends StatelessWidget {
  final Function(int)? onTabChange;

  const SuperAdminDashboardScreen({super.key, this.onTabChange});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Real-Time Stats Row
        Row(
          children: [
            // Stat Card 1: Total Users
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .snapshots(),
              builder: (context, snapshot) {
                final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                return _StatCard(
                  title: 'Total Active Users',
                  value: count.toString(),
                  trend: 'Dynamic Sync',
                  icon: LucideIcons.users,
                  color: AppTheme.tertiaryIndigo,
                );
              },
            ),
            const SizedBox(width: 24),

            // Stat Card 2: Pending Approvals
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('tutor_applications')
                  .where('status', isEqualTo: 'pending')
                  .snapshots(),
              builder: (context, snapshot) {
                final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                return _StatCard(
                  title: 'Pending Applications',
                  value: count.toString(),
                  trend: count > 0 ? 'Action Required' : 'All Clear',
                  icon: LucideIcons.clock,
                  color: AppTheme.secondaryGold,
                );
              },
            ),
            const SizedBox(width: 24),

            // Stat Card 3: Listed Tutors
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('tutors')
                  .snapshots(),
              builder: (context, snapshot) {
                final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                return _StatCard(
                  title: 'Active Peer Tutors',
                  value: count.toString(),
                  trend: 'Listed Live',
                  icon: LucideIcons.briefcase,
                  color: Colors.green,
                );
              },
            ),
            const SizedBox(width: 24),

            // Stat Card 4: Platform Revenue / Bookings completed
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .snapshots(),
              builder: (context, snapshot) {
                final totalBookings = snapshot.hasData
                    ? snapshot.data!.docs.length
                    : 0;
                double totalRevenue = 0.0;
                if (snapshot.hasData) {
                  for (var doc in snapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final price =
                        double.tryParse(
                          (data['price'] ?? '0.0').toString().replaceAll(
                            '₱',
                            '',
                          ),
                        ) ??
                        0.0;
                    // Suppose 5% platform fee
                    totalRevenue += price * 0.05;
                  }
                }

                return _StatCard(
                  title: 'Commission Earnings (5%)',
                  value: '₱${totalRevenue.toStringAsFixed(2)}',
                  trend: '$totalBookings Bookings',
                  icon: LucideIcons.banknote,
                  color: AppTheme.primaryRed,
                );
              },
            ),
          ],
        ),

        const SizedBox(height: 40),

        // Live Actionable Tables / Feeds Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dynamic Pending Tutors list
            Expanded(
              flex: 2,
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Pending Peer Approvals',
                            style: GoogleFonts.manrope(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () => onTabChange?.call(
                              2,
                            ), // index 2 is Service Approvals Screen
                            child: Text(
                              'View All',
                              style: GoogleFonts.manrope(
                                color: AppTheme.primaryRed,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Divider(),

                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('tutor_applications')
                            .where('status', isEqualTo: 'pending')
                            .limit(3)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 32.0),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppTheme.primaryRed,
                                ),
                              ),
                            );
                          }

                          final docs = snapshot.data?.docs ?? [];

                          if (docs.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              alignment: Alignment.center,
                              child: Text(
                                'No pending reviews right now. Nice job!',
                                style: GoogleFonts.manrope(
                                  color: Colors.grey.shade500,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }

                          return Column(
                            children: docs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final name = data['name'] ?? 'Tutor Applicant';
                              final college =
                                  data['college'] ?? 'University Department';
                              final skills = List<String>.from(
                                data['skills'] ?? [],
                              );
                              final time = data['submittedAt'] as Timestamp?;

                              String timeLabel = 'Just now';
                              if (time != null) {
                                timeLabel = DateFormat(
                                  'MMM dd',
                                ).format(time.toDate());
                              }

                              return _ApprovalItem(
                                title: name,
                                provider: college,
                                category: skills.isNotEmpty
                                    ? skills.first
                                    : 'General Skills',
                                date: timeLabel,
                                onReview: () => onTabChange?.call(2),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 24),

            // Live Activity Feed from Firestore Audit Logs
            Expanded(
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Audit Trails',
                            style: GoogleFonts.manrope(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              LucideIcons.arrowRight,
                              size: 18,
                              color: AppTheme.primaryRed,
                            ),
                            onPressed: () =>
                                onTabChange?.call(5), // index 5 is Audit Logs
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('audit_logs')
                            .orderBy('timestamp', descending: true)
                            .limit(4)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppTheme.primaryRed,
                                ),
                              ),
                            );
                          }

                          final docs = snapshot.data?.docs ?? [];

                          if (docs.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              alignment: Alignment.center,
                              child: Text(
                                'No system activities logged yet.',
                                style: GoogleFonts.manrope(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          }

                          return Column(
                            children: docs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final action =
                                  data['action'] ?? 'Action performed';
                              final timeStamp = data['timestamp'] as Timestamp?;

                              String timeLabel = 'Now';
                              if (timeStamp != null) {
                                final diff = DateTime.now().difference(
                                  timeStamp.toDate(),
                                );
                                if (diff.inMinutes < 60) {
                                  timeLabel = '${diff.inMinutes}m ago';
                                } else if (diff.inHours < 24) {
                                  timeLabel = '${diff.inHours}h ago';
                                } else {
                                  timeLabel = '${diff.inDays}d ago';
                                }
                              }

                              IconData icon = LucideIcons.info;
                              Color iconColor = Colors.blue;
                              if (action.contains('Approved') ||
                                  action.contains('tutor')) {
                                icon = LucideIcons.checkCircle2;
                                iconColor = Colors.green;
                              } else if (action.contains('Settings')) {
                                icon = LucideIcons.settings;
                                iconColor = AppTheme.secondaryGold;
                              } else if (action.contains('Deleted') ||
                                  action.contains('Suspended')) {
                                icon = LucideIcons.alertTriangle;
                                iconColor = AppTheme.primaryRed;
                              }

                              return _ActivityItem(
                                icon: icon,
                                label: action,
                                time: timeLabel,
                                color: iconColor,
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String trend;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.trend,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 16),
              Text(
                value,
                style: GoogleFonts.manrope(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: GoogleFonts.manrope(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                trend,
                style: GoogleFonts.manrope(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ApprovalItem extends StatelessWidget {
  final String title;
  final String provider;
  final String category;
  final String date;
  final VoidCallback onReview;

  const _ApprovalItem({
    required this.title,
    required this.provider,
    required this.category,
    required this.date,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '$provider • $category',
                  style: GoogleFonts.manrope(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            date,
            style: GoogleFonts.manrope(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 24),
          ElevatedButton(
            onPressed: onReview,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: Text(
              'Review',
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String time;
  final Color color;

  const _ActivityItem({
    required this.icon,
    required this.label,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';

class AdminDashboardScreen extends StatelessWidget {
  final Function(int)? onTabChange;

  const AdminDashboardScreen({super.key, this.onTabChange});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Real-Time Stats Row
        Row(
          children: [
            // Stat Card 1: Pending Tutors
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('tutor_applications')
                  .where('status', isEqualTo: 'pending')
                  .snapshots(),
              builder: (context, snapshot) {
                final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                return _StatCard(
                  title: 'Pending Tutors',
                  value: count.toString(),
                  trend: 'Requires Verification',
                  icon: LucideIcons.userPlus,
                  color: AppTheme.secondaryGold,
                );
              },
            ),
            const SizedBox(width: 24),

            // Stat Card 2: Overall Revenue
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('transactions')
                  .snapshots(),
              builder: (context, snapshot) {
                double totalRevenue = 0.0;
                if (snapshot.hasData) {
                  for (var doc in snapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final amount = (data['amount'] ?? 0).toDouble();
                    totalRevenue += amount;
                  }
                }
                return _StatCard(
                  title: 'Overall Revenue',
                  value: '₱${totalRevenue.toStringAsFixed(2)}',
                  trend: 'Real-time',
                  icon: LucideIcons.banknote,
                  color: Colors.green,
                );
              },
            ),
            const SizedBox(width: 24),

            // Stat Card 3: New Users
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .snapshots(),
              builder: (context, snapshot) {
                final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                return _StatCard(
                  title: 'New Users',
                  value: count.toString(),
                  trend: 'Platform Growth',
                  icon: LucideIcons.users,
                  color: AppTheme.tertiaryIndigo,
                );
              },
            ),
            const SizedBox(width: 24),

            // Stat Card 4: Pro Subscriptions
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('subscriptions')
                  .where('status', isEqualTo: 'Active')
                  .snapshots(),
              builder: (context, snapshot) {
                final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                return _StatCard(
                  title: 'Pro Subscriptions',
                  value: count.toString(),
                  trend: 'Active',
                  icon: LucideIcons.star,
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
            // Critical Review Queue
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
                            'Critical Review Queue',
                            style: GoogleFonts.manrope(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () => onTabChange?.call(1),
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
                      Text(
                        'Pending Tutor Applications (Requires Verification)',
                        style: GoogleFonts.manrope(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
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

                              return _ReviewItem(
                                title: name,
                                subtitle: '$college',
                                subject: skills.isNotEmpty
                                    ? 'Subject: ${skills.join(", ")}'
                                    : 'Subject: General',
                                date: timeLabel,
                                onReview: () => onTabChange?.call(1),
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

            // Account Moderation & Monitoring
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
                      Text(
                        'Account Moderation',
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('audit_logs').limit(2).snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return Text('No recent activities.', style: GoogleFonts.manrope(fontSize: 12, color: Colors.grey));
                          }
                          return Column(
                            children: snapshot.data!.docs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return _ModerationItem(
                                icon: LucideIcons.shieldAlert,
                                label: data['action'] ?? 'System Action',
                                subtext: 'Admin Activity',
                                color: AppTheme.primaryRed,
                              );
                            }).toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      Text(
                        'Transaction Monitoring',
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('transactions').limit(2).snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return Text('No recent transactions.', style: GoogleFonts.manrope(fontSize: 12, color: Colors.grey));
                          }
                          return Column(
                            children: snapshot.data!.docs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return _TransactionItem(
                                from: data['user'] ?? 'User',
                                to: data['type'] ?? 'Transaction',
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

class _ReviewItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String subject;
  final String date;
  final VoidCallback onReview;

  const _ReviewItem({
    required this.title,
    required this.subtitle,
    required this.subject,
    required this.date,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  subtitle,
                  style: GoogleFonts.manrope(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subject,
                  style: GoogleFonts.manrope(
                    color: Colors.grey.shade800,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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
          const SizedBox(width: 16),
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

class _ModerationItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtext;
  final Color color;

  const _ModerationItem({
    required this.icon,
    required this.label,
    required this.subtext,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
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
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtext,
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    color: Colors.grey.shade500,
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

class _TransactionItem extends StatelessWidget {
  final String from;
  final String to;

  const _TransactionItem({required this.from, required this.to});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          const Icon(
            LucideIcons.arrowRightLeft,
            size: 14,
            color: AppTheme.tertiaryIndigo,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.manrope(fontSize: 13, color: Colors.black87),
                children: [
                  TextSpan(
                    text: from,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const TextSpan(text: ' - '),
                  TextSpan(
                    text: to,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

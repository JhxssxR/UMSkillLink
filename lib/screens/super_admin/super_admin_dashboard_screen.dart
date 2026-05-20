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
                  .collection('settings')
                  .doc('commission_rules')
                  .collection('rules')
                  .snapshots(),
              builder: (context, rulesSnapshot) {
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .where('role', isEqualTo: 'tutor')
                      .snapshots(),
                  builder: (context, tutorsSnapshot) {
                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('bookings')
                          .snapshots(),
                      builder: (context, snapshot) {
                        final totalBookings = snapshot.hasData ? snapshot.data!.docs.length : 0;
                        double totalRevenue = 0.0;
                        double feeRateDisplay = 5.0;

                        if (snapshot.hasData && tutorsSnapshot.hasData && rulesSnapshot.hasData) {
                          final tutorSubStatus = {
                            for (var doc in tutorsSnapshot.data!.docs)
                              (doc.data() as Map<String, dynamic>)['email']: (doc.data() as Map<String, dynamic>)['isSubscribed'] ?? false
                          };

                          final rules = {
                            for (var doc in rulesSnapshot.data!.docs)
                              doc.id: (doc.data() as Map<String, dynamic>)['rate'] ?? 0.0
                          };

                          final baseRate = rules['base_fee']?.toDouble() ?? 5.0;
                          final premiumRate = rules['premium_fee']?.toDouble() ?? 3.0;
                          feeRateDisplay = baseRate;

                          for (var doc in snapshot.data!.docs) {
                            final data = doc.data() as Map<String, dynamic>;
                            final price = double.tryParse((data['price'] ?? '0.0').toString().replaceAll('₱', '')) ?? 0.0;
                            final tutorEmail = data['tutorEmail'];
                            
                            final isSubscribed = tutorSubStatus[tutorEmail] ?? false;
                            final appliedRate = isSubscribed ? premiumRate : baseRate;
                            
                            totalRevenue += price * (appliedRate / 100);
                          }
                        }

                        return _StatCard(
                          title: 'Commission Earnings (Mixed Rate)',
                          value: '₱${totalRevenue.toStringAsFixed(2)}',
                          trend: '$totalBookings Bookings',
                          icon: LucideIcons.banknote,
                          color: AppTheme.primaryRed,
                        );
                      },
                    );
                  },
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
                            onPressed: () => onTabChange?.call(2), 
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
                      const SizedBox(height: 16),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('tutor_applications')
                            .where('status', isEqualTo: 'pending')
                            .limit(5)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final apps = snapshot.data?.docs ?? [];
                          if (apps.isEmpty) {
                            return _buildEmptyState('No pending applications');
                          }
                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: apps.length,
                            separatorBuilder: (context, index) => const Divider(),
                            itemBuilder: (context, index) {
                              final app = apps[index].data() as Map<String, dynamic>;
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppTheme.primaryRed.withOpacity(0.1),
                                  child: Text(app['name']?[0] ?? 'U', style: const TextStyle(color: AppTheme.primaryRed)),
                                ),
                                title: Text(app['name'] ?? 'Unknown User', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 14)),
                                subtitle: Text(app['college'] ?? 'UM College', style: GoogleFonts.manrope(fontSize: 12)),
                                trailing: const Icon(LucideIcons.chevronRight, size: 16),
                                contentPadding: EdgeInsets.zero,
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24),
            // Platform Status
            Expanded(
              child: Column(
                children: [
                  _buildQuickStatusCard(
                    'System Health',
                    'Optimal',
                    LucideIcons.activity,
                    Colors.green,
                  ),
                  const SizedBox(height: 16),
                  _buildQuickStatusCard(
                    'Database Sync',
                    'Live',
                    LucideIcons.database,
                    AppTheme.tertiaryIndigo,
                  ),
                  const SizedBox(height: 16),
                  _buildQuickStatusCard(
                    'Security',
                    'SSL Active',
                    LucideIcons.shieldCheck,
                    Colors.blue,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(LucideIcons.inbox, color: Colors.grey.shade300, size: 32),
            const SizedBox(height: 8),
            Text(message, style: GoogleFonts.manrope(color: Colors.grey.shade400, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatusCard(String title, String status, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.manrope(color: Colors.grey.shade500, fontSize: 11)),
                Text(status, style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ],
        ),
      ),
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
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    trend,
                    style: GoogleFonts.manrope(
                      color: AppTheme.primaryRed,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              value,
              style: GoogleFonts.manrope(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1C1E),
              ),
            ),
            Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: const Color(0xFF7A7C80),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

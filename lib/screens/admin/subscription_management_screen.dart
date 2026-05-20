import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';

class SubscriptionManagementScreen extends StatefulWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  State<SubscriptionManagementScreen> createState() =>
      _SubscriptionManagementScreenState();
}

class _SubscriptionManagementScreenState
    extends State<SubscriptionManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('subscriptions').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryRed),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        
        // Calculate Summary Values
        int activeCount = 0;
        int pastDueCount = 0;
        double monthlyRecurring = 0;

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] ?? '';
          final amountField = data['amount'] ?? '0';
          double amount = 0;
          if (amountField is num) {
            amount = amountField.toDouble();
          } else {
            amount = double.tryParse(amountField.toString().replaceAll('\$', '').replaceAll(',', '')) ?? 0.0;
          }
          final cycle = data['billingCycle'] ?? 'Monthly';

          if (status == 'Active') {
            activeCount++;
            if (cycle == 'Monthly') {
              monthlyRecurring += amount;
            } else if (cycle == 'Annual') {
              monthlyRecurring += (amount / 12);
            }
          } else if (status == 'Past Due') {
            pastDueCount++;
          }
        }

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Subscription Management',
                    style: GoogleFonts.manrope(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(LucideIcons.download),
                    label: const Text('Export Report'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Summary Cards
              Row(
                children: [
                  _SummaryCard(
                    title: 'Total Active Subs',
                    value: activeCount.toString(),
                    icon: LucideIcons.checkCircle,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 24),
                  _SummaryCard(
                    title: 'Monthly Recurring',
                    value: '₱${monthlyRecurring.toStringAsFixed(2)}',
                    icon: LucideIcons.banknote,
                    color: AppTheme.secondaryGold,
                  ),
                  const SizedBox(width: 24),
                  _SummaryCard(
                    title: 'Past Due',
                    value: pastDueCount.toString(),
                    icon: LucideIcons.alertCircle,
                    color: AppTheme.primaryRed,
                  ),
                ],
              ),

              const SizedBox(height: 32),
              Text(
                'All Subscriptions',
                style: GoogleFonts.manrope(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              if (docs.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      children: [
                        const Icon(LucideIcons.shieldAlert, size: 48, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'No subscription records found.',
                          style: GoogleFonts.manrope(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: docs.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final status = data['status'] ?? 'Unknown';
                      
                      Color statusColor = Colors.grey;
                      if (status == 'Active') statusColor = Colors.green;
                      if (status == 'Past Due') statusColor = AppTheme.primaryRed;

                      String nextBilling = '-';
                      if (data['nextBilling'] != null) {
                        if (data['nextBilling'] is Timestamp) {
                          nextBilling = DateFormat('yyyy-MM-dd').format((data['nextBilling'] as Timestamp).toDate());
                        } else {
                          nextBilling = data['nextBilling'].toString();
                        }
                      }

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        title: Text(
                          data['userName'] ?? data['tutorName'] ?? 'Unknown User',
                          style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            '${data['plan'] ?? 'N/A'} • ${data['billingCycle'] ?? 'N/A'} • ₱${data['amount'] ?? '0.00'}',
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                status,
                                style: GoogleFonts.manrope(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Next: $nextBilling',
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {},
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.manrope(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: GoogleFonts.manrope(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

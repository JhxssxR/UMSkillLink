import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/app_theme.dart';

class SubscriptionManagementScreen extends StatefulWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  State<SubscriptionManagementScreen> createState() =>
      _SubscriptionManagementScreenState();
}

class _SubscriptionManagementScreenState
    extends State<SubscriptionManagementScreen> {
  // Mock data for subscriptions
  final List<Map<String, dynamic>> _subscriptions = [
    {
      'id': 'SUB-001',
      'tutorName': 'Dr. Alice Smith',
      'plan': 'Pro Tutor',
      'status': 'Active',
      'billingCycle': 'Monthly',
      'amount': '\$49.99',
      'nextBilling': '2026-06-15',
    },
    {
      'id': 'SUB-002',
      'tutorName': 'Prof. Bob Johnson',
      'plan': 'Premium',
      'status': 'Past Due',
      'billingCycle': 'Annual',
      'amount': '\$499.00',
      'nextBilling': '2026-05-10',
    },
    {
      'id': 'SUB-003',
      'tutorName': 'Dr. Charlie Davis',
      'plan': 'Pro Tutor',
      'status': 'Active',
      'billingCycle': 'Monthly',
      'amount': '\$49.99',
      'nextBilling': '2026-06-12',
    },
    {
      'id': 'SUB-004',
      'tutorName': 'Diana Prince',
      'plan': 'Basic',
      'status': 'Canceled',
      'billingCycle': 'Monthly',
      'amount': '\$19.99',
      'nextBilling': '-',
    },
  ];

  @override
  Widget build(BuildContext context) {
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
                value: '2',
                icon: LucideIcons.checkCircle,
                color: Colors.green,
              ),
              const SizedBox(width: 24),
              _SummaryCard(
                title: 'Monthly Recurring',
                value: '\$99.98',
                icon: LucideIcons.dollarSign,
                color: AppTheme.secondaryGold,
              ),
              const SizedBox(width: 24),
              _SummaryCard(
                title: 'Past Due',
                value: '1',
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
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _subscriptions.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final sub = _subscriptions[index];
                Color statusColor = Colors.grey;
                if (sub['status'] == 'Active') statusColor = Colors.green;
                if (sub['status'] == 'Past Due')
                  statusColor = AppTheme.primaryRed;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  title: Text(
                    sub['tutorName'],
                    style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      '${sub['plan']} • ${sub['billingCycle']} • ${sub['amount']}',
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
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          sub['status'],
                          style: GoogleFonts.manrope(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Next: ${sub['nextBilling']}',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    // Show details
                  },
                );
              },
            ),
          ),
        ],
      ),
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
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
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
            ],
          ),
        ),
      ),
    );
  }
}

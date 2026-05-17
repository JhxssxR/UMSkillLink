import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/app_theme.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats Row
        Row(
          children: [
            _StatCard(
              title: 'Total Users',
              value: '1,248',
              trend: '+12%',
              icon: LucideIcons.users,
              color: AppTheme.tertiaryIndigo,
            ),
            const SizedBox(width: 24),
            _StatCard(
              title: 'Pending Approvals',
              value: '24',
              trend: 'High Priority',
              icon: LucideIcons.clock,
              color: AppTheme.secondaryGold,
            ),
            const SizedBox(width: 24),
            _StatCard(
              title: 'Active Listings',
              value: '312',
              trend: '+5%',
              icon: LucideIcons.briefcase,
              color: Colors.green,
            ),
            const SizedBox(width: 24),
            _StatCard(
              title: 'Monthly Revenue',
              value: '₱142,550',
              trend: '+18%',
              icon: LucideIcons.banknote,
              color: AppTheme.primaryRed,
            ),
          ],
        ),
        
        const SizedBox(height: 40),
        
        // Tables/Charts Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recent Approvals Table
            Expanded(
              flex: 2,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Pending Approvals',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text('View All', style: TextStyle(color: AppTheme.primaryRed)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      _ApprovalItem(
                        title: 'Advanced Calculus II Tutoring',
                        provider: 'Maria Santos',
                        category: 'Mathematics',
                        date: 'Oct 26, 2023',
                      ),
                      _ApprovalItem(
                        title: 'Logo Design & Branding',
                        provider: 'John Doe',
                        category: 'Graphic Design',
                        date: 'Oct 25, 2023',
                      ),
                      _ApprovalItem(
                        title: 'Python for Beginners',
                        provider: 'Alex Lee',
                        category: 'Technical Skills',
                        date: 'Oct 24, 2023',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 24),
            
            // Recent Activity Feed
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recent Activity',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),
                      _ActivityItem(
                        icon: LucideIcons.userPlus,
                        label: 'New Provider Registered',
                        time: '2 mins ago',
                        color: Colors.blue,
                      ),
                      _ActivityItem(
                        icon: LucideIcons.checkCircle,
                        label: 'Service Approved by Admin',
                        time: '15 mins ago',
                        color: Colors.green,
                      ),
                      _ActivityItem(
                        icon: LucideIcons.alertTriangle,
                        label: 'User Account Flagged',
                        time: '1 hour ago',
                        color: Colors.orange,
                      ),
                      _ActivityItem(
                        icon: LucideIcons.creditCard,
                        label: 'Withdrawal Request: ₱5,000',
                        time: '3 hours ago',
                        color: AppTheme.primaryRed,
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
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 16),
              Text(
                value,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 12),
              Text(
                trend,
                style: TextStyle(
                  color: trend.startsWith('+') ? Colors.green : AppTheme.primaryRed,
                  fontSize: 12,
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

  const _ApprovalItem({
    required this.title,
    required this.provider,
    required this.category,
    required this.date,
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
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('$provider • $category', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          ),
          Text(date, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          const SizedBox(width: 24),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('Review', style: TextStyle(fontSize: 12)),
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
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(time, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

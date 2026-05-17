import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AuditLogsScreen extends StatelessWidget {
  const AuditLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'System Activity Logs',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(LucideIcons.download),
              label: const Text('Export Logs'),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 8,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              return _buildLogItem(index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLogItem(int index) {
    final actions = [
      'Approved Service: Calculus II Tutoring',
      'Suspended User: Sarah Chen (Fraudulent Activity)',
      'Modified Platform Fee: 5.0% -> 6.0%',
      'New Admin User Added: robert_fox',
      'Rejected Service: Crypto Trading Advice',
      'System Configuration Updated',
      'Bulk Approval: 12 Student Verification Requests',
      'Database Backup Completed'
    ];
    
    final icons = [
      LucideIcons.checkCircle,
      LucideIcons.userX,
      LucideIcons.settings,
      LucideIcons.userPlus,
      LucideIcons.xCircle,
      LucideIcons.edit3,
      LucideIcons.layers,
      LucideIcons.database
    ];

    final times = [
      '2 mins ago',
      '15 mins ago',
      '1 hour ago',
      '3 hours ago',
      'Yesterday, 4:30 PM',
      'Yesterday, 2:15 PM',
      'Oct 24, 10:00 AM',
      'Oct 23, 11:59 PM'
    ];

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icons[index % icons.length], size: 18, color: Colors.blueGrey),
      ),
      title: Text(actions[index % actions.length], style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
      subtitle: Text('Admin ID: AD-9824 • IP: 192.168.1.${10+index}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      trailing: Text(times[index % times.length], style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
    );
  }
}

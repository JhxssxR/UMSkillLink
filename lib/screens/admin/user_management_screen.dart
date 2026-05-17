import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/app_theme.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Actions
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search users by name, email or ID...',
                  prefixIcon: const Icon(LucideIcons.search, size: 20),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            _FilterChip(label: 'All Users', isActive: true),
            const SizedBox(width: 8),
            _FilterChip(label: 'Students', isActive: false),
            const SizedBox(width: 8),
            _FilterChip(label: 'Providers', isActive: false),
          ],
        ),
        
        const SizedBox(height: 32),
        
        // Users Table
        Card(
          child: SizedBox(
            width: double.infinity,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
              columns: const [
                DataColumn(label: Text('USER', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('ROLE', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('STATUS', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('JOINED DATE', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('ACTIONS', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: [
                _buildUserRow('Maria Santos', 'maria@um.edu.ph', 'Student', 'Active', 'Oct 12, 2023'),
                _buildUserRow('John Doe', 'john.doe@gmail.com', 'Provider', 'Pending', 'Oct 15, 2023'),
                _buildUserRow('Alex Lee', 'alex.lee@um.edu.ph', 'Student', 'Active', 'Oct 20, 2023'),
                _buildUserRow('Sarah Chen', 'sarah.c@provider.com', 'Provider', 'Suspended', 'Sep 28, 2023'),
                _buildUserRow('Robert Fox', 'robert@um.edu.ph', 'Student', 'Active', 'Oct 05, 2023'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  DataRow _buildUserRow(String name, String email, String role, String status, String date) {
    return DataRow(
      cells: [
        DataCell(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.primaryRed.withValues(alpha: 0.1),
                  child: Text(name[0], style: const TextStyle(color: AppTheme.primaryRed, fontSize: 12)),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(email, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ),
        DataCell(Text(role)),
        DataCell(_buildStatusBadge(status)),
        DataCell(Text(date)),
        DataCell(
          Row(
            children: [
              IconButton(icon: const Icon(LucideIcons.edit2, size: 18), onPressed: () {}),
              IconButton(icon: const Icon(LucideIcons.trash2, size: 18, color: AppTheme.primaryRed), onPressed: () {}),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'Active': color = Colors.green; break;
      case 'Pending': color = AppTheme.secondaryGold; break;
      case 'Suspended': color = Colors.red; break;
      default: color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;

  const _FilterChip({required this.label, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? AppTheme.primaryRed : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isActive ? AppTheme.primaryRed : Colors.grey.shade300),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? Colors.white : Colors.black87,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

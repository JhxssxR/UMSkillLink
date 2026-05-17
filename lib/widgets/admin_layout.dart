import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/app_theme.dart';

class AdminLayout extends StatelessWidget {
  final Widget child;
  final int selectedIndex;
  final Function(int) onIndexChanged;

  const AdminLayout({
    super.key,
    required this.child,
    required this.selectedIndex,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Column(
              children: [
                // Logo Section
                Container(
                  padding: const EdgeInsets.all(32),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/um_logo.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(LucideIcons.graduationCap, color: AppTheme.primaryRed);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'UM SkillLink',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Navigation Items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _SidebarItem(
                        icon: LucideIcons.layoutDashboard,
                        label: 'Overview',
                        isActive: selectedIndex == 0,
                        onTap: () => onIndexChanged(0),
                      ),
                      _SidebarItem(
                        icon: LucideIcons.users,
                        label: 'User Management',
                        isActive: selectedIndex == 1,
                        onTap: () => onIndexChanged(1),
                      ),
                      _SidebarItem(
                        icon: LucideIcons.clipboardCheck,
                        label: 'Service Approvals',
                        isActive: selectedIndex == 2,
                        onTap: () => onIndexChanged(2),
                      ),
                      _SidebarItem(
                        icon: LucideIcons.barChart3,
                        label: 'Reports & Analytics',
                        isActive: selectedIndex == 3,
                        onTap: () => onIndexChanged(3),
                      ),
                      _SidebarItem(
                        icon: LucideIcons.settings,
                        label: 'System Settings',
                        isActive: selectedIndex == 4,
                        onTap: () => onIndexChanged(4),
                      ),
                      _SidebarItem(
                        icon: LucideIcons.history,
                        label: 'Audit Logs',
                        isActive: selectedIndex == 5,
                        onTap: () => onIndexChanged(5),
                      ),
                    ],
                  ),
                ),

                // Admin Profile
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey.shade100)),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: AppTheme.secondaryGold,
                        child: Text('SA', style: TextStyle(color: Colors.white)),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Super Admin',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'admin@um.edu.ph',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.logOut, size: 20),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: Column(
              children: [
                // Header
                Container(
                  height: 80,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: Color(0xFFEEEFF0))),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _getPageTitle(selectedIndex),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(LucideIcons.bell),
                        onPressed: () {},
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(LucideIcons.plus, size: 18),
                        label: const Text('Add User'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content Area
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getPageTitle(int index) {
    switch (index) {
      case 0: return 'Super Admin Dashboard';
      case 1: return 'User Management';
      case 2: return 'Service Approval Queue';
      case 3: return 'Reports & Analytics';
      case 4: return 'System Settings';
      case 5: return 'Audit Logs';
      default: return 'Admin Panel';
    }
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          icon,
          color: isActive ? AppTheme.primaryRed : Colors.grey,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isActive ? AppTheme.primaryRed : Colors.black87,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        tileColor: isActive ? AppTheme.primaryRed.withValues(alpha: 0.05) : null,
      ),
    );
  }
}

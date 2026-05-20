import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminLayout extends StatelessWidget {
  final Widget child;
  final int selectedIndex;
  final Function(int) onIndexChanged;
  final VoidCallback? onLogout;
  final VoidCallback? onAddUserPressed;
  final VoidCallback? onNotificationPressed;
  final bool isSuperAdmin;

  const AdminLayout({
    super.key,
    required this.child,
    required this.selectedIndex,
    required this.onIndexChanged,
    this.onLogout,
    this.onAddUserPressed,
    this.onNotificationPressed,
    this.isSuperAdmin = true,
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
              border: Border(right: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              children: [
                // Logo Section
                Container(
                  padding: const EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 32,
                    bottom: 24,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryRed,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            'assets/images/um_logo.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                LucideIcons.bookOpen,
                                color: Colors.white,
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'UM SkillLink',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryRed,
                              ),
                            ),
                            Text(
                              isSuperAdmin
                                  ? 'Super Admin Portal'
                                  : 'Admin Dashboard',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Admin Profile Section
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: AppTheme.primaryRed,
                        radius: 18,
                        child: Icon(
                          LucideIcons.user,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isSuperAdmin
                                  ? 'System Admin'
                                  : 'University Admin',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              isSuperAdmin
                                  ? 'Full Access'
                                  : 'Institutional Control',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Navigation Items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      if (!isSuperAdmin) ...[
                        _SidebarItem(
                          icon: LucideIcons.layoutDashboard,
                          label: 'Overview',
                          isActive: selectedIndex == 0,
                          onTap: () => onIndexChanged(0),
                        ),
                        _SidebarItem(
                          icon: LucideIcons.shieldCheck,
                          label: 'Verify Tutors',
                          isActive: selectedIndex == 1,
                          onTap: () => onIndexChanged(1),
                        ),
                        _SidebarItem(
                          icon: LucideIcons.percent,
                          label: 'Commission Rates',
                          isActive: selectedIndex == 2,
                          onTap: () => onIndexChanged(2),
                        ),
                        _SidebarItem(
                          icon: LucideIcons.monitor,
                          label: 'Subscriptions',
                          isActive: selectedIndex == 3,
                          onTap: () => onIndexChanged(3),
                        ),
                        _SidebarItem(
                          icon: LucideIcons.userCog,
                          label: 'Manage Accounts',
                          isActive: selectedIndex == 4,
                          onTap: () => onIndexChanged(4),
                        ),
                        _SidebarItem(
                          icon: LucideIcons.receipt,
                          label: 'Transactions',
                          isActive: selectedIndex == 5,
                          onTap: () => onIndexChanged(5),
                        ),
                      ] else ...[
                        _SidebarItem(
                          icon: LucideIcons.layoutDashboard,
                          label: 'Overview',
                          isActive: selectedIndex == 0,
                          onTap: () => onIndexChanged(0),
                        ),
                        _SidebarItem(
                          icon: LucideIcons.userCog,
                          label: 'Manage Admin Accounts',
                          isActive: selectedIndex == 1,
                          onTap: () => onIndexChanged(1),
                        ),
                        _SidebarItem(
                          icon: LucideIcons.percent,
                          label: 'Platform Commission',
                          isActive: selectedIndex == 2,
                          onTap: () => onIndexChanged(2),
                        ),
                        _SidebarItem(
                          icon: LucideIcons.activity,
                          label: 'System Health & Security',
                          isActive: selectedIndex == 3,
                          onTap: () => onIndexChanged(3),
                        ),
                      ],
                    ],
                  ),
                ),

                // Sign Out Footer
                Container(
                  padding: const EdgeInsets.all(24),
                  child: InkWell(
                    onTap: onLogout,
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.logOut,
                          size: 20,
                          color: Colors.black54,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Sign Out',
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                      ],
                    ),
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
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFEEEFF0)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _getPageTitle(selectedIndex),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: (() {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null || user.email == null) {
                            return Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
                          }
                          return FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.email)
                              .collection('notifications')
                              .where('isRead', isEqualTo: false)
                              .snapshots();
                        })(),
                        builder: (context, snapshot) {
                          final unreadCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                          return IconButton(
                            icon: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                const Icon(LucideIcons.bell),
                                if (unreadCount > 0)
                                  Positioned(
                                    top: -2,
                                    right: -2,
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: const BoxDecoration(
                                        color: AppTheme.primaryRed,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 14,
                                        minHeight: 14,
                                      ),
                                      child: Center(
                                        child: Text(
                                          unreadCount > 9 ? '9+' : '$unreadCount',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                            height: 1.0,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            onPressed: onNotificationPressed,
                          );
                        },
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
    if (!isSuperAdmin) {
      switch (index) {
        case 0:
          return 'Admin Dashboard';
        case 1:
          return 'Verify Tutors';
        case 2:
          return 'Commission Rates';
        case 3:
          return 'Subscription Management';
        case 4:
          return 'Manage Accounts';
        case 5:
          return 'Transactions';
        default:
          return 'Admin Portal';
      }
    } else {
      switch (index) {
        case 0:
          return 'Super Admin Dashboard';
        case 1:
          return 'Manage Accounts';
        case 2:
          return 'Commission Management';
        case 3:
          return 'System Health & Security';
        default:
          return 'Super Admin Portal';
      }
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: isActive
            ? AppTheme.primaryRed.withOpacity(0.08)
            : null,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/app_theme.dart';
import '../../widgets/admin_layout.dart';
import '../login_screen.dart';
import 'admin_dashboard_screen.dart';
import '../super_admin/user_management_screen.dart';
import '../super_admin/service_approvals_screen.dart';
import '../super_admin/audit_logs_screen.dart';
import 'subscription_management_screen.dart';
import 'commission_rates_screen.dart';
import 'transactions_screen.dart';
import '../notifications_screen.dart';

class AdminPortal extends StatefulWidget {
  const AdminPortal({super.key});

  @override
  State<AdminPortal> createState() => _AdminPortalState();
}

class _AdminPortalState extends State<AdminPortal> {
  int _selectedIndex = 0;

  void _showNotificationsDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      AdminDashboardScreen(
        onTabChange: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      const ServiceApprovalsScreen(),
      const CommissionRatesScreen(),
      const SubscriptionManagementScreen(),
      const UserManagementScreen(),
      const TransactionsScreen(),
    ];

    return AdminLayout(
      isSuperAdmin: false,
      selectedIndex: _selectedIndex,
      onIndexChanged: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      onAddUserPressed:
          () {}, // Admins might not be able to add users directly from top bar, or maybe handle similarly
      onNotificationPressed: () => _showNotificationsDialog(context),
      onLogout: () async {
        await FirebaseAuth.instance.signOut();
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      },
      child: pages[_selectedIndex],
    );
  }
}

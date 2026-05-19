import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/app_theme.dart';
import '../../widgets/admin_layout.dart';
import '../login_screen.dart';
import 'super_admin_dashboard_screen.dart';
import 'user_management_screen.dart';
import 'service_approvals_screen.dart';
import 'reports_analytics_screen.dart';
import 'system_settings_screen.dart';
import 'audit_logs_screen.dart';
import '../admin/subscription_management_screen.dart';
import '../notifications_screen.dart';

class SuperAdminPortal extends StatefulWidget {
  const SuperAdminPortal({super.key});

  @override
  State<SuperAdminPortal> createState() => _SuperAdminPortalState();
}

class _SuperAdminPortalState extends State<SuperAdminPortal> {
  int _selectedIndex = 0;

  void _showAddUserDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String email = '';
    String role = 'student';
    String status = 'Active';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Add New User',
                style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Full Name',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        decoration: InputDecoration(
                          hintText: 'Enter full name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Name is required'
                            : null,
                        onSaved: (val) => name = val!.trim(),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Email Address',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        decoration: InputDecoration(
                          hintText: 'Enter email address',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty)
                            return 'Email is required';
                          if (!val.contains('@'))
                            return 'Enter a valid email address';
                          return null;
                        },
                        onSaved: (val) => email = val!.trim().toLowerCase(),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Assign Role',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: role,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                        ),
                        items: ['student', 'tutor', 'admin'].map((r) {
                          return DropdownMenuItem(
                            value: r,
                            child: Text(
                              r.toUpperCase(),
                              style: GoogleFonts.manrope(fontSize: 13),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              role = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Assign Status',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: status,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                        ),
                        items: ['Active', 'Pending', 'Suspended'].map((s) {
                          return DropdownMenuItem(
                            value: s,
                            child: Text(
                              s,
                              style: GoogleFonts.manrope(fontSize: 13),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              status = val;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.manrope(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Adding new user...'),
                          duration: Duration(seconds: 1),
                        ),
                      );

                      // Add to Firestore
                      await FirebaseFirestore.instance.collection('users').add({
                        'name': name,
                        'email': email,
                        'role': role,
                        'status': status,
                        'authProvider': 'Email',
                        'createdAt': FieldValue.serverTimestamp(),
                      });

                      // Log audit event
                      await FirebaseFirestore.instance
                          .collection('audit_logs')
                          .add({
                            'action':
                                'Created new user: $email as ${role.toUpperCase()}',
                            'timestamp': FieldValue.serverTimestamp(),
                            'adminEmail': 'j.antukan.549054@umindanao.edu.ph',
                          });
                    }
                  },
                  child: Text(
                    'Add User',
                    style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showNotificationsDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      SuperAdminDashboardScreen(
        onTabChange: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      const UserManagementScreen(),
      const ServiceApprovalsScreen(isSuperAdmin: true),
      const ReportsAnalyticsScreen(),
      const SystemSettingsScreen(),
      const SubscriptionManagementScreen(),
      const AuditLogsScreen(),
    ];

    return AdminLayout(
      selectedIndex: _selectedIndex,
      onIndexChanged: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      onAddUserPressed: () => _showAddUserDialog(context),
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

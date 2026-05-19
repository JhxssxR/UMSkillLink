import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_theme.dart';
import '../../core/demo_mode.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedRoleFilter = 'All Users'; // 'All Users', 'student', 'admin'

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showEditRoleDialog(
    BuildContext context,
    String docId,
    Map<String, dynamic> userData,
  ) {
    String currentRole = userData['role'] ?? 'student';
    String currentStatus = userData['status'] ?? 'Active';

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
                'Modify User Profile',
                style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'User: ${userData['name'] ?? userData['email']}',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Assign Role:',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: currentRole,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                    ),
                    items: ['student', 'tutor', 'admin'].map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(
                          role.toUpperCase(),
                          style: GoogleFonts.manrope(fontSize: 13),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          currentRole = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Assign Status:',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: currentStatus,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                    ),
                    items: ['Active', 'Pending', 'Suspended'].map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(
                          status,
                          style: GoogleFonts.manrope(fontSize: 13),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          currentStatus = val;
                        });
                      }
                    },
                  ),
                ],
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
                    Navigator.pop(context);

                    // Show a snackbar feedback
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Updating user record...'),
                        duration: Duration(seconds: 1),
                      ),
                    );

                    // Update in Firestore
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(docId)
                        .update({'role': currentRole, 'status': currentStatus});

                    // Log audit event
                    await FirebaseFirestore.instance.collection('audit_logs').add({
                      'action':
                          'Modified profile of ${userData['email']} (Role: $currentRole, Status: $currentStatus)',
                      'timestamp': FieldValue.serverTimestamp(),
                      'adminEmail': 'j.antukan.549054@umindanao.edu.ph',
                    });
                  },
                  child: Text(
                    'Save Changes',
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

  void _confirmDeleteUser(BuildContext context, String docId, String email) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Delete User permanently?',
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryRed,
            ),
          ),
          content: Text(
            'This action is irreversible. The user account associated with $email will be completely deleted from UMSkillLink registries.',
            style: GoogleFonts.manrope(fontSize: 13),
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
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Deleting user record...'),
                    duration: Duration(seconds: 1),
                  ),
                );

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(docId)
                    .delete();

                // Log audit event
                await FirebaseFirestore.instance.collection('audit_logs').add({
                  'action': 'Deleted user registry for $email',
                  'timestamp': FieldValue.serverTimestamp(),
                  'adminEmail': 'j.antukan.549054@umindanao.edu.ph',
                });
              },
              child: Text(
                'Delete Permanent',
                style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

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
                controller: _searchController,
                style: GoogleFonts.manrope(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search users by name or email...',
                  hintStyle: GoogleFonts.manrope(
                    fontSize: 14,
                    color: Colors.grey.shade400,
                  ),
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
            GestureDetector(
              onTap: () => setState(() => _selectedRoleFilter = 'All Users'),
              child: _FilterChip(
                label: 'All Users',
                isActive: _selectedRoleFilter == 'All Users',
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() => _selectedRoleFilter = 'student'),
              child: _FilterChip(
                label: 'Students',
                isActive: _selectedRoleFilter == 'student',
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() => _selectedRoleFilter = 'admin'),
              child: _FilterChip(
                label: 'Admins',
                isActive: _selectedRoleFilter == 'admin',
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),

        // Live Dynamic Users Table from Firestore
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: DemoMode.isActive
              ? _buildMockUsersTable()
              : StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(48.0),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryRed,
                          ),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Center(
                          child: Text(
                            'Error loading users from database: ${snapshot.error}',
                            style: GoogleFonts.manrope(
                              color: AppTheme.primaryRed,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }

                    final docs = snapshot.data?.docs ?? [];

                    // Filter and Search in memory
                    final filteredDocs = docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final email = (data['email'] ?? '')
                          .toString()
                          .toLowerCase();
                      final name = (data['name'] ?? '')
                          .toString()
                          .toLowerCase();
                      final role = (data['role'] ?? 'student')
                          .toString()
                          .toLowerCase();

                      // Role Filter
                      if (_selectedRoleFilter != 'All Users' &&
                          role != _selectedRoleFilter) {
                        return false;
                      }

                      // Search Query Filter
                      if (_searchQuery.isNotEmpty) {
                        return email.contains(_searchQuery) ||
                            name.contains(_searchQuery);
                      }

                      return true;
                    }).toList();

                    if (filteredDocs.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(48.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              LucideIcons.users,
                              size: 48,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No matching dynamic users found in database',
                              style: GoogleFonts.manrope(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Newly signed up users via Google Sign-In will automatically populate here.',
                              style: GoogleFonts.manrope(
                                color: Colors.grey.shade400,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return SizedBox(
                      width: double.infinity,
                      child: DataTable(
                        dataRowMinHeight: 60,
                        dataRowMaxHeight: 60,
                        headingRowColor: WidgetStateProperty.all(
                          Colors.grey.shade50,
                        ),
                        columns: [
                          DataColumn(
                            label: Text(
                              'USER',
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'ROLE',
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'STATUS',
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'PROVIDER',
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'ACTIONS',
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        rows: filteredDocs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final docId = doc.id;
                          final name = data['name'] ?? 'UM USER';
                          final email = data['email'] ?? 'unknown@um.edu.ph';
                          final role = (data['role'] ?? 'student')
                              .toString()
                              .toUpperCase();
                          final status = data['status'] ?? 'Active';
                          final provider = data['authProvider'] ?? 'Google';

                          return DataRow(
                            cells: [
                              DataCell(
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: AppTheme.primaryRed
                                            .withOpacity(0.1),
                                        child: Text(
                                          name.isNotEmpty ? name[0] : 'U',
                                          style: const TextStyle(
                                            color: AppTheme.primaryRed,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            name,
                                            style: GoogleFonts.manrope(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                          Text(
                                            email,
                                            style: GoogleFonts.manrope(
                                              color: Colors.grey.shade500,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: role == 'ADMIN'
                                        ? AppTheme.tertiaryIndigo.withOpacity(
                                            0.1,
                                          )
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    role,
                                    style: GoogleFonts.manrope(
                                      color: role == 'ADMIN'
                                          ? AppTheme.tertiaryIndigo
                                          : Colors.black87,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(_buildStatusBadge(status)),
                              DataCell(
                                Text(
                                  provider,
                                  style: GoogleFonts.manrope(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Edit Role/Status',
                                      icon: const Icon(
                                        LucideIcons.edit2,
                                        size: 16,
                                        color: Colors.blueGrey,
                                      ),
                                      onPressed: () => _showEditRoleDialog(
                                        context,
                                        docId,
                                        data,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Delete Permanently',
                                      icon: const Icon(
                                        LucideIcons.trash2,
                                        size: 16,
                                        color: AppTheme.primaryRed,
                                      ),
                                      onPressed: () => _confirmDeleteUser(
                                        context,
                                        docId,
                                        email,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'Active':
        color = Colors.green;
        break;
      case 'Pending':
        color = AppTheme.secondaryGold;
        break;
      case 'Suspended':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMockUsersTable() {
    final List<Map<String, dynamic>> mockDocs = [
      {
        'id': '1',
        'name': 'John Doe',
        'email': 'j.doe.123456@umindanao.edu.ph',
        'role': 'student',
        'status': 'Active',
        'authProvider': 'Google',
      },
      {
        'id': '2',
        'name': 'Jane Smith',
        'email': 'j.smith.654321@umindanao.edu.ph',
        'role': 'tutor',
        'status': 'Pending',
        'authProvider': 'Google',
      },
      {
        'id': '3',
        'name': 'Admin User',
        'email': 'admin@umindanao.edu.ph',
        'role': 'admin',
        'status': 'Active',
        'authProvider': 'Google',
      },
      {
        'id': '4',
        'name': 'Mark Johnson',
        'email': 'm.johnson.111111@umindanao.edu.ph',
        'role': 'student',
        'status': 'Suspended',
        'authProvider': 'Email',
      },
    ];

    final filteredDocs = mockDocs.where((data) {
      final email = (data['email'] ?? '').toString().toLowerCase();
      final name = (data['name'] ?? '').toString().toLowerCase();
      final role = (data['role'] ?? 'student').toString().toLowerCase();

      if (_selectedRoleFilter != 'All Users' && role != _selectedRoleFilter) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        return email.contains(_searchQuery) || name.contains(_searchQuery);
      }
      return true;
    }).toList();

    if (filteredDocs.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(48.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.users, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No matching dynamic users found in demo mode',
              style: GoogleFonts.manrope(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: DataTable(
        dataRowMinHeight: 60,
        dataRowMaxHeight: 60,
        headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
        columns: [
          DataColumn(
            label: Text(
              'USER',
              style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'ROLE',
              style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'STATUS',
              style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'PROVIDER',
              style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'ACTIONS',
              style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
            ),
          ),
        ],
        rows: filteredDocs.map((data) {
          final docId = data['id'];
          final name = data['name'] ?? 'UM USER';
          final email = data['email'] ?? 'unknown@um.edu.ph';
          final role = (data['role'] ?? 'student').toString().toUpperCase();
          final status = data['status'] ?? 'Active';
          final provider = data['authProvider'] ?? 'Google';

          return DataRow(
            cells: [
              DataCell(
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppTheme.primaryRed.withOpacity(0.1),
                        child: Text(
                          name.isNotEmpty ? name[0] : 'U',
                          style: const TextStyle(
                            color: AppTheme.primaryRed,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            email,
                            style: GoogleFonts.manrope(
                              color: Colors.grey.shade500,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: role == 'ADMIN'
                        ? AppTheme.tertiaryIndigo.withOpacity(0.1)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    role,
                    style: GoogleFonts.manrope(
                      color: role == 'ADMIN'
                          ? AppTheme.tertiaryIndigo
                          : Colors.black87,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              DataCell(_buildStatusBadge(status)),
              DataCell(
                Text(
                  provider,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Edit Role/Status',
                      icon: const Icon(
                        LucideIcons.edit2,
                        size: 16,
                        color: Colors.blueGrey,
                      ),
                      onPressed: () {},
                    ),
                    IconButton(
                      tooltip: 'Delete Permanently',
                      icon: const Icon(
                        LucideIcons.trash2,
                        size: 16,
                        color: AppTheme.primaryRed,
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
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
        border: Border.all(
          color: isActive ? AppTheme.primaryRed : Colors.grey.shade300,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          color: isActive ? Colors.white : Colors.black87,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
      ),
    );
  }
}

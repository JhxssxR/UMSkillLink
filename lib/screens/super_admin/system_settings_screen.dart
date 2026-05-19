import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_theme.dart';

class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _feeController = TextEditingController();
  final TextEditingController _withdrawalController = TextEditingController();

  bool _autoApprove = true;
  bool _twoFactor = true;
  bool _keywordFilter = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('global')
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _feeController.text = (data['transactionFee'] ?? 5.0).toString();
          _withdrawalController.text = (data['minWithdrawal'] ?? 500.0)
              .toString();
          _autoApprove = data['autoApprove'] ?? true;
          _twoFactor = data['twoFactor'] ?? true;
          _keywordFilter = data['keywordFilter'] ?? false;
          _isLoading = false;
        });
      } else {
        // Create initial default settings
        await FirebaseFirestore.instance
            .collection('settings')
            .doc('global')
            .set({
              'transactionFee': 5.0,
              'minWithdrawal': 500.0,
              'autoApprove': true,
              'twoFactor': true,
              'keywordFilter': false,
            });
        setState(() {
          _feeController.text = '5.0';
          _withdrawalController.text = '500';
          _autoApprove = true;
          _twoFactor = true;
          _keywordFilter = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading settings from Firestore: $e');
      setState(() {
        _feeController.text = '5.0';
        _withdrawalController.text = '500';
        _isLoading = false;
      });
    }
  }

  void _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final fee = double.tryParse(_feeController.text) ?? 5.0;
      final withdrawal = double.tryParse(_withdrawalController.text) ?? 500.0;

      await FirebaseFirestore.instance
          .collection('settings')
          .doc('global')
          .set({
            'transactionFee': fee,
            'minWithdrawal': withdrawal,
            'autoApprove': _autoApprove,
            'twoFactor': _twoFactor,
            'keywordFilter': _keywordFilter,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      // Log audit event
      await FirebaseFirestore.instance.collection('audit_logs').add({
        'action':
            'Updated platform configuration system settings (Fee: $fee%, Min: ₱$withdrawal)',
        'timestamp': FieldValue.serverTimestamp(),
        'adminEmail': 'j.antukan.549054@umindanao.edu.ph',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'System settings successfully saved in Cloud Firestore!',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save settings: $e'),
          backgroundColor: AppTheme.primaryRed,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(64.0),
          child: CircularProgressIndicator(color: AppTheme.primaryRed),
        ),
      );
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Platform Configuration'),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  _buildSettingRow(
                    'Transaction Fee (%)',
                    'The percentage taken from every student booking.',
                    child: SizedBox(
                      width: 120,
                      child: TextFormField(
                        controller: _feeController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          suffixText: '%',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (double.tryParse(value) == null) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                  ),
                  const Divider(height: 48),
                  _buildSettingRow(
                    'Minimum Withdrawal Amount',
                    'The minimum balance required for peer tutors to withdraw.',
                    child: SizedBox(
                      width: 150,
                      child: TextFormField(
                        controller: _withdrawalController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          prefixText: '₱',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (double.tryParse(value) == null) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          _buildSectionTitle('Security & Moderation'),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  _buildToggleRow(
                    'Auto-Approve University Verified Accounts',
                    'Automatically verify users with @umindanao.edu.ph email addresses.',
                    _autoApprove,
                    (val) => setState(() => _autoApprove = val),
                  ),
                  const Divider(height: 48),
                  _buildToggleRow(
                    'Two-Factor Authentication (Admin)',
                    'Require 2FA verification for all administrative accounts.',
                    _twoFactor,
                    (val) => setState(() => _twoFactor = val),
                  ),
                  const Divider(height: 48),
                  _buildToggleRow(
                    'Enable Service Keyword Filtering',
                    'Automatically flag peer tutor services containing restricted keywords.',
                    _keywordFilter,
                    (val) => setState(() => _keywordFilter = val),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: _loadSettings,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(120, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Reset',
                  style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRed,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(180, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Save Settings',
                  style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildSettingRow(
    String title,
    String subtitle, {
    required Widget child,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.manrope(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        child,
      ],
    );
  }

  Widget _buildToggleRow(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.manrope(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: AppTheme.primaryRed.withOpacity(0.5),
          activeThumbColor: AppTheme.primaryRed,
        ),
      ],
    );
  }
}

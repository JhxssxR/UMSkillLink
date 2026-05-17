import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

class SystemSettingsScreen extends StatelessWidget {
  const SystemSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Platform Configuration'),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                _buildSettingRow(
                  'Transaction Fee (%)',
                  'The percentage taken from every student booking.',
                  child: SizedBox(
                    width: 100,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: '5.0',
                        suffixText: '%',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ),
                const Divider(height: 48),
                _buildSettingRow(
                  'Minimum Withdrawal Amount',
                  'The minimum balance required for providers to withdraw.',
                  child: SizedBox(
                    width: 150,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: '500',
                        prefixText: '₱',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
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
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                _buildToggleRow(
                  'Auto-Approve University Verified Accounts',
                  'Automatically verify users with @um.edu.ph email addresses.',
                  true,
                ),
                const Divider(height: 48),
                _buildToggleRow(
                  'Two-Factor Authentication (Admin)',
                  'Require 2FA for all administrative accounts.',
                  true,
                ),
                const Divider(height: 48),
                _buildToggleRow(
                  'Enable Service Keyword Filtering',
                  'Automatically flag services containing restricted keywords.',
                  false,
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
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(120, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRed,
                foregroundColor: Colors.white,
                minimumSize: const Size(180, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildSettingRow(String title, String subtitle, {required Widget child}) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            ],
          ),
        ),
        child,
      ],
    );
  }

  Widget _buildToggleRow(String title, String subtitle, bool value) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            ],
          ),
        ),
        Switch(value: value, onChanged: (v) {}, activeTrackColor: AppTheme.primaryRed),
      ],
    );
  }
}

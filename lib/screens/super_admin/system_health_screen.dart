import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/app_theme.dart';

class SystemHealthScreen extends StatelessWidget {
  const SystemHealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'System Health & Security',
          style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Real-time monitoring of platform stability, security protocols, and server performance.',
          style: GoogleFonts.manrope(color: Colors.grey.shade600, fontSize: 14),
        ),
        const SizedBox(height: 32),
        
        // Health Indicators
        _buildHealthHeader(),
        
        const SizedBox(height: 32),
        
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _buildSecurityPanel(),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildServiceStatus(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHealthHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.shieldCheck, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'System Operational',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade900,
                ),
              ),
              Text(
                'All platform services are running optimally. Last check: Just now.',
                style: GoogleFonts.manrope(color: Colors.green.shade700, fontSize: 13),
              ),
            ],
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(LucideIcons.refreshCw, size: 16),
            label: const Text('Run Diagnostics'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Active Security Measures'),
        const SizedBox(height: 16),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSecurityItem(
                  'SSL/TLS Encryption',
                  'Ensures all data transmitted is encrypted.',
                  'ACTIVE',
                  Colors.blue,
                ),
                const Divider(),
                _buildSecurityItem(
                  'DDoS Protection',
                  'Mitigates large-scale traffic attacks.',
                  'ACTIVE',
                  Colors.blue,
                ),
                const Divider(),
                _buildSecurityItem(
                  'Database Backups',
                  'Last snapshot: 4 hours ago.',
                  'SCHEDULED',
                  Colors.orange,
                ),
                const Divider(),
                _buildSecurityItem(
                  'Firewall Rules',
                  'Filtering unauthorized access attempts.',
                  'SECURE',
                  Colors.green,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServiceStatus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Service Availability'),
        const SizedBox(height: 16),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildStatusRow('Auth Service', true),
                const SizedBox(height: 16),
                _buildStatusRow('Firestore DB', true),
                const SizedBox(height: 16),
                _buildStatusRow('Cloud Storage', true),
                const SizedBox(height: 16),
                _buildStatusRow('Messenger API', true),
                const SizedBox(height: 16),
                _buildStatusRow('Email Server', true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildSecurityItem(String title, String desc, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
                Text(desc, style: GoogleFonts.manrope(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              status,
              style: GoogleFonts.manrope(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String service, bool isUp) {
    return Row(
      children: [
        Icon(
          LucideIcons.checkCircle2,
          size: 16,
          color: isUp ? Colors.green : Colors.red,
        ),
        const SizedBox(width: 12),
        Text(service, style: GoogleFonts.manrope(fontSize: 13)),
        const Spacer(),
        Text(
          isUp ? '99.9%' : 'OFFLINE',
          style: GoogleFonts.manrope(
            fontSize: 11,
            color: isUp ? Colors.grey : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

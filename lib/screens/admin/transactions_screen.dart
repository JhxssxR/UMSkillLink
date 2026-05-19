import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../core/demo_mode.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _selectedStatusFilter =
      'All'; // 'All', 'Completed', 'Pending', 'Failed'

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter Controls
        Row(
          children: [
            const Icon(LucideIcons.filter, size: 20, color: Colors.grey),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () => setState(() => _selectedStatusFilter = 'All'),
              child: _FilterChip(
                label: 'All Transactions',
                isActive: _selectedStatusFilter == 'All',
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() => _selectedStatusFilter = 'Completed'),
              child: _FilterChip(
                label: 'Completed',
                isActive: _selectedStatusFilter == 'Completed',
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() => _selectedStatusFilter = 'Pending'),
              child: _FilterChip(
                label: 'Pending',
                isActive: _selectedStatusFilter == 'Pending',
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),

        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: DemoMode.isActive
              ? _buildMockTransactionsTable()
              : _buildLiveTransactionsTable(),
        ),
      ],
    );
  }

  Widget _buildMockTransactionsTable() {
    final List<Map<String, dynamic>> mockTransactions = [
      {
        'id': 'TXN-001',
        'date': DateTime.now().subtract(const Duration(hours: 2)),
        'amount': 450.00,
        'type': 'Booking Payment',
        'status': 'Completed',
        'user': 'John Doe',
      },
      {
        'id': 'TXN-002',
        'date': DateTime.now().subtract(const Duration(days: 1)),
        'amount': 1200.00,
        'type': 'Subscription Renewal',
        'status': 'Completed',
        'user': 'Jane Smith',
      },
      {
        'id': 'TXN-003',
        'date': DateTime.now().subtract(const Duration(days: 2)),
        'amount': 300.00,
        'type': 'Booking Payment',
        'status': 'Pending',
        'user': 'Mark Johnson',
      },
      {
        'id': 'TXN-004',
        'date': DateTime.now().subtract(const Duration(days: 3)),
        'amount': 850.00,
        'type': 'Withdrawal',
        'status': 'Failed',
        'user': 'Sarah Connor',
      },
    ];

    final filteredTxns = mockTransactions.where((t) {
      if (_selectedStatusFilter != 'All' &&
          t['status'] != _selectedStatusFilter)
        return false;
      return true;
    }).toList();

    return _buildDataTable(filteredTxns);
  }

  Widget _buildLiveTransactionsTable() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('transactions')
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(48.0),
            child: Center(
              child: CircularProgressIndicator(color: AppTheme.primaryRed),
            ),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(32.0),
            child: Center(
              child: Text(
                'Error loading transactions',
                style: GoogleFonts.manrope(
                  color: AppTheme.primaryRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        final filteredTxns = docs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id;
              data['date'] =
                  (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();
              return data;
            })
            .where((t) {
              if (_selectedStatusFilter != 'All' &&
                  t['status'] != _selectedStatusFilter)
                return false;
              return true;
            })
            .toList();

        if (filteredTxns.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(48.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.receipt, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No transactions found',
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

        return _buildDataTable(filteredTxns);
      },
    );
  }

  Widget _buildDataTable(List<Map<String, dynamic>> data) {
    return SizedBox(
      width: double.infinity,
      child: DataTable(
        dataRowMinHeight: 60,
        dataRowMaxHeight: 60,
        headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
        columns: [
          DataColumn(
            label: Text(
              'TRANSACTION ID',
              style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'DATE',
              style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'USER',
              style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'AMOUNT',
              style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'TYPE',
              style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'STATUS',
              style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
            ),
          ),
        ],
        rows: data.map((txn) {
          final String status = txn['status'] ?? 'Unknown';
          final DateTime date = txn['date'] ?? DateTime.now();
          final double amount = (txn['amount'] ?? 0.0).toDouble();

          return DataRow(
            cells: [
              DataCell(
                Text(
                  txn['id'].toString().substring(
                    0,
                    txn['id'].toString().length > 8 ? 8 : null,
                  ),
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryRed,
                  ),
                ),
              ),
              DataCell(
                Text(
                  DateFormat('MMM dd, yyyy').format(date),
                  style: GoogleFonts.manrope(fontSize: 13),
                ),
              ),
              DataCell(
                Text(
                  txn['user'] ?? 'Unknown',
                  style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
                ),
              ),
              DataCell(
                Text(
                  '₱${amount.toStringAsFixed(2)}',
                  style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
                ),
              ),
              DataCell(
                Text(
                  txn['type'] ?? 'Payment',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              DataCell(_buildStatusBadge(status)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'Completed':
        color = Colors.green;
        break;
      case 'Pending':
        color = AppTheme.secondaryGold;
        break;
      case 'Failed':
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

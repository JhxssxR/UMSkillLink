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
      'All'; // 'All', 'Completed', 'Pending', 'Cancelled', 'Failed'
  int _currentPage = 0;
  static const int _pageSize = 10;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('transactions')
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final allTransactions = docs.map((doc) {
          final data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
          data['id'] = doc.id;
          data['date'] = (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();
          return data;
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transactions',
                  style: GoogleFonts.manrope(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(LucideIcons.download),
                  label: const Text('Export Report'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Filter Controls
            Row(
              children: [
                const Icon(LucideIcons.filter, size: 20, color: Colors.grey),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () => setState(() {
                    _selectedStatusFilter = 'All';
                    _currentPage = 0;
                  }),
                  child: _FilterChip(
                    label: 'All Transactions',
                    isActive: _selectedStatusFilter == 'All',
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() {
                    _selectedStatusFilter = 'Completed';
                    _currentPage = 0;
                  }),
                  child: _FilterChip(
                    label: 'Completed',
                    isActive: _selectedStatusFilter == 'Completed',
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() {
                    _selectedStatusFilter = 'Pending';
                    _currentPage = 0;
                  }),
                  child: _FilterChip(
                    label: 'Pending',
                    isActive: _selectedStatusFilter == 'Pending',
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() {
                    _selectedStatusFilter = 'Cancelled';
                    _currentPage = 0;
                  }),
                  child: _FilterChip(
                    label: 'Cancelled',
                    isActive: _selectedStatusFilter == 'Cancelled',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            Card(
              elevation: 2,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: _buildTableContent(snapshot, allTransactions),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTableContent(AsyncSnapshot<QuerySnapshot> snapshot, List<Map<String, dynamic>> allTransactions) {
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

    final filteredTxns = allTransactions.where((t) {
      if (_selectedStatusFilter != 'All' && t['status'] != _selectedStatusFilter) return false;
      return true;
    }).toList();

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

    final int totalItems = filteredTxns.length;
    final int totalPages = (totalItems / _pageSize).ceil();

    if (_currentPage >= totalPages && totalPages > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _currentPage = totalPages - 1);
      });
    }

    final int startIndex = _currentPage * _pageSize;
    final int endIndex = (startIndex + _pageSize < totalItems) ? startIndex + _pageSize : totalItems;

    final paginatedTxns = filteredTxns.sublist(startIndex, endIndex);

    return Column(
      children: [
        _buildDataTable(paginatedTxns),
        // Pagination Footer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Showing ${startIndex + 1} to $endIndex of $totalItems transactions',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                children: [
                  _buildPageButton(
                    icon: LucideIcons.chevronLeft,
                    isEnabled: _currentPage > 0,
                    onTap: () => setState(() => _currentPage--),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Page ${_currentPage + 1} of $totalPages',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildPageButton(
                    icon: LucideIcons.chevronRight,
                    isEnabled: _currentPage < totalPages - 1,
                    onTap: () => setState(() => _currentPage++),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPageButton({
    required IconData icon,
    required bool isEnabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          border: Border.all(
            color: isEnabled ? Colors.grey.shade300 : Colors.grey.shade100,
          ),
          borderRadius: BorderRadius.circular(4),
          color: isEnabled ? Colors.white : Colors.grey.shade50,
        ),
        child: Icon(
          icon,
          size: 16,
          color: isEnabled ? Colors.black87 : Colors.grey.shade400,
        ),
      ),
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
      case 'Cancelled':
        color = Colors.grey.shade600;
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

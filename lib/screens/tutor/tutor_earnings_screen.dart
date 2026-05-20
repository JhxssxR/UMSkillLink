import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../components/custom_app_bar.dart';
import '../../models/mock_data.dart';

class TutorEarningsScreen extends StatefulWidget {
  const TutorEarningsScreen({super.key});

  @override
  State<TutorEarningsScreen> createState() => _TutorEarningsScreenState();
}

class _TutorEarningsScreenState extends State<TutorEarningsScreen> {
  final int _pageSize = 10;
  List<DocumentSnapshot> _earningsHistory = [];
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;

  @override
  void initState() {
    super.initState();
    _fetchEarnings();
  }

  Future<void> _fetchEarnings() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      Query query = FirebaseFirestore.instance
          .collection('users')
          .doc(user.email!.toLowerCase())
          .collection('earnings_history')
          .orderBy('timestamp', descending: true)
          .limit(_pageSize);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final querySnapshot = await query.get();

      if (querySnapshot.docs.length < _pageSize) {
        _hasMore = false;
      }

      if (querySnapshot.docs.isNotEmpty) {
        _lastDocument = querySnapshot.docs.last;
        setState(() {
          _earningsHistory.addAll(querySnapshot.docs);
        });
      }
    } catch (e) {
      debugPrint('Error fetching earnings: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const CustomAppBar(
        title: 'Earnings History',
        centerTitle: false,
      ),
      body: Column(
        children: [
          _buildSummaryHeader(),
          Expanded(
            child: _earningsHistory.isEmpty && !_isLoading
                ? _buildEmptyState()
                : _buildEarningsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader() {
    final userEmail = FirebaseAuth.instance.currentUser?.email?.toLowerCase() ?? '';
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userEmail).snapshots(),
      builder: (context, snapshot) {
        double total = 0.0;
        double pending = 0.0;
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          total = (data['earnings'] ?? 0.0).toDouble();
          pending = (data['pendingEarnings'] ?? 0.0).toDouble();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFEEEFF0))),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _buildSummaryItem('Balance', '₱${total.toStringAsFixed(2)}', Colors.green),
                  const SizedBox(width: 32),
                  _buildSummaryItem('Pending', '₱${pending.toStringAsFixed(2)}', AppTheme.secondaryGold),
                  const Spacer(),
                  if (pending > 0)
                    IconButton(
                      onPressed: _syncStuckEarnings,
                      icon: const Icon(LucideIcons.refreshCcw, color: AppTheme.primaryRed, size: 20),
                      tooltip: 'Sync stuck earnings',
                    ),
                ],
              ),
              if (pending > 0) ...[
                const SizedBox(height: 12),
                Text(
                  'Some earnings might be pending confirmation. Tap refresh to sync.',
                  style: GoogleFonts.manrope(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _syncStuckEarnings() async {
    final userEmail = FirebaseAuth.instance.currentUser?.email?.toLowerCase() ?? '';
    if (userEmail.isEmpty) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Syncing pending earnings...')),
    );

    try {
      // Find completed bookings that might have stuck money
      final snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('tutorEmail', isEqualTo: userEmail)
          .where('status', isEqualTo: 'Completed')
          .limit(10)
          .get();

      for (var doc in snapshot.docs) {
        await MockData.finalizeSession(doc.id, userEmail);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sync complete! Stuck funds released.'), backgroundColor: Colors.green),
        );
        setState(() {
          _earningsHistory.clear();
          _lastDocument = null;
          _hasMore = true;
        });
        _fetchEarnings();
      }
    } catch (e) {
      debugPrint('Error syncing earnings: $e');
    }
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.banknote, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No earnings records found.',
            style: GoogleFonts.manrope(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsList() {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
          _fetchEarnings();
        }
        return true;
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _earningsHistory.length + (_hasMore ? 1 : 0),
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == _earningsHistory.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryRed),
              ),
            );
          }

          final data = _earningsHistory[index].data() as Map<String, dynamic>;
          return _buildEarningsCard(data);
        },
      ),
    );
  }

  Widget _buildEarningsCard(Map<String, dynamic> data) {
    final timestamp = data['timestamp'] as Timestamp?;
    final dateStr = timestamp != null ? DateFormat('MMM dd, yyyy • hh:mm a').format(timestamp.toDate()) : 'Recently';
    final double amount = (data['amount'] ?? 0.0).toDouble();
    final double deduction = (data['deduction'] ?? 0.0).toDouble();
    final double netAmount = (data['netAmount'] ?? 0.0).toDouble();
    final String learnerName = data['learnerName'] ?? 'Student';
    final String subject = data['subject'] ?? 'Tutoring Session';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEFF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject,
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.neutralColor,
                      ),
                    ),
                    Text(
                      'Session with $learnerName',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '+₱${netAmount.toStringAsFixed(2)}',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gross Amount',
                style: GoogleFonts.manrope(fontSize: 12, color: Colors.grey.shade600),
              ),
              Text(
                '₱${amount.toStringAsFixed(2)}',
                style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Platform Fee (${((data['commissionRate'] ?? 0.0) * 100).toInt()}%)',
                style: GoogleFonts.manrope(fontSize: 12, color: Colors.red.shade400),
              ),
              Text(
                '-₱${deduction.toStringAsFixed(2)}',
                style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red.shade400),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            dateStr,
            style: GoogleFonts.manrope(
              fontSize: 10,
              color: Colors.grey.shade400,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

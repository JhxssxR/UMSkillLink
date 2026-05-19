import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/app_theme.dart';
import '../../models/mock_data.dart';
import '../../widgets/student_layout.dart';
import '../../components/custom_app_bar.dart';
import '../../components/tutor_app_bar.dart';
import 'manage_services_screen.dart';
import '../notifications_screen.dart';

class TutorDashboardScreen extends StatefulWidget {
  const TutorDashboardScreen({super.key});

  @override
  State<TutorDashboardScreen> createState() => _TutorDashboardScreenState();
}

class _TutorDashboardScreenState extends State<TutorDashboardScreen> {
  // Wallet state
  double _earnings = 0.00;
  bool _isWithdrawing = false;
  String _growthRate = '0% this month';

  // Active bookings metrics state
  int _activeSessions = 0;
  double _completionRate = 0.0;
  double _tutorRating = 0.0;

  // Pending Requests — loaded from MockData
  List<Map<String, dynamic>> _pendingRequests = [];

  // Your Services Catalog is now fetched from Firestore

  // Notifications — starts empty
  final List<String> _notifications = [];

  // Dynamic user info from Firebase
  String _tutorName = 'Tutor';
  String _tutorEmail = '';

  @override
  void initState() {
    super.initState();
    // Load tutor requests from the shared MockData cache
    _pendingRequests = List<Map<String, dynamic>>.from(MockData.tutorRequests);
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          _tutorEmail = user.email ?? '';
          // Try Firestore first
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.email)
              .get();
          if (doc.exists) {
            final data = doc.data() as Map<String, dynamic>;
            if (mounted) {
              setState(() {
                _tutorName = data['name'] ?? user.displayName ?? 'Tutor';
              });
            }
          } else if (user.displayName != null && user.displayName!.isNotEmpty) {
            if (mounted) {
              setState(() {
                _tutorName = user.displayName!;
              });
            }
          } else if (user.email != null) {
            // Derive name from email
            final parts = user.email!.split('@')[0].split('.');
            final derived = parts.map((part) {
              if (part.isEmpty) return '';
              return part[0].toUpperCase() + part.substring(1);
            }).join(' ');
            if (mounted) {
              setState(() {
                _tutorName = derived;
              });
            }
          }
        }
      }
    } catch (_) {}
  }

  void _withdrawFunds() {
    if (_earnings <= 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Your wallet balance is ₱0.00.',
            style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppTheme.primaryRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isWithdrawing = true;
    });

    // Simulate safe backdrop API delay
    Timer(const Duration(milliseconds: 1800), () {
      if (!mounted) return;

      final double withdrawnAmount = _earnings;
      setState(() {
        _earnings = 0.00;
        _growthRate = '0% this month';
        _isWithdrawing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                LucideIcons.checkCircle,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Withdrawal of ₱${withdrawnAmount.toStringAsFixed(2)} processed to your registered Bank Account!',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    });
  }

  void _acceptBooking(Map<String, dynamic> request) {
    setState(() {
      _pendingRequests.remove(request);
      _activeSessions += 1;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.checkCircle, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Accepted session request from ${request['name']}!',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _declineBooking(Map<String, dynamic> request) {
    setState(() {
      _pendingRequests.remove(request);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.xCircle, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Declined session request from ${request['name']}.',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showTutorMenuSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppTheme.primaryRed.withOpacity(0.1),
                      child: const Icon(
                        LucideIcons.graduationCap,
                        color: AppTheme.primaryRed,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tutor Hub Options',
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppTheme.neutralColor,
                          ),
                        ),
                        Text(
                          'Select an action to continue',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: const Icon(
                    LucideIcons.arrowLeftRight,
                    color: AppTheme.primaryRed,
                  ),
                  title: Text(
                    'Switch to Learner Portal',
                    style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StudentLayout(),
                      ),
                      (route) => false,
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(LucideIcons.wallet, color: Colors.grey),
                  title: Text(
                    'Earnings Ledger & Payouts',
                    style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Ledger feature details coming soon!',
                          style: GoogleFonts.manrope(),
                        ),
                        backgroundColor: AppTheme.neutralColor,
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(LucideIcons.settings, color: Colors.grey),
                  title: Text(
                    'Portal Settings',
                    style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showNotificationPanel() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: TutorAppBar(
        showBackButton: false,
        centerTitle: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFEEEFF0), width: 1.5),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4),
              ],
            ),
            child: Center(
              child: IconButton(
                icon: const Icon(
                  LucideIcons.menu,
                  color: AppTheme.primaryRed,
                  size: 16,
                ),
                padding: EdgeInsets.zero,
                onPressed: () => _showTutorMenuSheet(context),
              ),
            ),
          ),
        ),
        actions: [
          Stack(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primaryRed.withOpacity(0.15),
                child: const Icon(
                  LucideIcons.user,
                  size: 18,
                  color: AppTheme.primaryRed,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: 80,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildSwitchModeCard(),
              const SizedBox(height: 20),
              _buildGreetingPanel(),
              const SizedBox(height: 20),
              _buildDoubleHeroCards(),
              const SizedBox(height: 26),
              _buildPendingRequestsSection(),
              const SizedBox(height: 26),
              _buildYourServicesSection(),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildNotificationFab(),
    );
  }

  // --- SWITCH PORTAL CARD ---
  Widget _buildSwitchModeCard() {
    return GestureDetector(
      onTap: () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const StudentLayout()),
          (route) => false,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.primaryRed.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryRed.withOpacity(0.15),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              LucideIcons.arrowLeftRight,
              color: AppTheme.primaryRed,
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Switch to Learner Portal',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      color: AppTheme.primaryRed,
                    ),
                  ),
                  Text(
                    'Return to finding peer tutors & booking sessions.',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      fontSize: 11.5,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              LucideIcons.chevronRight,
              color: AppTheme.primaryRed,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // --- TUTOR GREETING PANEL ---
  Widget _buildGreetingPanel() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, Tutor $_tutorName!',
              style: GoogleFonts.manrope(
                fontSize: 23,
                fontWeight: FontWeight.w800,
                color: AppTheme.neutralColor,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Accepting new sessions',
                  style: GoogleFonts.manrope(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.secondaryGold.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.secondaryGold.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.shieldCheck,
                color: AppTheme.secondaryGold,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                'CERTIFIED TUTOR',
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.secondaryGold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- DOUBLE HERO METRICS CARDS ---
  Widget _buildDoubleHeroCards() {
    return Row(
      children: [
        // Total Earnings Card
        Expanded(
          flex: 12,
          child: Container(
            height: 172,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFBE1E2D), Color(0xFF90101B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryRed.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Wallet watermark background
                Positioned(
                  right: -10,
                  bottom: -10,
                  child: Opacity(
                    opacity: 0.12,
                    child: Icon(
                      LucideIcons.wallet,
                      size: 88,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL EARNINGS',
                      style: GoogleFonts.manrope(
                        color: Colors.white.withOpacity(0.75),
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₱${_earnings.toStringAsFixed(2)}',
                      style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '📈 $_growthRate',
                        style: GoogleFonts.manrope(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 34,
                      child: ElevatedButton(
                        onPressed: _isWithdrawing ? null : _withdrawFunds,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.primaryRed,
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isWithdrawing
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.primaryRed,
                                  ),
                                ),
                              )
                            : Text(
                                'Withdraw Funds',
                                style: GoogleFonts.manrope(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Active Bookings / Ratings Card
        Expanded(
          flex: 10,
          child: Container(
            height: 172,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEEEFF0), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'RATING',
                      style: GoogleFonts.manrope(
                        color: const Color(0xFF7A7C80),
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryGold.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: AppTheme.secondaryGold,
                            size: 10,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '$_tutorRating',
                            style: GoogleFonts.manrope(
                              color: AppTheme.secondaryGold,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _activeSessions < 10
                      ? '0$_activeSessions'
                      : '$_activeSessions',
                  style: GoogleFonts.manrope(
                    color: AppTheme.neutralColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 32,
                    letterSpacing: -1,
                  ),
                ),
                Text(
                  'Active Sessions',
                  style: GoogleFonts.manrope(
                    color: const Color(0xFF7A7C80),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Completion Rate',
                          style: GoogleFonts.manrope(
                            color: const Color(0xFF7A7C80),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${(_completionRate * 100).toInt()}%',
                          style: GoogleFonts.manrope(
                            color: AppTheme.neutralColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: FractionallySizedBox(
                        widthFactor: _completionRate,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryGold,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- PENDING REQUESTS SECTION ---
  Widget _buildPendingRequestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Pending Requests',
              style: GoogleFonts.manrope(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppTheme.neutralColor,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(width: 8),
            if (_pendingRequests.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_pendingRequests.length}',
                  style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_pendingRequests.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEEEFF0), width: 1.2),
            ),
            child: Center(
              child: Column(
                children: [
                  const Icon(
                    LucideIcons.checkSquare,
                    color: Colors.green,
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No pending requests. Great job!',
                    style: GoogleFonts.manrope(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _pendingRequests.length,
            itemBuilder: (context, index) {
              final req = _pendingRequests[index];
              return _buildRequestCard(req);
            },
          ),
      ],
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> req) {
    final bool isMarco = req['initials'] != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEFF0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isMarco)
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.primaryRed.withOpacity(0.1),
                  child: Text(
                    req['initials'],
                    style: GoogleFonts.manrope(
                      color: AppTheme.primaryRed,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                )
              else
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: NetworkImage(req['avatar']),
                  onBackgroundImageError: (exception, stackTrace) {},
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      req['name'],
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                        color: AppTheme.neutralColor,
                      ),
                    ),
                    Text(
                      req['degree'],
                      style: GoogleFonts.manrope(
                        fontSize: 11.5,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '₱${req['price']} ${req['type']}',
                  style: GoogleFonts.manrope(
                    color: AppTheme.primaryRed,
                    fontWeight: FontWeight.w800,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Grey service schedule banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.bookOpen,
                  color: Color(0xFF7A7C80),
                  size: 13,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${req['subject']} | ${req['schedule']}',
                    style: GoogleFonts.manrope(
                      color: const Color(0xFF495057),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (req['note'] != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Text(
                '"${req['note']}"',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _declineBooking(req),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF7A7C80),
                    side: const BorderSide(
                      color: Color(0xFFDCDFE4),
                      width: 1.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text(
                    'Decline',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _acceptBooking(req),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRed,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text(
                    'Accept Booking',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- YOUR SERVICES SECTION ---
  Widget _buildYourServicesSection() {
    final email = FirebaseAuth.instance.currentUser?.email ?? 'tutor@umindanao.edu.ph';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your Services',
              style: GoogleFonts.manrope(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppTheme.neutralColor,
                letterSpacing: -0.4,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ManageServicesScreen()),
                );
              },
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  LucideIcons.plus,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('services')
              .where('tutorEmail', isEqualTo: email)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 250,
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryRed),
                ),
              );
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEEEFF0)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.briefcase, color: Colors.grey.shade300, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'No services published yet.',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              );
            }

            return SizedBox(
              height: 250,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final svc = docs[index].data() as Map<String, dynamic>;
                  return _buildServiceCatalogCard(svc);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildServiceCatalogCard(Map<String, dynamic> svc) {
    final bool isDraft = svc['status'] == 'Draft';

    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12, bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEFF0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Service header image or draft display
          Stack(
            children: [
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDraft ? Colors.grey.shade100 : Colors.grey.shade200,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  image: svc['image'] != null
                      ? DecorationImage(
                          image: NetworkImage(svc['image']),
                          fit: BoxFit.cover,
                          onError: (exception, stackTrace) {},
                        )
                      : null,
                ),
                child: isDraft
                    ? Center(
                        child: Icon(
                          LucideIcons.fileText,
                          color: Colors.grey.shade400,
                          size: 32,
                        ),
                      )
                    : null,
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isDraft
                        ? Colors.grey.shade800
                        : AppTheme.secondaryGold,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isDraft
                            ? LucideIcons.fileText
                            : LucideIcons.shieldCheck,
                        color: Colors.white,
                        size: 9,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        svc['status'].toUpperCase(),
                        style: GoogleFonts.manrope(
                          color: Colors.white,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    svc['title'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: AppTheme.neutralColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (isDraft) ...[
                    // Draft alert banner / missing items
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.red.shade100),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.alertCircle,
                            color: Colors.red.shade700,
                            size: 10,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              svc['alert'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.manrope(
                                color: Colors.red.shade700,
                                fontSize: 8.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Linear progress loader
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Setup Progress',
                              style: GoogleFonts.manrope(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              '${(svc['progress'] * 100).toInt()}%',
                              style: GoogleFonts.manrope(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        LinearProgressIndicator(
                          value: svc['progress'],
                          color: AppTheme.primaryRed,
                          backgroundColor: Colors.grey.shade200,
                          minHeight: 3.5,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ],
                    ),
                  ] else ...[
                    Text(
                      '${svc['completed'] ?? 0} completed bookings',
                      style: GoogleFonts.manrope(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      svc['price'] ?? '',
                      style: GoogleFonts.manrope(
                        color: AppTheme.primaryRed,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 26,
                            child: OutlinedButton(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFFDCDFE4),
                                ),
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              child: Text(
                                'Edit',
                                style: GoogleFonts.manrope(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                  color: const Color(0xFF495057),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: SizedBox(
                            height: 26,
                            child: ElevatedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Service promote initiated!',
                                      style: GoogleFonts.manrope(),
                                    ),
                                    backgroundColor: AppTheme.neutralColor,
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryRed,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.zero,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              child: Text(
                                'Promote',
                                style: GoogleFonts.manrope(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- NOTIFICATION FAB ---
  Widget _buildNotificationFab() {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? '';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(email)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        final hasUnread = snapshot.hasData && snapshot.data!.docs.isNotEmpty;

        return FloatingActionButton(
          heroTag: 'tutor_notification_fab',
          onPressed: _showNotificationPanel,
          backgroundColor: AppTheme.primaryRed,
          elevation: 4,
          shape: const CircleBorder(),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(LucideIcons.bell, color: Colors.white),
              if (hasUnread)
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: AppTheme.secondaryGold,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

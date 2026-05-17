import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/app_theme.dart';
import '../../models/mock_data.dart';
import '../../widgets/student_layout.dart';

class ConfirmPaymentScreen extends StatefulWidget {
  final String tutorName;
  final String subjectName;
  final String dateStr;
  final String timeSlot;
  final double totalAmount;

  const ConfirmPaymentScreen({
    super.key,
    required this.tutorName,
    required this.subjectName,
    required this.dateStr,
    required this.timeSlot,
    required this.totalAmount,
  });

  @override
  State<ConfirmPaymentScreen> createState() => _ConfirmPaymentScreenState();
}

class _ConfirmPaymentScreenState extends State<ConfirmPaymentScreen> {
  int _selectedMethodIndex = 0; // 0: GCash, 1: Maya, 2: Campus Credit

  void _processPayment() {
    // Show premium loading indicator dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryRed),
            ),
            const SizedBox(height: 24),
            Text(
              'Securing transaction...',
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1C1E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Processing payment with UM SkillLink protection',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: const Color(0xFF7A7C80),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    // Simulate 1.5 second secure payment processing
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;

      // Dismiss loading dialog
      Navigator.pop(context);

      // Insert the newly confirmed session into MockData bookings dynamically!
      MockData.learnerBookings.insert(0, {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'tutorName': widget.tutorName,
        'subject': widget.subjectName,
        'time': '${widget.dateStr}, ${widget.timeSlot}',
        'isUpcoming': true,
        'status': 'Confirmed',
      });

      // Show Payment Success Modal
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFE6F4EA),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF137333),
                  size: 54,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Booking Confirmed!',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1C1E),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'You successfully booked and paid for a peer session with ${widget.tutorName}.',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: const Color(0xFF495057),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Pop dialog
                    Navigator.pop(context);
                    // Navigate directly to the StudentLayout at index 1 (Bookings Screen)!
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StudentLayout(initialIndex: 1),
                      ),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRed,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Go to Bookings',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // AppBar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF1A1C1E)),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'Confirm Payment',
                    style: GoogleFonts.manrope(
                      color: const Color(0xFF1A1C1E),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.user, color: Color(0xFF7A7C80)),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Service Summary Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFEEEFF0), width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'SERVICE SUMMARY',
                                style: GoogleFonts.manrope(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFADB5BD),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              // Verified badge label
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFBB03B).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(LucideIcons.award, color: Color(0xFFFBB03B), size: 10),
                                    const SizedBox(width: 2),
                                    Text(
                                      'Verified',
                                      style: GoogleFonts.manrope(
                                        color: const Color(0xFFFBB03B),
                                        fontSize: 8,
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
                            widget.subjectName,
                            style: GoogleFonts.manrope(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1A1C1E),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Tutor Section
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 20,
                                backgroundImage: NetworkImage(
                                  'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.tutorName,
                                      style: GoogleFonts.manrope(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF1A1C1E),
                                      ),
                                    ),
                                    Text(
                                      'College of Engineering',
                                      style: GoogleFonts.manrope(
                                        fontSize: 11,
                                        color: const Color(0xFF7A7C80),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Date/Time
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    const Icon(LucideIcons.calendar, color: AppTheme.primaryRed, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        widget.dateStr,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.manrope(
                                          color: const Color(0xFF495057),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  children: [
                                    const Icon(LucideIcons.clock, color: AppTheme.primaryRed, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        widget.timeSlot,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.manrope(
                                          color: const Color(0xFF495057),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const Divider(height: 24, color: Color(0xFFDEE2E6)),

                          // Total
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Amount',
                                style: GoogleFonts.manrope(
                                  color: const Color(0xFF7A7C80),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '₱${widget.totalAmount.toStringAsFixed(2)}',
                                style: GoogleFonts.manrope(
                                  color: AppTheme.primaryRed,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Select Payment Method Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select Payment Method',
                          style: GoogleFonts.manrope(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A1C1E),
                          ),
                        ),
                        Text(
                          'Add New',
                          style: GoogleFonts.manrope(
                            color: AppTheme.primaryRed,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Payment option cards
                    _buildPaymentMethodItem(
                      index: 0,
                      title: 'GCash',
                      sub: '0917 • • • 123',
                      iconData: LucideIcons.wallet,
                      iconBgColor: const Color(0xFFE8F0FE),
                      iconColor: const Color(0xFF1A73E8),
                    ),
                    const SizedBox(height: 12),

                    _buildPaymentMethodItem(
                      index: 1,
                      title: 'Maya',
                      sub: '0917 • • • 123',
                      iconData: LucideIcons.phone,
                      iconBgColor: const Color(0xFFE6F4EA),
                      iconColor: const Color(0xFF137333),
                    ),
                    const SizedBox(height: 12),

                    _buildPaymentMethodItem(
                      index: 2,
                      title: 'Campus Credit',
                      sub: 'Balance: ₱1,240.00',
                      iconData: LucideIcons.graduationCap,
                      iconBgColor: const Color(0xFFFFF0F2),
                      iconColor: AppTheme.primaryRed,
                      hasStudentTag: true,
                    ),
                    const SizedBox(height: 24),

                    // Security card notice
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F3F5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.shieldAlert, color: Color(0xFFFBB03B), size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Your payment is secured by UM SkillLink’s student protection policy.',
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                color: const Color(0xFF495057),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // Pay Now bottom button
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRed,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Pay Now ₱${widget.totalAmount.toStringAsFixed(2)}',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(LucideIcons.arrowRight, size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodItem({
    required int index,
    required String title,
    required String sub,
    required IconData iconData,
    required Color iconBgColor,
    required Color iconColor,
    bool hasStudentTag = false,
  }) {
    final isSelected = _selectedMethodIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethodIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryRed : const Color(0xFFEEEFF0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.01),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(iconData, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A1C1E),
                        ),
                      ),
                      if (hasStudentTag) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBB03B).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'STUDENT ONLY',
                            style: GoogleFonts.manrope(
                              color: const Color(0xFFD97706),
                              fontSize: 7,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      color: const Color(0xFF7A7C80),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Radio circle indicator
            Container(
              height: 20,
              width: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppTheme.primaryRed : const Color(0xFFCED4DA),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        height: 10,
                        width: 10,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryRed,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/app_theme.dart';
import 'payment_screen.dart';

class BookingScreen extends StatefulWidget {
  final Map<String, dynamic> tutor;

  const BookingScreen({super.key, required this.tutor});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int _selectedDateIndex = 0;
  String _selectedTimeSlot = '10:30 AM';
  final TextEditingController _goalsController = TextEditingController();
  int _goalsCharCount = 0;

  final List<Map<String, String>> _dates = [
    {'day': 'MON', 'num': '13'},
    {'day': 'TUE', 'num': '14'},
    {'day': 'WED', 'num': '15'},
    {'day': 'THU', 'num': '16'},
    {'day': 'FRI', 'num': '17'},
  ];

  final List<String> _morningSlots = ['09:00 AM', '10:30 AM', '11:00 AM'];
  final List<String> _afternoonSlots = ['01:30 PM', '03:00 PM', '04:30 PM']; // 04:30 PM will be disabled

  @override
  void initState() {
    super.initState();
    _goalsController.addListener(() {
      setState(() {
        _goalsCharCount = _goalsController.text.length;
      });
    });
  }

  @override
  void dispose() {
    _goalsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic price calculation matching screenshots: hourly 450 + 25 fee = 475
    const double hourlyRate = 450.00;
    const double serviceFee = 25.00;
    const double totalAmount = hourlyRate + serviceFee;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Custom Navigation Header
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
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/um_logo.png',
                        height: 28,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          LucideIcons.graduationCap,
                          color: AppTheme.primaryRed,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'UM SkillLink',
                        style: GoogleFonts.manrope(
                          color: AppTheme.primaryRed,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.helpCircle, color: Color(0xFF7A7C80)),
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
                    // Tutor Profile Card Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFEEEFF0), width: 1),
                      ),
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              const CircleAvatar(
                                radius: 30,
                                backgroundImage: NetworkImage(
                                  'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFBB03B),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check, color: Colors.white, size: 10),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Prof. Marco Santos',
                                  style: GoogleFonts.manrope(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1A1C1E),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Advanced Calculus & Statistics',
                                  style: GoogleFonts.manrope(
                                    fontSize: 13,
                                    color: AppTheme.primaryRed,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.star, color: Color(0xFFFBB03B), size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      '4.9',
                                      style: GoogleFonts.manrope(
                                        color: const Color(0xFF1A1C1E),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '(128 reviews)',
                                      style: GoogleFonts.manrope(
                                        color: const Color(0xFF7A7C80),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Select Date Header Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select Date',
                          style: GoogleFonts.manrope(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A1C1E),
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              'May 2024',
                              style: GoogleFonts.manrope(
                                color: AppTheme.primaryRed,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(LucideIcons.calendar, color: AppTheme.primaryRed, size: 16),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Horizontal Date List
                    SizedBox(
                      height: 70,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _dates.length,
                        itemBuilder: (context, index) {
                          final date = _dates[index];
                          final isSelected = _selectedDateIndex == index;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedDateIndex = index;
                              });
                            },
                            child: Container(
                              width: 58,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? AppTheme.primaryRed : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? AppTheme.primaryRed : const Color(0xFFEEEFF0),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    date['day']!,
                                    style: GoogleFonts.manrope(
                                      fontSize: 10,
                                      color: isSelected ? Colors.white.withOpacity(0.8) : const Color(0xFF7A7C80),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    date['num']!,
                                    style: GoogleFonts.manrope(
                                      fontSize: 16,
                                      color: isSelected ? Colors.white : const Color(0xFF1A1C1E),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Available Slots Heading
                    Text(
                      'Available Slots',
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A1C1E),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Morning slots section
                    Row(
                      children: [
                        const Icon(LucideIcons.sun, color: Color(0xFF7A7C80), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'MORNING',
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF7A7C80),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: _morningSlots.map((slot) {
                        final isSelected = _selectedTimeSlot == slot;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedTimeSlot = slot;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? AppTheme.primaryRed : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? AppTheme.primaryRed : const Color(0xFFEEEFF0),
                                ),
                              ),
                              child: Text(
                                slot,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : const Color(0xFF495057),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Afternoon slots section
                    Row(
                      children: [
                        const Icon(LucideIcons.sun, color: Color(0xFF7A7C80), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'AFTERNOON',
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF7A7C80),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: _afternoonSlots.map((slot) {
                        final isSelected = _selectedTimeSlot == slot;
                        final isDisabled = slot == '04:30 PM';
                        return Expanded(
                          child: GestureDetector(
                            onTap: isDisabled
                                ? null
                                : () {
                                    setState(() {
                                      _selectedTimeSlot = slot;
                                    });
                                  },
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isDisabled
                                    ? const Color(0xFFE9ECEF).withOpacity(0.5)
                                    : (isSelected ? AppTheme.primaryRed : Colors.white),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isDisabled
                                      ? const Color(0xFFE9ECEF)
                                      : (isSelected ? AppTheme.primaryRed : const Color(0xFFEEEFF0)),
                                ),
                              ),
                              child: Text(
                                slot,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDisabled
                                      ? const Color(0xFFADB5BD)
                                      : (isSelected ? Colors.white : const Color(0xFF495057)),
                                  decoration: isDisabled ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Session goals heading
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Session Goals',
                          style: GoogleFonts.manrope(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A1C1E),
                          ),
                        ),
                        Text(
                          'Optional',
                          style: GoogleFonts.manrope(
                            color: const Color(0xFF7A7C80),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Multi-line text field
                    TextField(
                      controller: _goalsController,
                      maxLines: 4,
                      maxLength: 500,
                      decoration: InputDecoration(
                        hintText: 'E.g. I need help with integration by parts and solving differential equations...',
                        hintStyle: GoogleFonts.manrope(
                          color: const Color(0xFFADB5BD),
                          fontSize: 12,
                        ),
                        counterText: '',
                        fillColor: Colors.white,
                        filled: true,
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: AppTheme.primaryRed, width: 1.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Color(0xFFEEEFF0)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF495057)),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '$_goalsCharCount/500',
                        style: GoogleFonts.manrope(
                          color: const Color(0xFF7A7C80),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Pricing block card container
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F3F5).withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Rate (1 hour)',
                                style: GoogleFonts.manrope(
                                  color: const Color(0xFF495057),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '₱${hourlyRate.toStringAsFixed(2)}',
                                style: GoogleFonts.manrope(
                                  color: const Color(0xFF1A1C1E),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Service Fee',
                                style: GoogleFonts.manrope(
                                  color: const Color(0xFF495057),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '₱${serviceFee.toStringAsFixed(2)}',
                                style: GoogleFonts.manrope(
                                  color: const Color(0xFF1A1C1E),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24, color: Color(0xFFDEE2E6)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Amount',
                                style: GoogleFonts.manrope(
                                  color: const Color(0xFF1A1C1E),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '₱${totalAmount.toStringAsFixed(2)}',
                                style: GoogleFonts.manrope(
                                  color: AppTheme.primaryRed,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Confirm Booking Bottom Button
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final selectedDateMap = _dates[_selectedDateIndex];
                    final dateStr = 'May ${selectedDateMap['num']}, 2024';
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ConfirmPaymentScreen(
                          tutorName: 'Gabriel Reyes',
                          subjectName: 'Advanced Calculus Tutoring',
                          dateStr: dateStr,
                          timeSlot: _selectedTimeSlot,
                          totalAmount: totalAmount,
                        ),
                      ),
                    );
                  },
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
                        'Confirm Booking',
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
}

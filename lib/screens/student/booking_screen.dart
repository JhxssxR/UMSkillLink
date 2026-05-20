import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/app_theme.dart';
import '../../components/custom_app_bar.dart';
import '../../models/mock_data.dart';
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
  int _selectedHours = 1;
  String _userTier = 'Free';
  int _activeBookingCount = 0;

  final List<Map<String, String>> _dates = [];
  String _currentMonthYear = '';
  List<String> _bookedSlots = [];
  bool _isLoadingBookings = true;

  final List<String> _potentialMorningSlots = [
    '08:00 AM',
    '08:30 AM',
    '09:00 AM',
    '09:30 AM',
    '10:00 AM',
    '10:30 AM',
    '11:00 AM',
    '11:30 AM',
  ];

  final List<String> _potentialAfternoonSlots = [
    '12:00 PM',
    '12:30 PM',
    '01:00 PM',
    '01:30 PM',
    '02:00 PM',
    '02:30 PM',
    '03:00 PM',
    '03:30 PM',
    '04:00 PM',
    '04:30 PM',
    '05:00 PM',
    '05:30 PM',
    '06:00 PM',
    '06:30 PM',
    '07:00 PM',
    '07:30 PM',
    '08:00 PM',
  ];

  final List<String> _morningSlots = [];
  final List<String> _afternoonSlots = [];

  String _getDateStrForNum(String dateNum) {
    final dateMap = _dates.firstWhere(
      (d) => d['num'] == dateNum,
      orElse: () => {},
    );
    if (dateMap.isEmpty) return '';
    return '${dateMap['month']} ${dateMap['num']}, ${dateMap['year']}';
  }

  Future<void> _fetchTutorBookings() async {
    try {
      final String tutorEmail = widget.tutor['tutorEmail'] ?? widget.tutor['email'] ?? '';
      if (tutorEmail.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoadingBookings = false;
          });
        }
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('tutorEmail', isEqualTo: tutorEmail)
          .get();

      final List<String> booked = [];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data['status'] == 'Declined' || data['status'] == 'Cancelled') {
          continue;
        }
        final String? timeVal = data['time'];
        if (timeVal != null) {
          booked.add(timeVal);
        }
      }

      if (mounted) {
        setState(() {
          _bookedSlots = booked;
          _isLoadingBookings = false;
        });
        _selectFirstAvailableSlot();
      }
    } catch (e) {
      debugPrint('Error fetching tutor bookings: $e');
      if (mounted) {
        setState(() {
          _isLoadingBookings = false;
        });
      }
    }
  }

  bool isSlotDisabled(String dateNum, String slot) {
    final dateStr = _getDateStrForNum(dateNum);
    if (dateStr.isEmpty) return false;

    final bookingTime = '$dateStr • $slot';

    // 1. Check Firestore fetched booked slots
    if (_bookedSlots.contains(bookingTime)) {
      return true;
    }

    // 2. Also check local MockData (for instant feedback after booking)
    final String tutorEmail = widget.tutor['tutorEmail'] ?? widget.tutor['email'] ?? '';
    final bool isMockBooked = MockData.learnerBookings.any((b) {
      final String? tEmail = b['tutorEmail'];
      final String? time = b['time'];
      final String? status = b['status'];
      
      return tEmail == tutorEmail && 
             time == bookingTime && 
             status != 'Declined' && 
             status != 'Cancelled';
    });

    if (isMockBooked) return true;

    // 3. Also check tutor_requests
    final bool isRequestBooked = MockData.tutorRequests.any((r) {
      final String? tEmail = r['tutorEmail'];
      final String? date = r['time'];
      final String? timeSlot = r['timeDetail'];
      final String? status = r['status'];

      return tEmail == tutorEmail && 
             '$date • $timeSlot' == bookingTime && 
             status != 'Declined' && 
             status != 'Cancelled';
    });

    return isRequestBooked;
  }

  bool _isSlotInHours(String slotText, String availabilityHours) {
    final double slotHour = _parseTimeToDouble(slotText);
    final String cleanHours = availabilityHours.toLowerCase();

    if (cleanHours.contains('after')) {
      final String timePart = cleanHours.replaceAll('after', '').trim();
      final double afterHour = _parseTimeToDouble(timePart);
      return slotHour >= afterHour;
    }

    if (cleanHours.contains('before')) {
      final String timePart = cleanHours.replaceAll('before', '').replaceAll('only', '').trim();
      final double beforeHour = _parseTimeToDouble(timePart);
      return slotHour < beforeHour;
    }

    if (cleanHours.contains('-')) {
      final parts = cleanHours.split('-');
      if (parts.length == 2) {
        final double startHour = _parseTimeToDouble(parts[0].trim());
        final double endHour = _parseTimeToDouble(parts[1].trim());
        return slotHour >= startHour && slotHour <= endHour;
      }
    }

    return true;
  }

  double _parseTimeToDouble(String timeStr) {
    final cleanStr = timeStr.toLowerCase().replaceAll(' ', '').replaceAll(':', '');
    bool isPm = cleanStr.contains('pm');
    final numberStr = cleanStr.replaceAll('am', '').replaceAll('pm', '');
    int val = int.tryParse(numberStr) ?? 0;
    double hour = 0;

    if (val >= 100) {
      final int mins = val % 100;
      final int hrs = val ~/ 100;
      hour = hrs + (mins / 60.0);
    } else {
      hour = val.toDouble();
    }

    if (isPm && hour < 12) {
      hour += 12;
    } else if (!isPm && hour == 12) {
      hour = 0;
    }

    return hour;
  }

  bool _isDayInDays(int weekday, String availabilityDays) {
    final String cleanDays = availabilityDays.toLowerCase();

    if (cleanDays.contains('weekend') ||
        cleanDays.contains('sat-sun') ||
        cleanDays.contains('sat - sun') ||
        (cleanDays.contains('saturday') && cleanDays.contains('sunday'))) {
      return weekday == DateTime.saturday || weekday == DateTime.sunday;
    }

    if (cleanDays.contains('mon-fri') ||
        cleanDays.contains('mon - fri') ||
        cleanDays.contains('monday - friday') ||
        cleanDays.contains('weekdays') ||
        cleanDays.contains('mon-friday')) {
      return weekday != DateTime.saturday && weekday != DateTime.sunday;
    }

    if (cleanDays.contains('mon')) {
      if (weekday == DateTime.monday) return true;
    }
    if (cleanDays.contains('tue')) {
      if (weekday == DateTime.tuesday) return true;
    }
    if (cleanDays.contains('wed')) {
      if (weekday == DateTime.wednesday) return true;
    }
    if (cleanDays.contains('thu')) {
      if (weekday == DateTime.thursday) return true;
    }
    if (cleanDays.contains('fri')) {
      if (weekday == DateTime.friday) return true;
    }
    if (cleanDays.contains('sat')) {
      if (weekday == DateTime.saturday) return true;
    }
    if (cleanDays.contains('sun')) {
      if (weekday == DateTime.sunday) return true;
    }

    if (!cleanDays.contains('mon') &&
        !cleanDays.contains('tue') &&
        !cleanDays.contains('wed') &&
        !cleanDays.contains('thu') &&
        !cleanDays.contains('fri') &&
        !cleanDays.contains('sat') &&
        !cleanDays.contains('sun')) {
      return true;
    }

    return false;
  }

  void _filterTimeSlots() {
    final String availabilityHours = widget.tutor['availabilityHours'] ??
        widget.tutor['tutorAvailabilityHours'] ??
        'After 5:00 PM';

    _morningSlots.clear();
    for (final slot in _potentialMorningSlots) {
      if (_isSlotInHours(slot, availabilityHours)) {
        _morningSlots.add(slot);
      }
    }

    _afternoonSlots.clear();
    for (final slot in _potentialAfternoonSlots) {
      if (_isSlotInHours(slot, availabilityHours)) {
        _afternoonSlots.add(slot);
      }
    }

    if (_morningSlots.isEmpty && _afternoonSlots.isEmpty) {
      _morningSlots.addAll(['09:00 AM', '10:30 AM']);
      _afternoonSlots.addAll(['01:30 PM', '03:00 PM', '04:30 PM']);
    }
  }

  void _generateUpcomingWeekdays() {
    final List<Map<String, String>> tempDates = [];
    DateTime current = DateTime.now();
    int added = 0;

    final String availabilityDays = widget.tutor['availabilityDays'] ??
        widget.tutor['tutorAvailabilityDays'] ??
        'Mon-Fri';

    for (int i = 0; i < 30 && added < 5; i++) {
      if (_isDayInDays(current.weekday, availabilityDays)) {
        String dayName = '';
        switch (current.weekday) {
          case DateTime.monday:
            dayName = 'MON';
            break;
          case DateTime.tuesday:
            dayName = 'TUE';
            break;
          case DateTime.wednesday:
            dayName = 'WED';
            break;
          case DateTime.thursday:
            dayName = 'THU';
            break;
          case DateTime.friday:
            dayName = 'FRI';
            break;
          case DateTime.saturday:
            dayName = 'SAT';
            break;
          case DateTime.sunday:
            dayName = 'SUN';
            break;
        }
        tempDates.add({
          'day': dayName,
          'num': current.day.toString(),
          'month': _getMonthName(current.month),
          'year': current.year.toString(),
        });
        added++;
      }
      current = current.add(const Duration(days: 1));
    }

    setState(() {
      _dates.clear();
      _dates.addAll(tempDates);
      if (_dates.isNotEmpty) {
        _currentMonthYear = '${_dates[0]['month']} ${_dates[0]['year']}';
      }
    });
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  void _selectFirstAvailableSlot() {
    if (_dates.isEmpty) return;
    final dateNum = _dates[_selectedDateIndex]['num'] ?? '1';

    for (final slot in _morningSlots) {
      if (!isSlotDisabled(dateNum, slot)) {
        setState(() {
          _selectedTimeSlot = slot;
        });
        return;
      }
    }

    for (final slot in _afternoonSlots) {
      if (!isSlotDisabled(dateNum, slot)) {
        setState(() {
          _selectedTimeSlot = slot;
        });
        return;
      }
    }

    setState(() {
      _selectedTimeSlot = _morningSlots.isNotEmpty
          ? _morningSlots[0]
          : (_afternoonSlots.isNotEmpty ? _afternoonSlots[0] : '10:30 AM');
    });
  }

  @override
  void initState() {
    super.initState();
    _filterTimeSlots();
    _generateUpcomingWeekdays();
    _fetchTutorBookings();
    _fetchUserTierAndBookings();
    _goalsController.addListener(() {
      setState(() {
        _goalsCharCount = _goalsController.text.length;
      });
    });
  }

  Future<void> _fetchUserTierAndBookings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final tier = await MockData.getSubscriptionTier(user.email!);
      final bookingsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('learnerEmail', isEqualTo: user.email!.toLowerCase())
          .where('status', whereIn: ['Pending', 'Confirmed'])
          .get();
      
      if (mounted) {
        setState(() {
          _userTier = tier;
          _activeBookingCount = bookingsSnapshot.docs.length;
        });
      }
    }
  }

  @override
  void dispose() {
    _goalsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String tutorName = widget.tutor['name'] ?? 'Peer Tutor';
    final String firstLetter = tutorName.isNotEmpty
        ? tutorName[0].toUpperCase()
        : 'T';

    // Dynamic price calculation matching screenshots: hourly tutor price + 25 fee
    final dynamic priceRaw = widget.tutor['price'];
    final double hourlyRate;
    if (priceRaw is num) {
      hourlyRate = priceRaw.toDouble();
    } else if (priceRaw is String) {
      hourlyRate = double.tryParse(priceRaw) ?? 450.0;
    } else {
      hourlyRate = 450.0;
    }
    const double serviceFee = 0.00;
    final double totalAmount = (hourlyRate * _selectedHours);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: const CustomAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tutor Profile Card Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFEEEFF0),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: AppTheme.primaryRed
                                    .withOpacity(0.1),
                                backgroundImage:
                                    (widget.tutor['avatar'] != null ||
                                        widget.tutor['avatarUrl'] != null)
                                    ? NetworkImage(
                                        widget.tutor['avatar'] ??
                                            widget.tutor['avatarUrl'],
                                      )
                                    : null,
                                child:
                                    (widget.tutor['avatar'] == null &&
                                        widget.tutor['avatarUrl'] == null)
                                    ? Text(
                                        firstLetter,
                                        style: GoogleFonts.manrope(
                                          color: AppTheme.primaryRed,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 22,
                                        ),
                                      )
                                    : null,
                                onBackgroundImageError:
                                    (exception, stackTrace) {},
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
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 10,
                                  ),
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
                                  widget.tutor['name'] ?? 'Peer Tutor',
                                  style: GoogleFonts.manrope(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1A1C1E),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.tutor['subject'] ??
                                      'Untitled Tutoring Service',
                                  style: GoogleFonts.manrope(
                                    fontSize: 13,
                                    color: AppTheme.primaryRed,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: Color(0xFFFBB03B),
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      (widget.tutor['rating'] ?? 5.0)
                                          .toString(),
                                      style: GoogleFonts.manrope(
                                        color: const Color(0xFF1A1C1E),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      widget.tutor['reviews'] != null &&
                                              widget.tutor['reviews'] > 0
                                          ? '(${widget.tutor['reviews']} reviews)'
                                          : '(New)',
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
                              _currentMonthYear.isNotEmpty
                                  ? _currentMonthYear
                                  : 'May 2024',
                              style: GoogleFonts.manrope(
                                color: AppTheme.primaryRed,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              LucideIcons.calendar,
                              color: AppTheme.primaryRed,
                              size: 16,
                            ),
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
                              _selectFirstAvailableSlot();
                            },
                            child: Container(
                              width: 58,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primaryRed
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.primaryRed
                                      : const Color(0xFFEEEFF0),
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
                                      color: isSelected
                                          ? Colors.white.withOpacity(0.8)
                                          : const Color(0xFF7A7C80),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    date['num']!,
                                    style: GoogleFonts.manrope(
                                      fontSize: 16,
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFF1A1C1E),
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
                    if (_morningSlots.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.sun,
                            color: Color(0xFF7A7C80),
                            size: 16,
                          ),
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
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _morningSlots.map((slot) {
                          final isSelected = _selectedTimeSlot == slot;
                          final dateNum = _dates.isNotEmpty
                              ? _dates[_selectedDateIndex]['num'] ?? '1'
                              : '1';
                          final isDisabled = isSlotDisabled(dateNum, slot);
                          return GestureDetector(
                            onTap: isDisabled
                                ? null
                                : () {
                                    setState(() {
                                      _selectedTimeSlot = slot;
                                    });
                                  },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isDisabled
                                    ? const Color(0xFFE9ECEF).withOpacity(0.5)
                                    : (isSelected
                                          ? AppTheme.primaryRed
                                          : Colors.white),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isDisabled
                                      ? const Color(0xFFE9ECEF)
                                      : (isSelected
                                            ? AppTheme.primaryRed
                                            : const Color(0xFFEEEFF0)),
                                ),
                              ),
                              child: Text(
                                slot,
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDisabled
                                      ? const Color(0xFFADB5BD)
                                      : (isSelected
                                            ? Colors.white
                                            : const Color(0xFF495057)),
                                  decoration: isDisabled
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Afternoon slots section
                    if (_afternoonSlots.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.sun,
                            color: Color(0xFF7A7C80),
                            size: 16,
                          ),
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
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _afternoonSlots.map((slot) {
                          final isSelected = _selectedTimeSlot == slot;
                          final dateNum = _dates.isNotEmpty
                              ? _dates[_selectedDateIndex]['num'] ?? '1'
                              : '1';
                          final isDisabled = isSlotDisabled(dateNum, slot);
                          return GestureDetector(
                            onTap: isDisabled
                                ? null
                                : () {
                                    setState(() {
                                      _selectedTimeSlot = slot;
                                    });
                                  },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isDisabled
                                    ? const Color(0xFFE9ECEF).withOpacity(0.5)
                                    : (isSelected
                                          ? AppTheme.primaryRed
                                          : Colors.white),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isDisabled
                                      ? const Color(0xFFE9ECEF)
                                      : (isSelected
                                            ? AppTheme.primaryRed
                                            : const Color(0xFFEEEFF0)),
                                ),
                              ),
                              child: Text(
                                slot,
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDisabled
                                      ? const Color(0xFFADB5BD)
                                      : (isSelected
                                            ? Colors.white
                                            : const Color(0xFF495057)),
                                  decoration: isDisabled
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Select Duration
                    Text(
                      'Select Duration',
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A1C1E),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFEEEFF0), width: 1.5),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedHours,
                          isExpanded: true,
                          icon: const Icon(LucideIcons.chevronDown, size: 20, color: Color(0xFF7A7C80)),
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A1C1E),
                          ),
                          items: [1, 2, 3, 4, 5].map((hour) {
                            return DropdownMenuItem<int>(
                              value: hour,
                              child: Text('$hour ${hour == 1 ? 'Hour' : 'Hours'}'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedHours = val;
                              });
                            }
                          },
                        ),
                      ),
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
                        hintText:
                            'E.g. I need help with integration by parts and solving differential equations...',
                        hintStyle: GoogleFonts.manrope(
                          color: const Color(0xFFADB5BD),
                          fontSize: 12,
                        ),
                        counterText: '',
                        fillColor: Colors.white,
                        filled: true,
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: AppTheme.primaryRed,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Color(0xFFEEEFF0),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        color: const Color(0xFF495057),
                      ),
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
                                'Rate ($_selectedHours ${_selectedHours == 1 ? 'hour' : 'hours'})',
                                style: GoogleFonts.manrope(
                                  color: const Color(0xFF495057),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '₱${(hourlyRate * _selectedHours).toStringAsFixed(2)}',
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
                    final limit = MockData.getBookingLimit(_userTier);
                    if (_activeBookingCount >= limit) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'You have reached your limit of $limit active bookings. Upgrade to Learner Lite for more!',
                          ),
                          backgroundColor: AppTheme.secondaryGold,
                          action: SnackBarAction(
                            label: 'UPGRADE',
                            textColor: Colors.white,
                            onPressed: () {},
                          ),
                        ),
                      );
                      return;
                    }

                    final selectedDateMap = _dates[_selectedDateIndex];
                    final dateStr =
                        '${selectedDateMap['month']} ${selectedDateMap['num']}, ${selectedDateMap['year']}';
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ConfirmPaymentScreen(
                          tutorName: widget.tutor['name'] ?? 'Gabriel Reyes',
                          tutorEmail: widget.tutor['tutorEmail'] ?? widget.tutor['email'],
                          subjectName:
                              widget.tutor['subject'] ??
                              'Untitled Tutoring Service',
                          dateStr: dateStr,
                          timeSlot: _selectedTimeSlot,
                          totalAmount: totalAmount,
                          duration: _selectedHours,
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

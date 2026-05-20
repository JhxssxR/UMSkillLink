import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/app_theme.dart';
import '../../models/mock_data.dart';
import '../../widgets/student_layout.dart';
import '../../components/custom_app_bar.dart';
import '../../services/notification_service.dart';

class ConfirmPaymentScreen extends StatefulWidget {
  final String tutorName;
  final String? tutorEmail;
  final String subjectName;
  final String dateStr;
  final String timeSlot;
  final double totalAmount;
  final int duration;

  const ConfirmPaymentScreen({
    super.key,
    required this.tutorName,
    this.tutorEmail,
    required this.subjectName,
    required this.dateStr,
    required this.timeSlot,
    required this.totalAmount,
    this.duration = 1,
  });

  @override
  State<ConfirmPaymentScreen> createState() => _ConfirmPaymentScreenState();
}

class _ConfirmPaymentScreenState extends State<ConfirmPaymentScreen> {
  String _selectedMethodId = ''; // ID of selected payment method in Firestore
  bool _initializedSelection = false;

  void _processPayment() {
    if (_selectedMethodId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please link and select a payment method before checking out.',
          ),
          backgroundColor: AppTheme.primaryRed,
        ),
      );
      return;
    }

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

      final String learnerName = FirebaseAuth.instance.currentUser?.displayName ?? (FirebaseAuth.instance.currentUser?.email?.split('@')[0] ?? 'Learner');

      // Insert the newly confirmed session into MockData bookings dynamically!
      String imagePath =
          'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100';
      if (widget.tutorName.contains('Sarah')) {
        imagePath = 'assets/images/tutor_sarah.png';
      } else if (widget.tutorName.contains('Aris')) {
        imagePath = 'assets/images/tutor_aris.png';
      } else if (widget.tutorName.contains('Marcus')) {
        imagePath = 'assets/images/tutor_marcus.png';
      } else if (widget.tutorName.contains('Elena')) {
        imagePath =
            'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150';
      } else if (widget.tutorName.contains('Maria')) {
        imagePath =
            'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150';
      } else if (widget.tutorName.contains('Marco')) {
        imagePath =
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150';
      }

      final String bookingId = DateTime.now().millisecondsSinceEpoch.toString();

      final String studentEmail =
          (FirebaseAuth.instance.currentUser?.email ?? 'anonymous').toLowerCase();
      final String tutorEmail =
          (widget.tutorEmail ??
          (() {
            if (widget.tutorName.contains('Sarah')) {
              return 'tutor_sarah@umindanao.edu.ph';
            } else if (widget.tutorName.contains('Aris')) {
              return 'tutor_aris@umindanao.edu.ph';
            } else if (widget.tutorName.contains('Marcus')) {
              return 'tutor_marcus@umindanao.edu.ph';
            } else if (widget.tutorName.contains('Elena')) {
              return 'tutor_elena@umindanao.edu.ph';
            } else if (widget.tutorName.contains('Maria')) {
              return 'tutor_maria@umindanao.edu.ph';
            } else if (widget.tutorName.contains('Marco')) {
              return 'tutor_marco@umindanao.edu.ph';
            } else {
              final slug = widget.tutorName.toLowerCase().replaceAll(' ', '_');
              return 'tutor_$slug@umindanao.edu.ph';
            }
          }())).toLowerCase();

      final Map<String, dynamic> newBooking = {
        'id': bookingId,
        'tutorName': widget.tutorName,
        'learnerName': learnerName,
        'subject': widget.subjectName,
        'time': '${widget.dateStr} • ${widget.timeSlot}',
        'isUpcoming': true,
        'status': 'Pending',
        'imagePath': imagePath,
        'price': widget.totalAmount,
        'studentEmail': studentEmail,
        'tutorEmail': tutorEmail,
        'duration': widget.duration,
      };

      final Map<String, dynamic> newRequest = {
        'id': bookingId,
        'learnerName': learnerName,
        'degree': 'Student',
        'subject': widget.subjectName,
        'time': widget.dateStr,
        'timeDetail': widget.timeSlot,
        'status': 'Pending',
        'price': widget.totalAmount,
        'avatar': FirebaseAuth.instance.currentUser?.photoURL ??
            'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100',
        'verified': true,
        'studentEmail': studentEmail,
        'tutorEmail': tutorEmail,
        'duration': widget.duration,
      };

      MockData.learnerBookings.insert(0, newBooking);
      MockData.tutorRequests.insert(0, newRequest);

      MockData.syncBookingAdded(newBooking);
      MockData.syncTutorRequestAdded(newRequest);

      // Fetch tutor's commission rate before logging transaction
      FirebaseFirestore.instance.collection('users').doc(tutorEmail).get().then((tutorDoc) {
        double commissionRate = 0.05; // Default 5%
        if (tutorDoc.exists) {
          final data = tutorDoc.data() as Map<String, dynamic>;
          if (data['subscriptionTier'] == 'Tutor Pro') {
            commissionRate = 0.03; // 3% for Pro
          }
        }

        // Log Booking Commission to Transactions for Admin Revenue tracking
        FirebaseFirestore.instance.collection('transactions').add({
          'user': studentEmail,
          'amount': widget.totalAmount * commissionRate,
          'type': 'Booking Commission',
          'status': 'Completed',
          'date': FieldValue.serverTimestamp(),
          'tutorEmail': tutorEmail,
        });
      });

      // Trigger Real-Time Notifications using Central NotificationService
      NotificationService.sendNotification(
        studentEmail,
        'Payment Confirmed! 💳',
        'Your payment of ₱${widget.totalAmount.toStringAsFixed(2)} for ${widget.subjectName} has been processed successfully.',
        'payment_confirmed',
      );

      NotificationService.sendNotification(
        studentEmail,
        'Booking Created! 📅',
        'Your session request for ${widget.subjectName} with ${widget.tutorName} on ${widget.dateStr} at ${widget.timeSlot} is now pending approval.',
        'booking_created',
      );

      NotificationService.sendNotification(
        tutorEmail,
        'New Booking Request! 🔔',
        '$learnerName has requested a session for ${widget.subjectName} on ${widget.dateStr} at ${widget.timeSlot}.',
        'booking_request',
      );

      // Show Payment Success Modal
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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
                        builder: (context) =>
                            const StudentLayout(initialIndex: 1),
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

  void _showAddPaymentMethodSheet() {
    String selectedProvider = 'GCash';
    final TextEditingController numberController = TextEditingController();
    bool setAsDefault = true;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Link Payment Method',
                          style: GoogleFonts.manrope(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.neutralColor,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.x, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Select Provider',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setModalState(() {
                                selectedProvider = 'GCash';
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: selectedProvider == 'GCash'
                                    ? const Color(0xFF007DFE)
                                    : Colors.white,
                                border: Border.all(
                                  color: selectedProvider == 'GCash'
                                      ? const Color(0xFF005CFF)
                                      : Colors.grey.shade300,
                                  width: 2.5,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: selectedProvider == 'GCash'
                                    ? [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF007DFE,
                                          ).withOpacity(0.3),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: selectedProvider == 'GCash'
                                          ? Colors.white
                                          : const Color(0xFF007DFE),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        'G',
                                        style: GoogleFonts.outfit(
                                          color: selectedProvider == 'GCash'
                                              ? const Color(0xFF007DFE)
                                              : Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'GCash',
                                    style: GoogleFonts.manrope(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: selectedProvider == 'GCash'
                                          ? Colors.white
                                          : const Color(0xFF007DFE),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setModalState(() {
                                selectedProvider = 'Maya';
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: selectedProvider == 'Maya'
                                    ? const Color(0xFF0C1013)
                                    : Colors.white,
                                border: Border.all(
                                  color: selectedProvider == 'Maya'
                                      ? const Color(0xFF00F59B)
                                      : Colors.grey.shade300,
                                  width: 2.5,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: selectedProvider == 'Maya'
                                    ? [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF00F59B,
                                          ).withOpacity(0.2),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: selectedProvider == 'Maya'
                                          ? const Color(0xFF1E293B)
                                          : const Color(0xFFF1F3F5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        'm',
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFF00F59B),
                                          fontWeight: FontWeight.w900,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'maya',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                      letterSpacing: -0.5,
                                      color: selectedProvider == 'Maya'
                                          ? const Color(0xFF00F59B)
                                          : const Color(0xFF0C1013),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Mobile Number',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: numberController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: 'e.g., 09171234567',
                        hintStyle: GoogleFonts.manrope(
                          color: Colors.grey.shade400,
                        ),
                        prefixIcon: const Icon(LucideIcons.phone, size: 18),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryRed,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter mobile number';
                        }
                        final clean = value.replaceAll(RegExp(r'\D'), '');
                        if (clean.length != 11 || !clean.startsWith('09')) {
                          return 'Must be an 11-digit number starting with 09';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Set as Default Method',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        Switch(
                          value: setAsDefault,
                          activeColor: AppTheme.primaryRed,
                          onChanged: (val) {
                            setModalState(() {
                              setAsDefault = val;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (formKey.currentState?.validate() ?? false) {
                            final number = numberController.text.trim();
                            Navigator.pop(context);
                            await _addPaymentMethod(
                              selectedProvider,
                              number,
                              setAsDefault,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Link Account',
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _addPaymentMethod(
    String provider,
    String number,
    bool isDefault,
  ) async {
    final email = FirebaseAuth.instance.currentUser?.email ?? 'anonymous';
    try {
      final ref = FirebaseFirestore.instance
          .collection('users')
          .doc(email)
          .collection('payment_methods');
      final existingDocs = await ref.get();
      final bool forceDefault = existingDocs.docs.isEmpty || isDefault;

      final batch = FirebaseFirestore.instance.batch();

      if (forceDefault) {
        for (var doc in existingDocs.docs) {
          batch.update(doc.reference, {'isPrimary': false});
        }
      }

      final newDocRef = ref.doc();
      batch.set(newDocRef, {
        'id': newDocRef.id,
        'type': provider,
        'number': number,
        'isPrimary': forceDefault,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      setState(() {
        _selectedMethodId = newDocRef.id;
        _initializedSelection = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Linked $provider account successfully!'),
            backgroundColor: const Color(0xFF137333),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error linking payment method: $e');
    }
  }

  String _maskNumber(String raw) {
    if (raw.length < 7) return raw;
    final prefix = raw.substring(0, 4);
    final suffix = raw.substring(raw.length - 3);
    return '$prefix • • • $suffix';
  }

  Widget _buildEmptyPaymentMethodsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryRed.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Icon(
            LucideIcons.alertTriangle,
            color: AppTheme.primaryRed.withOpacity(0.8),
            size: 36,
          ),
          const SizedBox(height: 12),
          Text(
            'No Payment Methods Linked',
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.neutralColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'You need to link a GCash or Maya account before you can proceed with checkout.',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showAddPaymentMethodSheet,
              icon: const Icon(LucideIcons.plus, size: 16),
              label: const Text('Link GCash or Maya Account'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRed,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: CustomAppBar(
        title: 'Confirm Payment',
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.user, color: Color(0xFF7A7C80)),
            onPressed: () {},
          ),
        ],
      ),
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
                    // Service Summary Card
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFFBB03B,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      LucideIcons.award,
                                      color: Color(0xFFFBB03B),
                                      size: 10,
                                    ),
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
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.grey.shade300,
                                backgroundImage: const NetworkImage(
                                  'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100',
                                ),
                                onBackgroundImageError:
                                    (exception, stackTrace) {},
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
                                    const Icon(
                                      LucideIcons.calendar,
                                      color: AppTheme.primaryRed,
                                      size: 16,
                                    ),
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
                                    const Icon(
                                      LucideIcons.clock,
                                      color: AppTheme.primaryRed,
                                      size: 16,
                                    ),
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
                        GestureDetector(
                          onTap: _showAddPaymentMethodSheet,
                          child: Text(
                            'Add New',
                            style: GoogleFonts.manrope(
                              color: AppTheme.primaryRed,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // StreamBuilder for linked GCash/Maya accounts
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(
                            FirebaseAuth.instance.currentUser?.email ??
                                'anonymous',
                          )
                          .collection('payment_methods')
                          .orderBy('createdAt', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.primaryRed,
                                ),
                              ),
                            ),
                          );
                        }

                        final docs = snapshot.data?.docs ?? [];
                        final methods = docs.map((doc) => doc.data()).toList();

                        // Sort so primary is on top
                        methods.sort((a, b) {
                          final aPrimary = a['isPrimary'] == true ? 1 : 0;
                          final bPrimary = b['isPrimary'] == true ? 1 : 0;
                          return bPrimary.compareTo(aPrimary);
                        });

                        if (methods.isEmpty) {
                          return _buildEmptyPaymentMethodsCard();
                        }

                        // Initialize selection if not set
                        if (!_initializedSelection && methods.isNotEmpty) {
                          final primaryIndex = methods.indexWhere(
                            (m) => m['isPrimary'] == true,
                          );
                          final defaultMethod = primaryIndex != -1
                              ? methods[primaryIndex]
                              : methods[0];
                          _selectedMethodId = defaultMethod['id'] ?? '';
                          _initializedSelection = true;
                        }

                        return Column(
                          children: methods.map((method) {
                            final mId = method['id'] ?? '';
                            final mType = method['type'] ?? 'GCash';
                            final isGCash = mType == 'GCash';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildPaymentMethodItem(
                                methodId: mId,
                                title: mType,
                                sub: _maskNumber(method['number'] ?? ''),
                                iconData: isGCash
                                    ? LucideIcons.wallet
                                    : LucideIcons.phone,
                                iconBgColor: isGCash
                                    ? const Color(0xFFE8F0FE)
                                    : const Color(0xFFE6F4EA),
                                iconColor: isGCash
                                    ? const Color(0xFF1A73E8)
                                    : const Color(0xFF137333),
                              ),
                            );
                          }).toList(),
                        );
                      },
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
                          const Icon(
                            LucideIcons.shieldAlert,
                            color: Color(0xFFFBB03B),
                            size: 18,
                          ),
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
    required String methodId,
    required String title,
    required String sub,
    required IconData iconData,
    required Color iconBgColor,
    required Color iconColor,
    bool hasStudentTag = false,
  }) {
    final isSelected = _selectedMethodId == methodId;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethodId = methodId;
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
            _buildBrandLogoBadge(title),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F0FE),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Student Rate',
                            style: GoogleFonts.manrope(
                              color: const Color(0xFF1A73E8),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sub,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: const Color(0xFF7A7C80),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Selection indicator
            Container(
              height: 20,
              width: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryRed
                      : const Color(0xFFCED4DA),
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

  Widget _buildBrandLogoBadge(String type) {
    final isGCash = type.toLowerCase() == 'gcash';
    if (isGCash) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF007DFE),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    'G',
                    style: TextStyle(
                      color: Color(0xFF007DFE),
                      fontWeight: FontWeight.w900,
                      fontSize: 9,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'GCash',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 7.5,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF0C1013),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1E293B), width: 1),
        ),
        child: Center(
          child: Text(
            'maya',
            style: GoogleFonts.outfit(
              color: const Color(0xFF00F59B),
              fontWeight: FontWeight.w800,
              fontSize: 13,
              letterSpacing: -0.5,
            ),
          ),
        ),
      );
    }
  }
}

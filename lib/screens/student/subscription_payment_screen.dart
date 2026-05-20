import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/app_theme.dart';
import '../../components/custom_app_bar.dart';
import '../../services/notification_service.dart';

class SubscriptionPaymentScreen extends StatefulWidget {
  final String planName;
  final double amount;
  final bool isTutor;

  const SubscriptionPaymentScreen({
    super.key,
    required this.planName,
    required this.amount,
    required this.isTutor,
  });

  @override
  State<SubscriptionPaymentScreen> createState() => _SubscriptionPaymentScreenState();
}

class _SubscriptionPaymentScreenState extends State<SubscriptionPaymentScreen> {
  String _selectedMethodId = '';
  bool _initializedSelection = false;

  void _processSubscription() {
    if (_selectedMethodId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please link and select a payment method.'),
          backgroundColor: AppTheme.primaryRed,
        ),
      );
      return;
    }

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
            const CircularProgressIndicator(color: AppTheme.primaryRed),
            const SizedBox(height: 24),
            Text(
              'Activating ${widget.planName}...',
              style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Processing secure payment',
              style: GoogleFonts.manrope(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(milliseconds: 2000), () async {
      if (!mounted) return;
      
      final user = FirebaseAuth.instance.currentUser;
      final email = user?.email?.toLowerCase() ?? '';
      
      try {
        final now = DateTime.now();
        final expiry = DateTime(now.year, now.month + 1, now.day);

        final batch = FirebaseFirestore.instance.batch();

        // 1. Update User Document
        batch.set(
          FirebaseFirestore.instance.collection('users').doc(email),
          {
            'isSubscribed': true,
            'subscriptionTier': widget.planName,
            'subscriptionPlan': widget.planName,
            'commissionRate': widget.planName == 'Tutor Pro' ? 0.03 : 0.05,
          },
          SetOptions(merge: true),
        );

        // 2. Add to Subscriptions Collection
        final subRef = FirebaseFirestore.instance.collection('subscriptions').doc();
        batch.set(subRef, {
          'id': subRef.id,
          'userName': user?.displayName ?? email.split('@')[0].toUpperCase(),
          'userEmail': email,
          'tutorName': user?.displayName ?? email.split('@')[0].toUpperCase(),
          'tutorEmail': email,
          'plan': widget.planName,
          'amount': widget.amount,
          'status': 'Active',
          'billingCycle': 'Monthly',
          'nextBilling': Timestamp.fromDate(expiry),
          'subscribedAt': FieldValue.serverTimestamp(),
          'paymentMethodId': _selectedMethodId,
        });

        // 3. Log to Transactions
        final transRef = FirebaseFirestore.instance.collection('transactions').doc();
        batch.set(transRef, {
          'id': transRef.id,
          'user': email,
          'amount': widget.amount,
          'type': 'Subscription: ${widget.planName}',
          'status': 'Completed',
          'date': FieldValue.serverTimestamp(),
        });

        await batch.commit();

        // Notify Admin about the new subscription
        await NotificationService.sendAdminNotification(
          'New Subscription 💰',
          '${user?.displayName ?? email} has subscribed to ${widget.planName} (₱${widget.amount.toStringAsFixed(2)}).',
          'subscription_upgrade',
        );

        if (mounted) {
          Navigator.pop(context); // Pop loading
          _showSuccessDialog();
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Pop loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Activation failed: $e'), backgroundColor: AppTheme.primaryRed),
          );
        }
      }
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
    final email = FirebaseAuth.instance.currentUser?.email?.toLowerCase() ?? 'anonymous';
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

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 24),
            Text(
              'Subscription Active!',
              style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'You have successfully upgraded to ${widget.planName}. Enjoy your new benefits!',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Pop dialog
                  Navigator.pop(context); // Pop payment screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRed,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Great, thanks!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.helpCircle, color: AppTheme.primaryRed),
                const SizedBox(width: 12),
                Text(
                  'Subscription Help',
                  style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'How does it work?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Your subscription is billed monthly. You can cancel anytime from your profile settings.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 16),
            const Text(
              'Secure Payments',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'All transactions are processed through secure GCash or Maya portals with UM SkillLink protection.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryRed)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: CustomAppBar(
        title: 'Payment Details',
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.helpCircle, color: Color(0xFF7A7C80)),
            onPressed: _showHelpModal,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Plan Summary
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEEEFF0)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Selected Plan',
                              style: GoogleFonts.manrope(color: Colors.grey, fontSize: 12),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryRed.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                widget.planName,
                                style: GoogleFonts.manrope(
                                  color: AppTheme.primaryRed,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total to Pay',
                              style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '₱${widget.amount.toStringAsFixed(2)}',
                              style: GoogleFonts.manrope(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primaryRed,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  Text(
                    'Select Payment Method',
                    style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser?.email?.toLowerCase() ?? 'anonymous')
                        .collection('payment_methods')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      
                      final methods = snapshot.data!.docs;
                      if (methods.isEmpty) {
                        return _buildEmptyState();
                      }

                      if (!_initializedSelection) {
                        _selectedMethodId = methods.first.id;
                        _initializedSelection = true;
                      }

                      return Column(
                        children: methods.map((doc) => _buildMethodItem(doc.data())).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          Container(
            padding: const EdgeInsets.all(24),
            color: Colors.white,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _processSubscription,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRed,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Pay & Activate Now',
                  style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryRed.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const Icon(LucideIcons.creditCard, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No payment methods linked', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'Link your GCash or Maya account to proceed.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _showAddPaymentMethodSheet,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed.withOpacity(0.1),
              foregroundColor: AppTheme.primaryRed,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 24),
            ),
            child: const Text('Link Account', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodItem(Map<String, dynamic> method) {
    final bool isSelected = _selectedMethodId == method['id'];
    final bool isGCash = method['type'] == 'GCash';
    
    return GestureDetector(
      onTap: () => setState(() => _selectedMethodId = method['id']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppTheme.primaryRed : const Color(0xFFEEEFF0), width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            _buildBrandLogo(method['type']),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(method['type'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '${method['number'].substring(0, 4)} •••• ${method['number'].substring(7)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: AppTheme.primaryRed),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandLogo(String type) {
    final isGCash = type.toLowerCase() == 'gcash';
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isGCash ? const Color(0xFF007DFE) : const Color(0xFF0C1013),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: isGCash 
          ? const Text('G', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
          : Text('maya', style: GoogleFonts.outfit(color: const Color(0xFF00F59B), fontSize: 10, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

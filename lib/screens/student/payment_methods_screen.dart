import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/app_theme.dart';
import '../../components/custom_app_bar.dart';

class PaymentMethodsScreen extends StatefulWidget {
  final bool isNewAccount;

  const PaymentMethodsScreen({super.key, this.isNewAccount = false});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get _userEmail => _auth.currentUser?.email ?? 'anonymous';

  // Open the Add Payment Method Bottom Sheet
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

  // Add the payment method to Firestore
  Future<void> _addPaymentMethod(
    String provider,
    String number,
    bool isDefault,
  ) async {
    try {
      final ref = _firestore
          .collection('users')
          .doc(_userEmail)
          .collection('payment_methods');
      final existingDocs = await ref.get();
      final bool forceDefault = existingDocs.docs.isEmpty || isDefault;

      final batch = _firestore.batch();

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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.checkCircle2, color: Colors.white),
                const SizedBox(width: 8),
                Text('Linked $provider account successfully!'),
              ],
            ),
            backgroundColor: const Color(0xFF137333),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error linking payment method: $e');
    }
  }

  // Make the payment method default in Firestore
  Future<void> _makePrimary(String methodId) async {
    try {
      final ref = _firestore
          .collection('users')
          .doc(_userEmail)
          .collection('payment_methods');
      final allDocs = await ref.get();
      final batch = _firestore.batch();

      for (var doc in allDocs.docs) {
        batch.update(doc.reference, {'isPrimary': doc.id == methodId});
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Default payment method updated!'),
            backgroundColor: const Color(0xFF137333),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error making primary: $e');
    }
  }

  // Remove the payment method from Firestore
  Future<void> _removePaymentMethod(String methodId, String type) async {
    try {
      final ref = _firestore
          .collection('users')
          .doc(_userEmail)
          .collection('payment_methods');
      final docToDel = await ref.doc(methodId).get();
      final bool wasPrimary = docToDel.data()?['isPrimary'] ?? false;

      await ref.doc(methodId).delete();

      if (wasPrimary) {
        final remaining = await ref.get();
        if (remaining.docs.isNotEmpty) {
          await ref.doc(remaining.docs.first.id).update({'isPrimary': true});
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed $type account.'),
            backgroundColor: AppTheme.primaryRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error removing payment method: $e');
    }
  }

  // Show bottom sheet with manage options
  void _showActionsSheet(Map<String, dynamic> method) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Manage Account',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.neutralColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${method['type']} • ${_maskNumber(method['number'])}',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),
              if (!(method['isPrimary'] ?? false)) ...[
                ListTile(
                  leading: const Icon(
                    LucideIcons.check,
                    color: Color(0xFF137333),
                  ),
                  title: Text(
                    'Make Default/Primary',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF137333),
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await _makePrimary(method['id']);
                  },
                ),
                const Divider(height: 1),
              ],
              ListTile(
                leading: const Icon(
                  LucideIcons.trash2,
                  color: AppTheme.primaryRed,
                ),
                title: Text(
                  'Remove Account',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryRed,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _removePaymentMethod(method['id'], method['type']);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  String _maskNumber(String number) {
    if (number.length < 7) return number;
    return '${number.substring(0, 4)} • • • ${number.substring(number.length - 3)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: const CustomAppBar(title: 'Payment Methods', centerTitle: false),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestore
            .collection('users')
            .doc(_userEmail)
            .collection('payment_methods')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryRed),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          final methods = docs.map((doc) => doc.data()).toList();

          // Sort so primary/default payment method is always on top
          methods.sort((a, b) {
            final aPrimary = a['isPrimary'] == true ? 1 : 0;
            final bPrimary = b['isPrimary'] == true ? 1 : 0;
            return bPrimary.compareTo(aPrimary);
          });

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Linked Accounts',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.neutralColor,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _showAddPaymentMethodSheet,
                    icon: const Icon(
                      LucideIcons.plus,
                      size: 16,
                      color: AppTheme.primaryRed,
                    ),
                    label: Text(
                      'Add New',
                      style: GoogleFonts.manrope(
                        color: AppTheme.primaryRed,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (methods.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFEEEFF0)),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        LucideIcons.creditCard,
                        size: 48,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No linked payment methods.',
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Add GCash or PayMaya to facilitate swift checkout.',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton.icon(
                        onPressed: _showAddPaymentMethodSheet,
                        icon: const Icon(LucideIcons.plus, size: 16),
                        label: const Text('Link Account'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryRed,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...methods.map((method) {
                  final isGCash = method['type'] == 'GCash';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildPaymentMethodCard(
                      method: method,
                      title: method['type'] ?? 'Unknown',
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
                      isPrimary: method['isPrimary'] == true,
                    ),
                  );
                }),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEEEFF0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryGold.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.shieldCheck,
                        color: AppTheme.secondaryGold,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Secure Payments',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.neutralColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'UM SkillLink ensures your transactions are safe and encrypted.',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPaymentMethodCard({
    required Map<String, dynamic> method,
    required String title,
    required String sub,
    required IconData iconData,
    required Color iconBgColor,
    required Color iconColor,
    bool isPrimary = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEFF0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildBrandLogoBadge(title),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1C1E),
                  ),
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
          if (isPrimary)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F4EA),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Default',
                style: GoogleFonts.manrope(
                  color: const Color(0xFF137333),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              LucideIcons.moreVertical,
              color: Colors.grey.shade400,
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => _showActionsSheet(method),
          ),
        ],
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

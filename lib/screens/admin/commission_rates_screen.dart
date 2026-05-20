import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/app_theme.dart';
import '../../core/demo_mode.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CommissionRatesScreen extends StatefulWidget {
  const CommissionRatesScreen({super.key});

  @override
  State<CommissionRatesScreen> createState() => _CommissionRatesScreenState();
}

class _CommissionRatesScreenState extends State<CommissionRatesScreen> {
  bool _isEditing = false;
  double _defaultRate = 5.0; // 5%

  final TextEditingController _rateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _rateController.text = _defaultRate.toString();
  }

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }

  void _saveRate() async {
    setState(() {
      _isEditing = false;
      _defaultRate = double.tryParse(_rateController.text) ?? _defaultRate;
    });

    if (!DemoMode.isActive) {
      // In a real app, save to a 'settings' collection
      await FirebaseFirestore.instance
          .collection('settings')
          .doc('commission')
          .set({
            'defaultRate': _defaultRate,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Commission rate updated successfully')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Commission rate updated (Demo Mode)')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header info
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRed.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.percent,
                    size: 32,
                    color: AppTheme.primaryRed,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Global Commission Rate',
                        style: GoogleFonts.manrope(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This percentage represents the platform fee deducted from every successful tutor booking transaction.',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          _isEditing
                              ? SizedBox(
                                  width: 120,
                                  child: TextField(
                                    controller: _rateController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    style: GoogleFonts.manrope(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryRed,
                                    ),
                                    decoration: InputDecoration(
                                      suffixText: '%',
                                      suffixStyle: GoogleFonts.manrope(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                      ),
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                )
                              : Text(
                                  '${_defaultRate.toStringAsFixed(1)}%',
                                  style: GoogleFonts.manrope(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryRed,
                                  ),
                                ),
                          const SizedBox(width: 32),
                          _isEditing
                              ? ElevatedButton.icon(
                                  onPressed: _saveRate,
                                  icon: const Icon(LucideIcons.save, size: 18),
                                  label: const Text('Save Changes'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                )
                              : ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _isEditing = true;
                                    });
                                  },
                                  icon: const Icon(LucideIcons.edit2, size: 18),
                                  label: const Text('Modify Rate'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryRed,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                          if (_isEditing) ...[
                            const SizedBox(width: 16),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isEditing = false;
                                  _rateController.text = _defaultRate
                                      .toString();
                                });
                              },
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.manrope(color: Colors.grey),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 32),

        Text(
          'Tier Exceptions',
          style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryGold.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.star, color: AppTheme.secondaryGold, size: 20),
                ),
                title: Text(
                  'Tutor Pro Tier',
                  style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Reduced platform fee for subscribed professional tutors.',
                  style: GoogleFonts.manrope(fontSize: 13),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '3.0%',
                    style: GoogleFonts.manrope(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.user, color: Colors.grey, size: 20),
                ),
                title: Text(
                  'Standard / Free Tier',
                  style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Default platform fee for all other users.',
                  style: GoogleFonts.manrope(fontSize: 13),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_defaultRate.toStringAsFixed(1)}%',
                    style: GoogleFonts.manrope(
                      color: AppTheme.primaryRed,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

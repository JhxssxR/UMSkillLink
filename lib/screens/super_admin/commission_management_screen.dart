import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/app_theme.dart';
import 'package:intl/intl.dart';

class CommissionManagementScreen extends StatefulWidget {
  const CommissionManagementScreen({super.key});

  @override
  State<CommissionManagementScreen> createState() => _CommissionManagementScreenState();
}

class _CommissionManagementScreenState extends State<CommissionManagementScreen> {
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '₱');

  void _showEditRuleDialog(String docId, Map<String, dynamic> ruleData) {
    final rateCtrl = TextEditingController(text: ruleData['rate'].toString());
    bool isActive = ruleData['isActive'] ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('Edit ${ruleData['title']}', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: rateCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Commission Rate (%)',
                    suffixText: '%',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: Text('Is Active', style: GoogleFonts.manrope(fontSize: 14)),
                  value: isActive,
                  onChanged: (val) => setDialogState(() => isActive = val),
                  activeColor: AppTheme.primaryRed,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: GoogleFonts.manrope(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () async {
                  final newRate = double.tryParse(rateCtrl.text) ?? ruleData['rate'];
                  await FirebaseFirestore.instance
                      .collection('settings')
                      .doc('commission_rules')
                      .collection('rules')
                      .doc(docId)
                      .update({
                    'rate': newRate,
                    'isActive': isActive,
                  });
                  
                  // If it's the base fee, also update settings/global/transactionFee for consistency
                  if (docId == 'base_fee') {
                    await FirebaseFirestore.instance
                        .collection('settings')
                        .doc('global')
                        .update({'transactionFee': newRate});
                  }

                  if (context.mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRed,
                  foregroundColor: Colors.white,
                ),
                child: Text('Save', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Platform Wide Commission',
          style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Monitor and manage transaction fees across the entire UMSkillLink ecosystem.',
          style: GoogleFonts.manrope(color: Colors.grey.shade600, fontSize: 14),
        ),
        const SizedBox(height: 32),

        // Stats Row with StreamBuilders
        Row(
          children: [
            // Total Revenue & Commission
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('bookings').snapshots(),
                builder: (context, bookingsSnapshot) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'tutor').snapshots(),
                    builder: (context, tutorsSnapshot) {
                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('settings')
                            .doc('commission_rules')
                            .collection('rules')
                            .snapshots(),
                        builder: (context, rulesSnapshot) {
                          double totalCommission = 0;
                          
                          if (bookingsSnapshot.hasData && tutorsSnapshot.hasData && rulesSnapshot.hasData) {
                            // 1. Map tutors to their subscription status
                            final tutorSubStatus = {
                              for (var doc in tutorsSnapshot.data!.docs)
                                (doc.data() as Map<String, dynamic>)['email']: (doc.data() as Map<String, dynamic>)['isSubscribed'] ?? false
                            };

                            // 2. Map rules to their rates
                            final rules = {
                              for (var doc in rulesSnapshot.data!.docs)
                                doc.id: (doc.data() as Map<String, dynamic>)['rate'] ?? 0.0
                            };

                            final baseRate = rules['base_fee']?.toDouble() ?? 5.0;
                            final premiumRate = rules['premium_fee']?.toDouble() ?? 3.0;

                            // 3. Calculate based on individual booking + tutor status
                            for (var doc in bookingsSnapshot.data!.docs) {
                              final data = doc.data() as Map<String, dynamic>;
                              final price = (data['price'] ?? 0).toDouble();
                              final tutorEmail = data['tutorEmail'];
                              
                              final isSubscribed = tutorSubStatus[tutorEmail] ?? false;
                              final appliedRate = isSubscribed ? premiumRate : baseRate;
                              
                              totalCommission += price * (appliedRate / 100);
                            }
                          }

                          return _buildStatCard(
                            'Total Commission Revenue',
                            _currencyFormat.format(totalCommission),
                            LucideIcons.trendingUp,
                            Colors.green,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(width: 24),
            // Current Base Rate
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('settings').doc('global').snapshots(),
                builder: (context, snapshot) {
                  double feeRate = 5.0;
                  if (snapshot.hasData && snapshot.data!.exists) {
                    feeRate = (snapshot.data!.get('transactionFee') ?? 5.0).toDouble();
                  }
                  return _buildStatCard(
                    'Current Base Rate',
                    '$feeRate%',
                    LucideIcons.percent,
                    AppTheme.primaryRed,
                  );
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),

        _buildSectionTitle('Active Commission Rules'),
        const SizedBox(height: 16),
        
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('settings')
              .doc('commission_rules')
              .collection('rules')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              _initializeDefaultRules();
              return const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed));
            }

            final rules = snapshot.data!.docs;

            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: rules.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final doc = rules[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return _buildCommissionItem(
                    doc.id,
                    data['title'] ?? 'Rule',
                    data['desc'] ?? '',
                    '${data['rate']}%',
                    data['isActive'] ?? false,
                    data,
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _initializeDefaultRules() async {
    final ref = FirebaseFirestore.instance.collection('settings').doc('commission_rules').collection('rules');
    final snapshot = await ref.get();
    if (snapshot.docs.isEmpty) {
      await ref.doc('base_fee').set({
        'title': 'Base Platform Fee',
        'desc': 'Applied to all successful peer tutor bookings.',
        'rate': 5.0,
        'isActive': true,
      });
      await ref.doc('premium_fee').set({
        'title': 'Premium Tutor Fee',
        'desc': 'Reduced fee for highly rated/subscribed tutors.',
        'rate': 3.0,
        'isActive': true,
      });
      await ref.doc('event_fee').set({
        'title': 'University Special Event',
        'desc': 'Special rate for campus-wide academic weeks.',
        'rate': 0.0,
        'isActive': false,
      });
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.manrope(color: Colors.grey.shade500, fontSize: 13),
              ),
              Text(
                value,
                style: GoogleFonts.manrope(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommissionItem(String docId, String title, String desc, String rate, bool isActive, Map<String, dynamic> data) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      onTap: () => _showEditRuleDialog(docId, data),
      title: Text(title, style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
      subtitle: Text(desc, style: GoogleFonts.manrope(fontSize: 12, color: Colors.grey.shade600)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isActive ? Colors.green.withOpacity(0.1) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              rate,
              style: GoogleFonts.manrope(
                color: isActive ? Colors.green : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Icon(LucideIcons.chevronRight, size: 18, color: Colors.grey),
        ],
      ),
    );
  }
}

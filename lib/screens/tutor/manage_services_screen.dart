import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/app_theme.dart';
import '../../components/tutor_app_bar.dart';

class ManageServicesScreen extends StatefulWidget {
  const ManageServicesScreen({super.key});

  @override
  State<ManageServicesScreen> createState() => _ManageServicesScreenState();
}

class _ManageServicesScreenState extends State<ManageServicesScreen> {
  void _showAddServiceDialog() {
    final titleCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Add New Service',
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(
                labelText: 'Service / Subject Title',
                labelStyle: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Hourly Rate (₱)',
                prefixText: '₱ ',
                labelStyle: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
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
              if (titleCtrl.text.trim().isEmpty || priceCtrl.text.trim().isEmpty) return;
              
              final email = FirebaseAuth.instance.currentUser?.email;
              if (email == null) return;
              
              final tutorQuery = await FirebaseFirestore.instance
                  .collection('users')
                  .where('email', isEqualTo: email)
                  .limit(1)
                  .get();
                  
              String tutorName = 'Tutor Name';
              String college = 'University of Mindanao';
              
              if (tutorQuery.docs.isNotEmpty) {
                final data = tutorQuery.docs.first.data();
                tutorName = data['name'] ?? '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
                if (tutorName.isEmpty) tutorName = 'Peer Tutor';
                college = data['college'] ?? college;
              }
              
              await FirebaseFirestore.instance.collection('services').add({
                'tutorEmail': email,
                'name': tutorName,
                'college': college,
                'title': titleCtrl.text.trim(),
                'subject': titleCtrl.text.trim(),
                'rate': int.tryParse(priceCtrl.text) ?? 250,
                'rating': 0.0,
                'reviews': 0,
                'completed': 0,
                'status': 'Active',
                'createdAt': FieldValue.serverTimestamp(),
              });
              
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Service added successfully.', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
                  backgroundColor: Colors.green.shade600,
                  behavior: SnackBarBehavior.floating,
                ));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              foregroundColor: Colors.white,
            ),
            child: Text('Add', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEditServiceDialog(String docId, Map<String, dynamic> currentSvc) {
    final titleCtrl = TextEditingController(text: currentSvc['title']);
    final priceCtrl = TextEditingController(text: currentSvc['rate'].toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Edit Service',
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(
                labelText: 'Service / Subject Title',
                labelStyle: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Hourly Rate (₱)',
                prefixText: '₱ ',
                labelStyle: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('services').doc(docId).delete();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Service removed.', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
                  backgroundColor: AppTheme.primaryRed,
                  behavior: SnackBarBehavior.floating,
                ));
              }
            },
            child: Text('Delete', style: GoogleFonts.manrope(color: AppTheme.primaryRed, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty || priceCtrl.text.trim().isEmpty) return;
              
              await FirebaseFirestore.instance.collection('services').doc(docId).update({
                'title': titleCtrl.text.trim(),
                'subject': titleCtrl.text.trim(),
                'rate': int.tryParse(priceCtrl.text) ?? currentSvc['rate'],
              });
              
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Service updated.', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
                  backgroundColor: Colors.green.shade600,
                  behavior: SnackBarBehavior.floating,
                ));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              foregroundColor: Colors.white,
            ),
            child: Text('Save', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? 'tutor@umindanao.edu.ph';
    
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const TutorAppBar(
        showBackButton: true,
        centerTitle: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('services')
            .where('tutorEmail', isEqualTo: email)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading services: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.briefcase, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No services yet',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + New Service to get started.',
                    style: GoogleFonts.manrope(fontSize: 13, color: Colors.grey.shade400),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final svc = docs[index].data() as Map<String, dynamic>;
              final docId = docs[index].id;
              return _buildServiceCard(docId, svc);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'manage_services_fab',
        onPressed: _showAddServiceDialog,
        backgroundColor: AppTheme.primaryRed,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: Text(
          'New Service',
          style: GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildServiceCard(String docId, Map<String, dynamic> svc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  svc['status'] ?? 'Active',
                  style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.edit3, size: 20, color: Colors.grey),
                onPressed: () => _showEditServiceDialog(docId, svc),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            svc['title'] ?? '',
            style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                svc['price'] ?? '',
                style: const TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              const Icon(Icons.star, color: AppTheme.secondaryGold, size: 16),
              const SizedBox(width: 4),
              Text(
                '${svc['rating'] ?? 5.0} (${svc['reviews'] ?? 0})',
                style: GoogleFonts.manrope(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

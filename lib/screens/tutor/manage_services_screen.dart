import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../../core/app_theme.dart';
import '../../components/tutor_app_bar.dart';

class ManageServicesScreen extends StatefulWidget {
  const ManageServicesScreen({super.key});

  @override
  State<ManageServicesScreen> createState() => _ManageServicesScreenState();
}

class _ManageServicesScreenState extends State<ManageServicesScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isSubscribed = false;

  @override
  void initState() {
    super.initState();
    _checkSubscription();
  }

  Future<void> _checkSubscription() async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(email).get();
      if (doc.exists && mounted) {
        setState(() {
          _isSubscribed = doc.data()?['isSubscribed'] ?? false;
        });
      }
    }
  }

  void _showSubscribeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(LucideIcons.sparkles, color: AppTheme.secondaryGold),
            const SizedBox(width: 10),
            Text(
              'Premium Feature',
              style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Promoting your services is a premium feature reserved for subscribed tutors.',
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),
            _buildBenefitItem(LucideIcons.trendingUp, 'Appear at the top of search results'),
            _buildBenefitItem(LucideIcons.eye, 'Get up to 5x more profile views'),
            _buildBenefitItem(LucideIcons.badgeCheck, 'Exclusive "Featured" badge'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Later',
              style: GoogleFonts.manrope(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final email = FirebaseAuth.instance.currentUser?.email;
              if (email != null) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(email)
                    .update({'isSubscribed': true});
                await _checkSubscription();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Subscription successful!', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
                      backgroundColor: Colors.green.shade600,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              foregroundColor: Colors.white,
            ),
            child: Text('Subscribe Now', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryRed),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _pickAndConvertImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800, // Resize to keep base64 string small
        maxHeight: 800,
        imageQuality: 70,
      );
      if (image == null) return null;

      final Uint8List bytes = await image.readAsBytes();
      final String base64String = base64Encode(bytes);
      // Return a Data URI so it can be used easily
      return 'data:image/jpeg;base64,$base64String';
    } catch (e) {
      debugPrint('Error picking/converting image: $e');
      return null;
    }
  }

  // Helper to build image widget from URL or Base64
  Widget _buildServiceImage(String imageUrl, {BoxFit fit = BoxFit.cover}) {
    if (imageUrl.startsWith('data:image')) {
      try {
        final String base64Data = imageUrl.split(',').last;
        return Image.memory(
          base64Decode(base64Data),
          fit: fit,
          errorBuilder: (context, error, stackTrace) => const Icon(LucideIcons.imageOff),
        );
      } catch (e) {
        return const Icon(LucideIcons.imageOff);
      }
    }
    return Image.network(
      imageUrl,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => const Icon(LucideIcons.imageOff),
    );
  }

  void _showAddServiceDialog() {
    final titleCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final objectiveCtrl = TextEditingController();
    String? uploadedImageUrl;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          bool isUploadingLocal = false;
          
          return AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Add New Service',
              style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      setModalState(() => isUploadingLocal = true);
                      final base64Image = await _pickAndConvertImage();
                      if (base64Image != null) {
                        setModalState(() {
                          uploadedImageUrl = base64Image;
                        });
                      }
                      setModalState(() => isUploadingLocal = false);
                    },
                    child: Container(
                      height: 140,
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200, width: 1.5),
                      ),
                      child: Stack(
                        children: [
                          if (uploadedImageUrl != null && uploadedImageUrl!.isNotEmpty)
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: _buildServiceImage(uploadedImageUrl!),
                              ),
                            )
                          else
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryRed.withOpacity(0.05),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(LucideIcons.imagePlus, color: AppTheme.primaryRed, size: 28),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Upload Service Cover',
                                    style: GoogleFonts.manrope(
                                      fontSize: 13,
                                      color: AppTheme.primaryRed,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Recommended: 1200x800',
                                    style: GoogleFonts.manrope(
                                      fontSize: 10,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (uploadedImageUrl != null && uploadedImageUrl!.isNotEmpty)
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(LucideIcons.camera, color: Colors.white, size: 12),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Change',
                                      style: GoogleFonts.manrope(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (isUploadingLocal)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
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
                      helperText: 'Allowed range: ₱150 - ₱300',
                      helperStyle: GoogleFonts.manrope(fontSize: 11, color: AppTheme.primaryRed, fontWeight: FontWeight.w600),
                      prefixText: '₱ ',
                      labelStyle: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: objectiveCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Service Objective',
                      hintText: 'Describe the goal of this service...',
                      hintStyle: GoogleFonts.manrope(fontSize: 13, color: Colors.grey.shade400),
                      labelStyle: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600),
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: GoogleFonts.manrope(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () async {
                  final String priceText = priceCtrl.text.trim();
                  if (titleCtrl.text.trim().isEmpty || priceText.isEmpty) return;
                  
                  final int? rate = int.tryParse(priceText);
                  if (rate == null || rate < 150 || rate > 300) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Hourly rate must be between ₱150 and ₱300.', 
                        style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
                      backgroundColor: AppTheme.primaryRed,
                      behavior: SnackBarBehavior.floating,
                    ));
                    return;
                  }
                  
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
                    'objective': objectiveCtrl.text.trim(),
                    'rate': int.tryParse(priceCtrl.text) ?? 250,
                    'price': priceCtrl.text.trim(),
                    'imageUrl': uploadedImageUrl,
                    'image': uploadedImageUrl,
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
          );
        },
      ),
    );
  }

  void _showEditServiceDialog(String docId, Map<String, dynamic> currentSvc) {
    final titleCtrl = TextEditingController(text: currentSvc['title'] ?? '');
    final rateValue = currentSvc['rate'];
    final priceCtrl = TextEditingController(text: rateValue != null ? rateValue.toString() : '');
    final objectiveCtrl = TextEditingController(text: currentSvc['objective'] ?? '');
    String? uploadedImageUrl = currentSvc['imageUrl'] ?? currentSvc['image'];
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          bool isUploadingLocal = false;
          
          return AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Edit Service',
              style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      setModalState(() => isUploadingLocal = true);
                      final base64Image = await _pickAndConvertImage();
                      if (base64Image != null) {
                        setModalState(() {
                          uploadedImageUrl = base64Image;
                        });
                      }
                      setModalState(() => isUploadingLocal = false);
                    },
                    child: Container(
                      height: 140,
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200, width: 1.5),
                      ),
                      child: Stack(
                        children: [
                          if (uploadedImageUrl != null && uploadedImageUrl!.isNotEmpty)
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: _buildServiceImage(uploadedImageUrl!),
                              ),
                            )
                          else
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryRed.withOpacity(0.05),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(LucideIcons.imagePlus, color: AppTheme.primaryRed, size: 28),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Upload Service Cover',
                                    style: GoogleFonts.manrope(
                                      fontSize: 13,
                                      color: AppTheme.primaryRed,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Tap to select a photo',
                                    style: GoogleFonts.manrope(
                                      fontSize: 10,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (uploadedImageUrl != null && uploadedImageUrl!.isNotEmpty)
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(LucideIcons.camera, color: Colors.white, size: 12),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Change',
                                      style: GoogleFonts.manrope(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (isUploadingLocal)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
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
                      helperText: 'Allowed range: ₱150 - ₱300',
                      helperStyle: GoogleFonts.manrope(fontSize: 11, color: AppTheme.primaryRed, fontWeight: FontWeight.w600),
                      prefixText: '₱ ',
                      labelStyle: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: objectiveCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Service Objective',
                      hintText: 'Describe the goal of this service...',
                      hintStyle: GoogleFonts.manrope(fontSize: 13, color: Colors.grey.shade400),
                      labelStyle: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600),
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: GoogleFonts.manrope(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () async {
                  final String priceText = priceCtrl.text.trim();
                  if (titleCtrl.text.trim().isEmpty || priceText.isEmpty) return;
                  
                  final int? rate = int.tryParse(priceText);
                  if (rate == null || rate < 150 || rate > 300) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Hourly rate must be between ₱150 and ₱300.', 
                        style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
                      backgroundColor: AppTheme.primaryRed,
                      behavior: SnackBarBehavior.floating,
                    ));
                    return;
                  }
                  
                  await FirebaseFirestore.instance.collection('services').doc(docId).update({
                    'title': titleCtrl.text.trim(),
                    'subject': titleCtrl.text.trim(),
                    'objective': objectiveCtrl.text.trim(),
                    'rate': rate,
                    'price': priceText,
                    'imageUrl': uploadedImageUrl,
                    'image': uploadedImageUrl,
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
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Service'),
        content: const Text('Are you sure you want to delete this tutoring service? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('services').doc(docId).delete();
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Service deleted.'),
                  backgroundColor: AppTheme.primaryRed,
                ));
              }
            },
            child: const Text('Delete', style: TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.bold)),
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
        showBackButton: false,
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
    final String title = svc['title'] ?? 'Untitled Service';
    final String rate = (svc['rate'] != null) ? '₱${svc['rate']}' : (svc['price'] != null ? '₱${svc['price']}' : '₱0');
    final String status = svc['status'] ?? 'Active';
    final bool isActive = status == 'Active';
    
    // Improved image resolution logic
    String imageUrl = '';
    final dynamic svcImg = svc['imageUrl'] ?? svc['image'];
    if (svcImg != null && svcImg.toString().isNotEmpty) {
      imageUrl = svcImg.toString();
    } else {
      // Reliable fallback image for services
      imageUrl = 'https://images.unsplash.com/photo-1544377193-33dcf4d68fb5?q=80&w=1000&auto=format&fit=crop';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEFF0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Image Area
          Stack(
            children: [
              Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed.withOpacity(0.05),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: _buildServiceImage(imageUrl),
                ),
              ),
              // Status Badge
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.secondaryGold : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive ? AppTheme.secondaryGold.withOpacity(0.2) : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isActive ? LucideIcons.shieldCheck : LucideIcons.clock,
                        color: Colors.white,
                        size: 10,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        status.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Actions Overlay
              Positioned(
                top: 8,
                right: 8,
                child: Row(
                  children: [
                    _buildOverlayAction(
                      icon: LucideIcons.trash2,
                      onTap: () => _showDeleteConfirmation(docId),
                      color: Colors.white,
                      iconColor: AppTheme.primaryRed,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: const Color(0xFF1A1C1E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${svc['completed'] ?? 0} completed bookings',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$rate/hr',
                  style: GoogleFonts.manrope(
                    color: AppTheme.primaryRed,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showEditServiceDialog(docId, svc),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFEEEFF0)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'Edit',
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A1C1E),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_isSubscribed) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Promote initiated for $title!')),
                            );
                          } else {
                            _showSubscribeDialog();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryRed,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                        child: Text(
                          'Promote',
                          style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlayAction({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
    required Color iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 16, color: iconColor),
      ),
    );
  }

  Widget _buildMetaItem({
    required IconData icon,
    required String label,
    required String sublabel,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 6),
        RichText(
          text: TextSpan(
            style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF1A1C1E)),
            children: [
              TextSpan(text: label, style: const TextStyle(fontWeight: FontWeight.w800)),
              const TextSpan(text: ' '),
              TextSpan(
                text: sublabel,
                style: TextStyle(
                  color: const Color(0xFF7A7C80),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

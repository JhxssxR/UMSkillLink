import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/app_theme.dart';
import '../../components/custom_app_bar.dart';
import '../../models/mock_data.dart';
import '../../services/notification_service.dart';

class TutorApplicationScreen extends StatefulWidget {
  const TutorApplicationScreen({super.key});

  @override
  State<TutorApplicationScreen> createState() => _TutorApplicationScreenState();
}

class _TutorApplicationScreenState extends State<TutorApplicationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _skillSearchController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _rateController = TextEditingController(
    text: '0.00',
  );
  final TextEditingController _collegeController = TextEditingController();

  final List<String> _skills = ['Calculus', 'Python'];

  bool _isUploadingId = false;
  bool _idUploaded = false;
  String? _idImageUrl;

  bool _isUploadingExpertise = false;
  bool _expertiseUploaded = false;
  String? _expertiseImageUrl;

  final ImagePicker _picker = ImagePicker();

  String _subscriptionTier = 'Free';

  @override
  void initState() {
    super.initState();
    _fetchUserTier();
    _fetchUserDetails();
  }

  void _fetchUserDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final String email = user.email!.toLowerCase();
      try {
        // 1. Try fetching from users collection first
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(email)
            .get();
        
        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _nameController.text = data['name'] ?? user.displayName ?? '';
            _idController.text = data['studentId'] ?? '';
            _collegeController.text = data['college'] ?? '';
          });
        }

        // 2. Fallback/Supplement from student_directory
        if (_idController.text.isEmpty || _collegeController.text.isEmpty || _nameController.text.isEmpty) {
          final dirDoc = await FirebaseFirestore.instance
              .collection('student_directory')
              .doc(email)
              .get();
          
          if (dirDoc.exists) {
            final dirData = dirDoc.data() as Map<String, dynamic>;
            setState(() {
              if (_nameController.text.isEmpty) {
                _nameController.text = dirData['name'] ?? dirData['fullName'] ?? '';
              }
              if (_idController.text.isEmpty) {
                _idController.text = dirData['studentId'] ?? dirData['id'] ?? '';
              }
              if (_collegeController.text.isEmpty) {
                _collegeController.text = dirData['college'] ?? dirData['department'] ?? '';
              }
            });
          } else {
            // Try searching by email field if doc ID lookup fails
            final query = await FirebaseFirestore.instance
                .collection('student_directory')
                .where('email', isEqualTo: email)
                .limit(1)
                .get();
            
            if (query.docs.isNotEmpty) {
              final dirData = query.docs.first.data();
              setState(() {
                if (_nameController.text.isEmpty) {
                  _nameController.text = dirData['name'] ?? dirData['fullName'] ?? '';
                }
                if (_idController.text.isEmpty) {
                  _idController.text = dirData['studentId'] ?? dirData['id'] ?? '';
                }
                if (_collegeController.text.isEmpty) {
                  _collegeController.text = dirData['college'] ?? dirData['department'] ?? '';
                }
              });
            }
          }
        }
      } catch (e) {
        debugPrint('Error fetching user details for application: $e');
      }
    }
  }

  void _fetchUserTier() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final tier = await MockData.getSubscriptionTier(user.email!);
      if (mounted) {
        setState(() {
          _subscriptionTier = tier;
        });
      }
    }
  }

  void _addSkill(String skill) {
    final limit = MockData.getSubjectLimit(_subscriptionTier);
    if (_skills.length >= limit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Your current plan limits you to $limit skills. Upgrade to Tutor Pro for more!',
          ),
          backgroundColor: AppTheme.secondaryGold,
          action: SnackBarAction(
            label: 'UPGRADE',
            textColor: Colors.white,
            onPressed: () {
              // Navigation to subscription page would go here
            },
          ),
        ),
      );
      return;
    }

    if (skill.trim().isNotEmpty && !_skills.contains(skill.trim())) {
      setState(() {
        _skills.add(skill.trim());
        _skillSearchController.clear();
      });
    }
  }

  void _removeSkill(String skill) {
    setState(() {
      _skills.remove(skill);
    });
  }

  void _pickAndUploadId() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 70,
    );
    if (image == null) return;

    setState(() {
      _isUploadingId = true;
    });

    try {
      final bytes = await image.readAsBytes();
      final String base64Image = 'data:image/png;base64,${base64Encode(bytes)}';

      setState(() {
        _isUploadingId = false;
        _idUploaded = true;
        _idImageUrl = base64Image;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('University ID processed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      });
    } catch (e) {
      setState(() {
        _isUploadingId = false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to process ID. Please try again.'),
            backgroundColor: AppTheme.primaryRed,
          ),
        );
      });
    }
  }

  void _pickAndUploadExpertise() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 70,
    );
    if (image == null) return;

    setState(() {
      _isUploadingExpertise = true;
    });

    try {
      final bytes = await image.readAsBytes();
      final String base64Image = 'data:image/png;base64,${base64Encode(bytes)}';

      setState(() {
        _isUploadingExpertise = false;
        _expertiseUploaded = true;
        _expertiseImageUrl = base64Image;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Proof of expertise processed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      });
    } catch (e) {
      setState(() {
        _isUploadingExpertise = false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to process documents. Please try again.'),
            backgroundColor: AppTheme.primaryRed,
          ),
        );
      });
    }
  }

  void _submitApplication() async {
    // Show a loading dialog first
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryRed),
        );
      },
    );

    try {
      final user = FirebaseAuth.instance.currentUser;

      // Save data to Firestore collection "tutor_applications"
      await FirebaseFirestore.instance.collection('tutor_applications').add({
        'name': _nameController.text.trim(),
        'email': user?.email ?? 'learner@umindanao.edu.ph',
        'universityId': _idController.text.trim(),
        'college': _collegeController.text.trim(),
        'skills': _skills,
        'bio': _bioController.text.trim(),
        'hourlyRate': double.tryParse(_rateController.text.trim()) ?? 0.0,
        'idImageUrl': _idImageUrl,
        'expertiseImageUrl': _expertiseImageUrl,
        'status': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
      });

      // Notify Admin about the new application
      await NotificationService.sendAdminNotification(
        'New Tutor Application 📝',
        '${_nameController.text.trim()} has submitted a new peer tutor application for review.',
        'tutor_application',
      );

      // Dismiss the loading dialog
      if (mounted) Navigator.pop(context);

      // Show success dialog and navigate back
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.checkCircle2,
                        color: Colors.green,
                        size: 54,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Application Submitted!',
                      style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.neutralColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Your application has been received and is currently pending review by an Administrator. You will be notified once your status changes.',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        color: const Color(0xFF7A7C80),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Close Dialog
                          Navigator.pop(context); // Go back to Profile
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Return to Profile',
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
          },
        );
      }
    } catch (e) {
      // Dismiss the loading dialog
      if (mounted) Navigator.pop(context);

      // Show error notification
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to submit application: $e',
              style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppTheme.primaryRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: const CustomAppBar(
        subtitle: 'TUTOR APPLICATION',
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card 1: Personal Information
            _buildFormCard(
              icon: LucideIcons.user,
              title: 'Personal Information',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputLabel('Full Name'),
                  _buildTextField(
                    controller: _nameController,
                    hint: 'Enter your full name',
                  ),
                  const SizedBox(height: 16),
                  _buildInputLabel('University ID Number'),
                  _buildTextField(
                    controller: _idController,
                    hint: 'e.g., 2023-0000',
                  ),
                  const SizedBox(height: 16),
                  _buildInputLabel('College / Department'),
                  _buildTextField(
                    controller: _collegeController,
                    hint: 'Enter your college or department',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Card 2: Expertise & Skills
            _buildFormCard(
              icon: LucideIcons.graduationCap,
              title: 'Expertise & Skills',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputLabel('Subjects / Skills'),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFEEEFF0),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.search,
                          color: Color(0xFFADB5BD),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _skillSearchController,
                            decoration: InputDecoration(
                              hintText:
                                  'Search skills (e.g., Calculus, Python)',
                              hintStyle: GoogleFonts.manrope(
                                color: const Color(0xFFADB5BD),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              border: InputBorder.none,
                            ),
                            onSubmitted: _addSkill,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            LucideIcons.plus,
                            color: AppTheme.primaryRed,
                            size: 18,
                          ),
                          onPressed: () =>
                              _addSkill(_skillSearchController.text),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Skills tags
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _skills.map((skill) {
                      return Container(
                        padding: const EdgeInsets.only(
                          left: 12,
                          right: 6,
                          top: 6,
                          bottom: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryRed.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.primaryRed.withOpacity(0.15),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              skill,
                              style: GoogleFonts.manrope(
                                color: AppTheme.primaryRed,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => _removeSkill(skill),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.transparent,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  LucideIcons.x,
                                  color: AppTheme.primaryRed,
                                  size: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  _buildInputLabel('Teaching Experience / Bio'),
                  _buildTextField(
                    controller: _bioController,
                    hint:
                        'Tell us about your academic achievements or previous tutoring experience...',
                    maxLines: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Card 3: University ID Upload
            _buildUploadCard(
              icon: LucideIcons.upload,
              title: 'University ID',
              subtitle: 'Front-facing photo of your active UM ID card.',
              buttonText: _idUploaded
                  ? 'ID Photo Uploaded ✓'
                  : 'Upload ID Photo',
              isUploading: _isUploadingId,
              isSuccess: _idUploaded,
              onTap: _pickAndUploadId,
              previewUrl: _idImageUrl,
            ),
            const SizedBox(height: 20),

            // Card 4: Proof of Expertise
            _buildUploadCard(
              icon: LucideIcons.shieldAlert,
              title: 'Proof of Expertise',
              subtitle: 'Grades (COG), certificates, or portfolio.',
              buttonText: _expertiseUploaded
                  ? 'Documents Uploaded ✓'
                  : 'Upload Documents',
              isUploading: _isUploadingExpertise,
              isSuccess: _expertiseUploaded,
              onTap: _pickAndUploadExpertise,
              previewUrl: _expertiseImageUrl,
            ),
            const SizedBox(height: 20),

            // Card 5: Tutoring Rate
            _buildFormCard(
              icon: LucideIcons.banknote,
              title: 'Tutoring Rate',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputLabel('Hourly Rate (PHP)'),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFEEEFF0),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '₱',
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF495057),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _rateController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: const Color(0xFF1A1C1E),
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Average rates range from ₱150 - ₱350/hr.',
                    style: GoogleFonts.manrope(
                      color: const Color(0xFFADB5BD),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Certified Peer Tutor Quote Banner Block
            Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: const DecorationImage(
                  image: AssetImage('assets/images/um_campus.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.bottomRight,
                        end: Alignment.topLeft,
                        colors: [
                          Colors.black.withOpacity(0.85),
                          Colors.black.withOpacity(0.4),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '“Empowering the UM\ncommunity through shared\nknowledge.”',
                          style: GoogleFonts.manrope(
                            color: Colors.white,
                            fontSize: 16,
                            height: 1.3,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBB03B),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.verified_user,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'CERTIFIED PEER TUTOR',
                                style: GoogleFonts.manrope(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 8,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Save & Continue Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitApplication,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Save & Continue',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Save Draft Text Button
            Center(
              child: TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Application draft saved!',
                        style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: AppTheme.secondaryGold,
                    ),
                  );
                  Navigator.pop(context);
                },
                child: Text(
                  'Save Draft',
                  style: GoogleFonts.manrope(
                    color: const Color(0xFF7A7C80),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          color: const Color(0xFF495057),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEEEFF0), width: 1.5),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: GoogleFonts.manrope(
          color: const Color(0xFF1A1C1E),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.manrope(
            color: const Color(0xFFADB5BD),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildFormCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEFF0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryRed, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildUploadCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required bool isUploading,
    required bool isSuccess,
    required VoidCallback onTap,
    String? previewUrl,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEFF0), width: 1),
      ),
      child: Column(
        children: [
          if (isSuccess && previewUrl != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: previewUrl.startsWith('data:image')
                      ? MemoryImage(base64Decode(previewUrl.split(',').last))
                      : NetworkImage(previewUrl) as ImageProvider,
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSuccess
                    ? Colors.green.withOpacity(0.08)
                    : const Color(0xFFF1F3F5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSuccess ? LucideIcons.checkCircle : icon,
                color: isSuccess ? Colors.green : AppTheme.primaryRed,
                size: 24,
              ),
            ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: const Color(0xFF1A1C1E),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.manrope(
              color: const Color(0xFF7A7C80),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: isUploading || isSuccess ? null : onTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSuccess
                    ? Colors.green.withOpacity(0.08)
                    : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSuccess ? Colors.green : const Color(0xFFCED4DA),
                  style: isSuccess ? BorderStyle.solid : BorderStyle.solid,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: isUploading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryRed,
                          ),
                        ),
                      )
                    : Text(
                        buttonText,
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.bold,
                          color: isSuccess
                              ? Colors.green
                              : const Color(0xFF495057),
                          fontSize: 13,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

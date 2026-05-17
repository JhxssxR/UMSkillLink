import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/app_theme.dart';
import '../../widgets/tutor_layout.dart';

class TutorApplicationScreen extends StatefulWidget {
  const TutorApplicationScreen({super.key});

  @override
  State<TutorApplicationScreen> createState() => _TutorApplicationScreenState();
}

class _TutorApplicationScreenState extends State<TutorApplicationScreen> {
  final TextEditingController _nameController = TextEditingController(text: 'Juan D. Dela Cruz');
  final TextEditingController _idController = TextEditingController(text: '2023-0000');
  final TextEditingController _skillSearchController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _rateController = TextEditingController(text: '0.00');

  String _selectedCollege = 'College of Engineering';
  final List<String> _colleges = [
    'College of Engineering',
    'College of Computing Education',
    'College of Business Administration',
    'College of Architecture',
    'College of Arts and Sciences'
  ];

  final List<String> _skills = ['Calculus', 'Python'];

  bool _isUploadingId = false;
  bool _idUploaded = false;

  bool _isUploadingExpertise = false;
  bool _expertiseUploaded = false;

  void _addSkill(String skill) {
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

  void _simulateIdUpload() {
    setState(() {
      _isUploadingId = true;
    });
    Timer(const Duration(seconds: 1), () {
      setState(() {
        _isUploadingId = false;
        _idUploaded = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'University ID uploaded successfully!',
            style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  void _simulateExpertiseUpload() {
    setState(() {
      _isUploadingExpertise = true;
    });
    Timer(const Duration(seconds: 1), () {
      setState(() {
        _isUploadingExpertise = false;
        _expertiseUploaded = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Proof of expertise uploaded successfully!',
            style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  void _submitApplication() {
    // Show success dialog and navigate to Tutor Mode
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                  child: const Icon(LucideIcons.checkCircle2, color: Colors.green, size: 54),
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
                  'Your application is being verified by the UM Super Admin. You have been granted instant sandbox access to explore the Tutor Dashboard!',
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
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const TutorLayout()),
                        (route) => false,
                      );
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
                      'Go to Tutor Dashboard',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF1A1C1E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'UM SkillLink',
                  style: GoogleFonts.manrope(
                    color: AppTheme.primaryRed,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'TUTOR APPLICATION',
                  style: GoogleFonts.manrope(
                    color: const Color(0xFF7A7C80),
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.helpCircle, color: Color(0xFF7A7C80)),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFFEEEFF0),
            height: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step Progress Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Step 1 of 3',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryRed,
                  ),
                ),
                Text(
                  'Profile & Skills',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: const Color(0xFF7A7C80),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Stack(
              children: [
                Container(
                  height: 6,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9ECEF),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                Container(
                  height: 6,
                  width: MediaQuery.of(context).size.width * 0.33,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRed,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFEEEFF0), width: 1.5),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCollege,
                        isExpanded: true,
                        icon: const Icon(LucideIcons.chevronDown, color: Color(0xFF7A7C80), size: 18),
                        style: GoogleFonts.manrope(
                          color: const Color(0xFF1A1C1E),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        items: _colleges.map((String college) {
                          return DropdownMenuItem<String>(
                            value: college,
                            child: Text(college),
                          );
                        }).toList(),
                        onChanged: (String? val) {
                          if (val != null) {
                            setState(() {
                              _selectedCollege = val;
                            });
                          }
                        },
                      ),
                    ),
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
                      border: Border.all(color: const Color(0xFFEEEFF0), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.search, color: Color(0xFFADB5BD), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _skillSearchController,
                            decoration: InputDecoration(
                              hintText: 'Search skills (e.g., Calculus, Python)',
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
                          icon: const Icon(LucideIcons.plus, color: AppTheme.primaryRed, size: 18),
                          onPressed: () => _addSkill(_skillSearchController.text),
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
                        padding: const EdgeInsets.only(left: 12, right: 6, top: 6, bottom: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryRed.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.primaryRed.withOpacity(0.15)),
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
                                child: const Icon(LucideIcons.x, color: AppTheme.primaryRed, size: 12),
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
                    hint: 'Tell us about your academic achievements or previous tutoring experience...',
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
              buttonText: _idUploaded ? 'ID Photo Uploaded ✓' : 'Upload ID Photo',
              isUploading: _isUploadingId,
              isSuccess: _idUploaded,
              onTap: _simulateIdUpload,
            ),
            const SizedBox(height: 20),

            // Card 4: Proof of Expertise
            _buildUploadCard(
              icon: LucideIcons.shieldAlert,
              title: 'Proof of Expertise',
              subtitle: 'Grades (COG), certificates, or portfolio.',
              buttonText: _expertiseUploaded ? 'Documents Uploaded ✓' : 'Upload Documents',
              isUploading: _isUploadingExpertise,
              isSuccess: _expertiseUploaded,
              onTap: _simulateExpertiseUpload,
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
                      border: Border.all(color: const Color(0xFFEEEFF0), width: 1.5),
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
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBB03B),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified_user, color: Colors.white, size: 12),
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSuccess ? Colors.green.withOpacity(0.08) : const Color(0xFFF1F3F5),
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
                color: isSuccess ? Colors.green.withOpacity(0.08) : Colors.white,
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
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryRed),
                        ),
                      )
                    : Text(
                        buttonText,
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.bold,
                          color: isSuccess ? Colors.green : const Color(0xFF495057),
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

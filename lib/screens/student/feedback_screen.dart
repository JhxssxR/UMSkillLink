import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/app_theme.dart';
import '../../widgets/student_layout.dart';
import '../../components/custom_app_bar.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  int _selectedRating = 4; // Default to 4 out of 5 stars
  final TextEditingController _commentController = TextEditingController();
  bool _isFileComplaintActive = false;
  String _selectedIssueCategory = 'Late attendance';

  final List<String> _issueCategories = [
    'Late attendance',
    'Unprofessional behavior',
    'Incomplete session material',
    'Other issue',
  ];

  void _submitFeedback() {
    // Show a success dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                Icons.volunteer_activism_rounded,
                color: Color(0xFF137333),
                size: 54,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Thank You!',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1C1E),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _isFileComplaintActive
                  ? 'Your feedback and report have been logged. The support team will investigate the issue.'
                  : 'Your feedback was successfully submitted! Let\'s build a stronger university community together.',
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
                  // Pop Dialog
                  Navigator.pop(context);
                  // Pop Feedback screen and return to StudentLayout
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const StudentLayout(initialIndex: 0),
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
                  'Back to Home',
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
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: CustomAppBar(
        showBackButton: true,
        actions: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: const NetworkImage(
              'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100',
            ),
            onBackgroundImageError: (exception, stackTrace) {},
          ),
          const SizedBox(width: 16),
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
                  children: [
                    // Service summary details card
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
                          const SizedBox(height: 8),
                          Text(
                            'Web Development Tutoring',
                            style: GoogleFonts.manrope(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1A1C1E),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Session with Alex Rivera • Oct 24, 2023',
                            style: GoogleFonts.manrope(
                              color: const Color(0xFF7A7C80),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(height: 24, color: Color(0xFFDEE2E6)),

                          // Tutor details
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.grey.shade300,
                                backgroundImage: const NetworkImage(
                                  'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100',
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
                                      'Alex Rivera',
                                      style: GoogleFonts.manrope(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF1A1C1E),
                                      ),
                                    ),
                                    Text(
                                      'B.S. Information Technology',
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Interactive Questions Title
                    Text(
                      'How was your session?',
                      style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A1C1E),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your feedback helps the UM community grow stronger.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        color: const Color(0xFF7A7C80),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Star Selectors Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starPos = index + 1;
                        final isActive = starPos <= _selectedRating;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedRating = starPos;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(
                              isActive ? Icons.star : Icons.star_border,
                              color: isActive
                                  ? const Color(0xFFFBB03B)
                                  : const Color(0xFFCED4DA),
                              size: 40,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 32),

                    // Custom comment field card
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Write your review',
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A1C1E),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _commentController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText:
                            'Tell us what you liked or how the provider can improve...',
                        hintStyle: GoogleFonts.manrope(
                          color: const Color(0xFFADB5BD),
                          fontSize: 12,
                        ),
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
                    const SizedBox(height: 24),

                    // File a Complaint Section (styled light red card)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0F2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.primaryRed.withOpacity(0.15),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryRed.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  LucideIcons.alertTriangle,
                                  color: AppTheme.primaryRed,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'File a Complaint',
                                      style: GoogleFonts.manrope(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryRed,
                                      ),
                                    ),
                                    Text(
                                      'Only for serious issues during session',
                                      style: GoogleFonts.manrope(
                                        fontSize: 11,
                                        color: const Color(0xFF7A7C80),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _isFileComplaintActive,
                                activeColor: AppTheme.primaryRed,
                                activeTrackColor: AppTheme.primaryRed
                                    .withOpacity(0.2),
                                inactiveThumbColor: const Color(0xFF7A7C80),
                                inactiveTrackColor: const Color(0xFFE9ECEF),
                                onChanged: (value) {
                                  setState(() {
                                    _isFileComplaintActive = value;
                                  });
                                },
                              ),
                            ],
                          ),
                          if (_isFileComplaintActive) ...[
                            const SizedBox(height: 16),
                            const Divider(height: 1, color: Color(0xFFFDCFD6)),
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Issue Category',
                                style: GoogleFonts.manrope(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF495057),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFFDCFD6),
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedIssueCategory,
                                  isExpanded: true,
                                  icon: const Icon(
                                    LucideIcons.chevronDown,
                                    color: Color(0xFF7A7C80),
                                    size: 18,
                                  ),
                                  style: GoogleFonts.manrope(
                                    color: const Color(0xFF495057),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                      setState(() {
                                        _selectedIssueCategory = newValue;
                                      });
                                    }
                                  },
                                  items: _issueCategories
                                      .map<DropdownMenuItem<String>>((
                                        String value,
                                      ) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value),
                                        );
                                      })
                                      .toList(),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Submit feedback solid CTA
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitFeedback,
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
                          'Submit Feedback',
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

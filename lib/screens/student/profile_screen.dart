import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/app_theme.dart';
import '../../models/mock_data.dart';
import '../login_screen.dart';
import '../../widgets/student_layout.dart';
import '../../widgets/tutor_layout.dart';
import 'tutor_application_screen.dart';

class ProfileScreen extends StatelessWidget {
  final bool isTutorMode;
  
  const ProfileScreen({super.key, this.isTutorMode = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          isTutorMode ? 'Tutor Profile' : 'Student Profile',
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFFEEEFF0),
            height: 1,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: [
          // Hero Profile Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEEEFF0)),
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 46,
                      backgroundColor: isTutorMode ? AppTheme.secondaryGold.withOpacity(0.15) : AppTheme.primaryRed.withOpacity(0.15),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: isTutorMode ? AppTheme.secondaryGold : AppTheme.primaryRed,
                        child: const Icon(LucideIcons.user, size: 40, color: Colors.white),
                      ),
                    ),
                    if (!isTutorMode)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppTheme.secondaryGold,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.check, size: 14, color: Colors.white),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Juan Dela Cruz',
                  style: GoogleFonts.manrope(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.neutralColor,
                  ),
                ),
                Text(
                  isTutorMode ? 'UM Accredited Peer Tutor' : 'BS Computer Science',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'student@umindanao.edu.ph',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Learning Statistics Section
          _buildSectionTitle('Learning Statistics'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Completed', '12 Sessions', LucideIcons.checkCircle2, AppTheme.primaryRed),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard('Duration', '24.5 Hours', LucideIcons.clock, AppTheme.tertiaryIndigo),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Academic Goals Section
          _buildSectionTitle('Academic Goals'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEEEFF0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGoalItem('🐍 Master Python Programming Concepts', 'Target: End of Term'),
                const Divider(height: 20, color: Color(0xFFEEEFF0)),
                _buildGoalItem('📐 Score high on Differential Calculus II exam', 'Target: Next Week'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Active Bookings Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle('Active Bookings'),
              Text(
                'View All',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...MockData.learnerBookings.map((booking) => _buildBookingCard(booking)),
          const SizedBox(height: 24),

          // Favorite Tutors Section
          _buildSectionTitle('Favorite Tutors'),
          const SizedBox(height: 12),
          SizedBox(
            height: 130,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: MockData.tutors.length,
              itemBuilder: (context, index) {
                final tutor = MockData.tutors[index];
                return _buildFavTutorCard(tutor);
              },
            ),
          ),
          const SizedBox(height: 16),

          if (!isTutorMode) ...[
            // Tutor Application Promotion Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryRed, AppTheme.primaryRed.withOpacity(0.85)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryRed.withOpacity(0.1),
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
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.award, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Earn as a Peer Tutor',
                        style: GoogleFonts.manrope(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Share your academic expertise with peers. Get accredited, choose your rate, and empower the UM community.',
                    style: GoogleFonts.manrope(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const TutorApplicationScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primaryRed,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Apply Now • Tutor Application',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          const SizedBox(height: 16),

          // Mode Switcher Button
          ElevatedButton.icon(
            onPressed: () {
              if (isTutorMode) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const StudentLayout()),
                  (route) => false,
                );
              } else {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const TutorLayout()),
                  (route) => false,
                );
              }
            },
            icon: Icon(isTutorMode ? LucideIcons.graduationCap : LucideIcons.briefcase, size: 18),
            label: Text(
              isTutorMode ? 'Switch to Student Mode' : 'Switch to Tutor Mode',
              style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isTutorMode ? AppTheme.primaryRed : AppTheme.secondaryGold,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 12),

          // Settings Options
          _buildSettingsItem(LucideIcons.settings, 'Account Settings'),
          _buildSettingsItem(LucideIcons.bell, 'Notifications'),
          if (isTutorMode) _buildSettingsItem(LucideIcons.wallet, 'Earnings & Payouts'),
          if (!isTutorMode) _buildSettingsItem(LucideIcons.creditCard, 'Payment Methods'),
          _buildSettingsItem(LucideIcons.helpCircle, 'Help & Support'),
          
          const SizedBox(height: 24),
          
          // Log Out Button
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            icon: const Icon(LucideIcons.logOut, size: 18),
            label: Text('Log Out', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryRed,
              side: const BorderSide(color: AppTheme.primaryRed),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppTheme.neutralColor,
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEFF0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.manrope(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                ),
                Text(
                  value,
                  style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.neutralColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalItem(String text, String target) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.neutralColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                target,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.primaryRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Active',
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryRed,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final bool isUpcoming = booking['isUpcoming'] ?? false;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              color: isUpcoming ? AppTheme.primaryRed.withOpacity(0.1) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isUpcoming ? LucideIcons.calendar : LucideIcons.checkSquare,
              color: isUpcoming ? AppTheme.primaryRed : Colors.grey.shade600,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking['subject'],
                  style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.neutralColor),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tutor: ${booking['tutorName']} • ${booking['time']}',
                  style: GoogleFonts.manrope(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isUpcoming ? const Color(0xFFE3F2FD) : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              booking['status'],
              style: GoogleFonts.manrope(
                color: isUpcoming ? Colors.blue.shade800 : Colors.green.shade800,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavTutorCard(Map<String, dynamic> tutor) {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEFF0)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppTheme.tertiaryIndigo.withOpacity(0.1),
            child: const Icon(LucideIcons.user, color: AppTheme.tertiaryIndigo, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            tutor['name'],
            style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.neutralColor),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: AppTheme.secondaryGold, size: 12),
              const SizedBox(width: 2),
              Text(
                tutor['rating'].toString(),
                style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.neutralColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(IconData icon, String title) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEEEFF0)),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.grey.shade600, size: 20),
        title: Text(
          title,
          style: GoogleFonts.manrope(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.neutralColor),
        ),
        trailing: Icon(LucideIcons.chevronRight, color: Colors.grey.shade400, size: 18),
        onTap: () {},
      ),
    );
  }
}

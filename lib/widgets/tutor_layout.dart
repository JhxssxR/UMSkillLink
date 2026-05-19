import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/app_theme.dart';
import '../screens/tutor/tutor_dashboard_screen.dart';
import '../screens/tutor/manage_services_screen.dart';
import '../screens/tutor/tutor_bookings_screen.dart';
import '../screens/tutor/tutor_messages_screen.dart';
import '../screens/student/profile_screen.dart';

class TutorLayout extends StatefulWidget {
  final int initialIndex;

  const TutorLayout({super.key, this.initialIndex = 0});

  @override
  State<TutorLayout> createState() => _TutorLayoutState();
}

class _TutorLayoutState extends State<TutorLayout> {
  late int _currentIndex;

  final List<Widget> _pages = [
    const TutorDashboardScreen(),
    const ManageServicesScreen(),
    const TutorBookingsScreen(),
    const TutorMessagesScreen(),
    const ProfileScreen(isTutorMode: true),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Container(
        height: 76,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(color: Color(0xFFEEEFF0), width: 1.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, LucideIcons.layoutDashboard, 'Dashboard'),
            _buildNavItem(1, LucideIcons.briefcase, 'Services'),
            _buildNavItem(2, LucideIcons.calendarCheck, 'Requests'),
            _buildNavItem(3, LucideIcons.messageCircle, 'Messages'),
            _buildNavItem(4, LucideIcons.user, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isActive = _currentIndex == index;

    return GestureDetector(
      key: ValueKey('tutor_nav_$index'),
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 14 : 8,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryRed : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : const Color(0xFF7A7C80),
              size: 20,
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

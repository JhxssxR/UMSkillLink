import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/app_theme.dart';
import '../screens/tutor/tutor_dashboard_screen.dart';
import '../screens/tutor/manage_services_screen.dart';
import '../screens/tutor/tutor_bookings_screen.dart';
import '../screens/student/profile_screen.dart'; // We can reuse the profile or make a tutor specific one

class TutorLayout extends StatefulWidget {
  const TutorLayout({super.key});

  @override
  State<TutorLayout> createState() => _TutorLayoutState();
}

class _TutorLayoutState extends State<TutorLayout> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const TutorDashboardScreen(),
    const ManageServicesScreen(),
    const TutorBookingsScreen(),
    const ProfileScreen(isTutorMode: true),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.secondaryGold, // Distinct color for Tutor mode
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: const [
          BottomNavigationBarItem(icon: Icon(LucideIcons.layoutDashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.briefcase), label: 'Services'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.calendarCheck), label: 'Requests'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.user), label: 'Profile'),
        ],
      ),
    );
  }
}

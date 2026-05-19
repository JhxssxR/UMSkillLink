import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_theme.dart';

class ReportsAnalyticsScreen extends StatefulWidget {
  const ReportsAnalyticsScreen({super.key});

  @override
  State<ReportsAnalyticsScreen> createState() => _ReportsAnalyticsScreenState();
}

class _ReportsAnalyticsScreenState extends State<ReportsAnalyticsScreen> {
  String _selectedRange = 'Last 30 Days';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, userSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('bookings').snapshots(),
          builder: (context, bookingSnapshot) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('tutors')
                  .snapshots(),
              builder: (context, tutorSnapshot) {
                // Calculate dynamic metrics
                final users = userSnapshot.data?.docs ?? [];
                final bookings = bookingSnapshot.data?.docs ?? [];
                final tutors = tutorSnapshot.data?.docs ?? [];

                // 1. Role Distribution Calculations
                int studentCount = 0;
                int tutorCount = 0;
                int adminCount = 0;

                for (var userDoc in users) {
                  final data = userDoc.data() as Map<String, dynamic>;
                  final role = (data['role'] ?? 'student')
                      .toString()
                      .toLowerCase();
                  if (role == 'admin') {
                    adminCount++;
                  } else if (role == 'tutor') {
                    tutorCount++;
                  } else {
                    studentCount++;
                  }
                }

                // If completely empty database, show default non-empty fallback ratio representation
                final totalCalculated = studentCount + tutorCount + adminCount;
                double studentPercent = totalCalculated > 0
                    ? (studentCount / totalCalculated) * 100
                    : 60;
                double tutorPercent = totalCalculated > 0
                    ? (tutorCount / totalCalculated) * 100
                    : 30;
                double adminPercent = totalCalculated > 0
                    ? (adminCount / totalCalculated) * 100
                    : 10;

                // 2. Average rating computation
                double sumRating = 0.0;
                for (var t in tutors) {
                  final d = t.data() as Map<String, dynamic>;
                  sumRating +=
                      double.tryParse((d['rating'] ?? '5.0').toString()) ?? 5.0;
                }
                double avgRating = tutors.isNotEmpty
                    ? sumRating / tutors.length
                    : 5.0;

                // 3. Completion Rate Calculation
                int completed = 0;
                for (var b in bookings) {
                  final d = b.data() as Map<String, dynamic>;
                  final status = (d['status'] ?? '').toString().toLowerCase();
                  if (status == 'completed' || status == 'approved') {
                    completed++;
                  }
                }
                double completionRate = bookings.isNotEmpty
                    ? (completed / bookings.length) * 100
                    : 100.0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Performance Overview',
                          style: GoogleFonts.manrope(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        DropdownButton<String>(
                          value: _selectedRange,
                          style: GoogleFonts.manrope(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                          onChanged: (v) {
                            if (v != null) {
                              setState(() {
                                _selectedRange = v;
                              });
                            }
                          },
                          items: ['Last 7 Days', 'Last 30 Days', 'This Year']
                              .map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value,
                                    style: GoogleFonts.manrope(fontSize: 13),
                                  ),
                                );
                              })
                              .toList(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildChartCard(
                            'Dynamic Revenue Growth (PHP)',
                            _buildLineChart(bookings),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _buildChartCard(
                            'Real-Time User Proportions',
                            _buildPieChart(
                              studentPercent,
                              tutorPercent,
                              adminPercent,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    Text(
                      'System Detailed Statistics',
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 16),

                    GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 3,
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                      childAspectRatio: 3.2,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildSmallStatCard(
                          'Active User Registrations',
                          users.length.toString(),
                          'Live Database',
                          LucideIcons.users,
                          Colors.blue,
                        ),
                        _buildSmallStatCard(
                          'Service Completion Rate',
                          '${completionRate.toStringAsFixed(1)}%',
                          '${bookings.length} total sessions',
                          LucideIcons.checkCircle2,
                          Colors.green,
                        ),
                        _buildSmallStatCard(
                          'Average Tutor Rating',
                          '${avgRating.toStringAsFixed(1)}/5.0',
                          'Based on active feedback',
                          LucideIcons.star,
                          AppTheme.secondaryGold,
                        ),
                      ],
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildChartCard(String title, Widget chart) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(height: 280, child: chart),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(List<QueryDocumentSnapshot> bookings) {
    // Generate simple dynamic spots based on bookings revenue or defaults
    List<FlSpot> spots = [];
    if (bookings.isEmpty) {
      spots = [
        const FlSpot(0, 2),
        const FlSpot(1, 3),
        const FlSpot(2, 2.5),
        const FlSpot(3, 4),
        const FlSpot(4, 5),
        const FlSpot(5, 7),
      ];
    } else {
      // Accumulate price sequentially to show growth
      double cumulative = 0;
      for (int i = 0; i < bookings.length; i++) {
        final d = bookings[i].data() as Map<String, dynamic>;
        final price =
            double.tryParse(
              (d['price'] ?? '0.0').toString().replaceAll('₱', ''),
            ) ??
            0.0;
        cumulative += price * 0.05; // 5% fee revenue
        spots.add(FlSpot(i.toDouble(), cumulative));
      }
      if (spots.length < 2) {
        spots.add(FlSpot(1, cumulative + 100));
      }
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppTheme.primaryRed,
            barWidth: 4,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.primaryRed.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(
    double studentPercent,
    double tutorPercent,
    double adminPercent,
  ) {
    return PieChart(
      PieChartData(
        sectionsSpace: 4,
        centerSpaceRadius: 40,
        sections: [
          PieChartSectionData(
            color: AppTheme.primaryRed,
            value: studentPercent,
            title: '${studentPercent.toStringAsFixed(0)}%',
            radius: 50,
            titleStyle: GoogleFonts.manrope(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          PieChartSectionData(
            color: AppTheme.secondaryGold,
            value: tutorPercent,
            title: '${tutorPercent.toStringAsFixed(0)}%',
            radius: 50,
            titleStyle: GoogleFonts.manrope(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          PieChartSectionData(
            color: AppTheme.tertiaryIndigo,
            value: adminPercent,
            title: '${adminPercent.toStringAsFixed(0)}%',
            radius: 50,
            titleStyle: GoogleFonts.manrope(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallStatCard(
    String label,
    String value,
    String sub,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.manrope(
                      color: Colors.grey.shade600,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    sub,
                    style: GoogleFonts.manrope(
                      color: Colors.grey.shade400,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

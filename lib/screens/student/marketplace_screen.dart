import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/app_theme.dart';
import '../../models/mock_data.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/student_layout.dart';
import '../../components/custom_app_bar.dart';
import 'service_details_screen.dart';
import 'chat_screen.dart';
import '../../components/notification_bell.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  String _selectedCategory = 'All Skills';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'All Skills',
    'Tutoring',
    'Design',
    'Coding',
  ];

  Map<String, dynamic> _serviceToTutorMap(Map<String, dynamic> svc) {
    final String tutorName = svc['name'] ?? svc['tutorName'] ?? 'Peer Tutor';
    final String title = svc['title'] ?? 'Untitled Service';
    
    // Extract price/rate correctly
    dynamic rawPrice = svc['price'];
    if (rawPrice == null || rawPrice.toString().trim().isEmpty || rawPrice.toString() == 'null') {
      rawPrice = svc['rate'] ?? 0;
    }
    
    String priceStr = rawPrice.toString()
        .replaceAll('₱', '')
        .replaceAll('/hr', '')
        .replaceAll(',', '')
        .trim();
    if (priceStr.isEmpty || priceStr == 'null') priceStr = '0';

    return {
      'name': tutorName,
      'tutorEmail': svc['tutorEmail'],
      'subject': title,
      'rating': (svc['rating'] ?? 5.0).toDouble(),
      'reviews': (svc['reviews'] ?? 0).toInt(),
      'price': priceStr,
      'rate': priceStr,
      'avatar':
          svc['tutorAvatar'] ??
          svc['imageUrl'] ??
          'https://res.cloudinary.com/demo/image/upload/v1312461204/sample.jpg',
      'imageUrl':
          svc['imageUrl'] ??
          'https://res.cloudinary.com/demo/image/upload/v1312461204/sample.jpg',
      'college': 'University of Mindanao',
      'about':
          '$tutorName offers $title tutoring services. Book a session to learn more!',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: CustomAppBar(
        showBackButton: false,
        centerTitle: false,
        actions: [
          const NotificationBell(),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              final state = context
                  .findAncestorStateOfType<StudentLayoutState>();
              if (state != null) {
                state.setIndex(3);
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StudentLayout(initialIndex: 3),
                  ),
                );
              }
            },
            child: !Firebase.apps.isNotEmpty
                ? CircleAvatar(
                    radius: 18,
                    backgroundColor: AppTheme.primaryRed.withOpacity(0.15),
                    child: const Text(
                      'S',
                      style: TextStyle(
                        color: AppTheme.primaryRed,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  )
                : StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(
                          FirebaseAuth.instance.currentUser?.email ??
                              'student@umindanao.edu.ph',
                        )
                        .snapshots(),
                    builder: (context, snapshot) {
                      String firstLetter = 'S';
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final data =
                            snapshot.data!.data() as Map<String, dynamic>;
                        final name = data['name'] as String?;
                        if (name != null && name.isNotEmpty) {
                          firstLetter = name[0].toUpperCase();
                        }
                      } else {
                        final email = FirebaseAuth.instance.currentUser?.email;
                        if (email != null && email.isNotEmpty) {
                          firstLetter = email[0].toUpperCase();
                        }
                      }

                      final photoUrl =
                          FirebaseAuth.instance.currentUser?.photoURL;
                      if (photoUrl != null) {
                        return CircleAvatar(
                          radius: 18,
                          backgroundColor: AppTheme.primaryRed.withOpacity(
                            0.15,
                          ),
                          backgroundImage: NetworkImage(photoUrl),
                        );
                      }

                      return CircleAvatar(
                        radius: 18,
                        backgroundColor: AppTheme.primaryRed.withOpacity(0.15),
                        child: Text(
                          firstLetter,
                          style: const TextStyle(
                            color: AppTheme.primaryRed,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Section
              Text(
                'Find your study partner',
                style: GoogleFonts.manrope(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1C1E),
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Connect with verified UM tutors for any subject.',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: const Color(0xFF7A7C80),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),

              // Search Bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFEEEFF0),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search for tutors, skills, or subjects...',
                    hintStyle: GoogleFonts.manrope(
                      color: const Color(0xFFADB5BD),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    icon: const Icon(
                      LucideIcons.search,
                      color: Color(0xFF7A7C80),
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Skill Category Tabs / Pills
              SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = _selectedCategory == category;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryRed
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryRed
                                : const Color(0xFFEEEFF0),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          category,
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF495057),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 28),

              // --- ALL SERVICES FROM FIRESTORE ---
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('services')
                    .where('status', isEqualTo: 'Active')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 200,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryRed,
                        ),
                      ),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFEEEFF0)),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            LucideIcons.users,
                            color: AppTheme.primaryRed,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Services Available Yet',
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1A1C1E),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tutor services will appear here once they are published by verified tutors.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              color: const Color(0xFF7A7C80),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // --- Determine featured tutor ---
                  // Only feature a service if it has real feedback (reviews > 0).
                  // Pick the best-rated one per subject (1 tutor only per skill).
                  // Filter services by category and search query
                  final allServices = docs
                      .map((d) => d.data() as Map<String, dynamic>)
                      .where((svc) {
                        final title = (svc['title'] ?? '')
                            .toString()
                            .toLowerCase();
                        final tutorName =
                            (svc['name'] ?? svc['tutorName'] ?? '')
                                .toString()
                                .toLowerCase();

                        // Category filtering
                        if (_selectedCategory != 'All Skills') {
                          if (!title.contains(
                            _selectedCategory.toLowerCase(),
                          )) {
                            return false;
                          }
                        }

                        // Search query filtering
                        if (_searchQuery.isNotEmpty) {
                          if (!title.contains(_searchQuery) &&
                              !tutorName.contains(_searchQuery)) {
                            return false;
                          }
                        }
                        return true;
                      })
                      .toList();

                  // Find best service per subject that has feedback
                  Map<String, dynamic>? featuredSvc;
                  final Set<String> seenSubjects = {};
                  // Sort: highest rating first, then most reviews
                  allServices.sort((a, b) {
                    final ratingA = (a['rating'] ?? 0.0).toDouble();
                    final ratingB = (b['rating'] ?? 0.0).toDouble();
                    if (ratingB != ratingA) return ratingB.compareTo(ratingA);
                    final reviewsA = (a['reviews'] ?? 0).toInt();
                    final reviewsB = (b['reviews'] ?? 0).toInt();
                    return reviewsB.compareTo(reviewsA);
                  });

                  for (final svc in allServices) {
                    final reviews = (svc['reviews'] ?? 0).toInt();
                    final rating = (svc['rating'] ?? 0.0).toDouble();
                    final subject = (svc['title'] ?? '')
                        .toString()
                        .toLowerCase()
                        .trim();
                    // Only feature if tutor has at least 10 good reviews (≥4.5 stars)
                    if (reviews >= 10 &&
                        rating >= 4.5 &&
                        !seenSubjects.contains(subject)) {
                      featuredSvc = svc;
                      seenSubjects.add(subject);
                      break; // Only 1 featured tutor
                    }
                  }

                  final Map<String, dynamic>? featuredTutor =
                      featuredSvc != null
                      ? _serviceToTutorMap(featuredSvc)
                      : null;

                  final bool isFeaturedPro = featuredTutor != null && featuredTutor['subscriptionTier'] == 'Tutor Pro';
                  final String tutorName = featuredTutor != null ? (featuredTutor['name'] ?? 'Tutor Name') : 'Tutor Name';

                  final bool isOwnFeatured = featuredTutor != null &&
                      FirebaseAuth.instance.currentUser?.email == featuredTutor['tutorEmail'];

                  // Remaining = all services except the featured one
                  final remainingServices = featuredSvc != null
                      ? allServices.where((s) => s != featuredSvc).toList()
                      : allServices;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- FEATURED TUTOR (only if feedback exists) ---
                      if (featuredTutor != null) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Featured Tutor',
                              style: GoogleFonts.manrope(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1A1C1E),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFFBB03B,
                                ).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.verified,
                                    color: Color(0xFFFBB03B),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Based on feedback',
                                    style: GoogleFonts.manrope(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFD4960A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Large Featured Card
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ServiceDetailsScreen(tutor: featuredTutor),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFEEEFF0),
                                width: 1,
                              ),
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
                                Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(15),
                                        topRight: Radius.circular(15),
                                      ),
                                      child: SizedBox(
                                        height: 160,
                                        width: double.infinity,
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            Image.network(
                                              featuredTutor['imageUrl'] ??
                                                  'https://res.cloudinary.com/demo/image/upload/v1312461204/sample.jpg',
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => Container(
                                                    height: 160,
                                                    color: AppTheme.primaryRed
                                                        .withOpacity(0.1),
                                                    child: const Icon(
                                                      LucideIcons.image,
                                                      color:
                                                          AppTheme.primaryRed,
                                                      size: 40,
                                                    ),
                                                  ),
                                            ),
                                            Container(
                                              color: Colors.black.withOpacity(
                                                0.1,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 12,
                                      left: 12,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFBB03B),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.workspace_premium,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'TOP RATED',
                                              style: GoogleFonts.manrope(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    tutorName,
                                                    style: GoogleFonts.manrope(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                      color: const Color(0xFF1A1C1E),
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (isFeaturedPro) ...[
                                                  const SizedBox(width: 4),
                                                  const Icon(
                                                    Icons.stars,
                                                    color: AppTheme.secondaryGold,
                                                    size: 16,
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF1F3F5),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.star,
                                                  color: Color(0xFFFBB03B),
                                                  size: 14,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${featuredTutor['rating']} (${featuredTutor['reviews']})',
                                                  style: GoogleFonts.manrope(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w800,
                                                    color: const Color(
                                                      0xFF1A1C1E,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        featuredTutor['subject'] ?? 'Subject',
                                        style: GoogleFonts.manrope(
                                          color: const Color(0xFF7A7C80),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(
                                            LucideIcons.graduationCap,
                                            color: AppTheme.primaryRed,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            featuredTutor['college'] ??
                                                'University of Mindanao',
                                            style: GoogleFonts.manrope(
                                              color: const Color(0xFF495057),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ServiceDetailsScreen(
                                                      tutor: featuredTutor,
                                                    ),
                                              ),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                AppTheme.primaryRed,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: Text(
                                            isOwnFeatured
                                                ? 'View Your Service'
                                                : (featuredTutor['rate'] == '0' ||
                                                        featuredTutor['rate'] == 0)
                                                    ? 'Book Session • FREE'
                                                    : 'Book Session • ₱${featuredTutor['rate'] ?? 250}/hr',
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
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // --- ALL AVAILABLE SERVICES (always shown) ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Available Services',
                            style: GoogleFonts.manrope(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1A1C1E),
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: Text(
                              'View All',
                              style: GoogleFonts.manrope(
                                color: AppTheme.primaryRed,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (remainingServices.isNotEmpty)
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: remainingServices.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                childAspectRatio: 0.8,
                              ),
                          itemBuilder: (context, index) {
                            final tutorMap = _serviceToTutorMap(
                              remainingServices[index],
                            );
                            return _buildMiniTutorCard(context, tutorMap);
                          },
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniTutorCard(BuildContext context, Map<String, dynamic> tutor) {
    final String? currentUserEmail = FirebaseAuth.instance.currentUser?.email;
    final bool isOwnService = currentUserEmail != null && currentUserEmail == tutor['tutorEmail'];
    final String avatarUrl =
        tutor['avatar'] ??
        'https://res.cloudinary.com/demo/image/upload/v1312461204/sample.jpg';
    final String tutorEmail = tutor['tutorEmail'] ?? '';
    final String initialName = tutor['name'] ?? 'Peer Tutor';

    Widget nameWidget = Text(
      initialName,
      style: GoogleFonts.manrope(
        fontWeight: FontWeight.bold,
        fontSize: 13,
        color: const Color(0xFF1A1C1E),
      ),
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    if ((initialName == 'Peer Tutor' ||
            initialName == 'null null' ||
            initialName.isEmpty) &&
        tutorEmail.isNotEmpty) {
      nameWidget = FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(tutorEmail)
            .get(),
        builder: (context, snapshot) {
          String fetchedName = 'Peer Tutor';
          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            fetchedName =
                data['name'] ??
                '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
            if (fetchedName.isEmpty) fetchedName = 'Peer Tutor';
            tutor['name'] = fetchedName;
          }
          return Text(
            fetchedName,
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: const Color(0xFF1A1C1E),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        },
      );
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceDetailsScreen(tutor: tutor),
          ),
        );
      },
      child: Container(
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Background Cover Image
            Expanded(
              flex: 4,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                ),
                child: Image.network(
                  avatarUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: AppTheme.primaryRed.withOpacity(0.1),
                    child: const Icon(
                      LucideIcons.image,
                      color: AppTheme.primaryRed,
                    ),
                  ),
                ),
              ),
            ),
            // Content
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 8.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        nameWidget,
                        const SizedBox(height: 2),
                        Text(
                          tutor['subject'] ?? 'Subject',
                          style: GoogleFonts.manrope(
                            color: const Color(0xFF7A7C80),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if ((tutor['reviews'] ?? 0) > 0)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.star,
                                color: Color(0xFFFBB03B),
                                size: 12,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                (tutor['rating'] ?? 5.0).toString(),
                                style: GoogleFonts.manrope(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1A1C1E),
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            'New',
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryRed,
                            ),
                          ),
                      ],
                    ),
                    // Book a Session Button
                    SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ServiceDetailsScreen(tutor: tutor),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryRed,
                          side: const BorderSide(
                            color: AppTheme.primaryRed,
                            width: 1,
                          ),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          isOwnService ? 'View Service' : 'Book a Session',
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceListingCard(
    BuildContext context,
    Map<String, dynamic> svc,
  ) {
    final bool isOwnService = FirebaseAuth.instance.currentUser?.email == svc['tutorEmail'];
    final String tutorName = svc['tutorName'] ?? 'Peer Tutor';
    final String title = svc['title'] ?? 'Untitled Service';
    
    dynamic rawPrice = svc['price'];
    if (rawPrice == null || rawPrice.toString().trim().isEmpty || rawPrice.toString() == 'null') {
      rawPrice = svc['rate'] ?? 0;
    }
    
    String displayPrice = rawPrice.toString();
    if (!displayPrice.contains('₱') && rawPrice.toString() != '0' && rawPrice != 0) {
      displayPrice = '₱$displayPrice/hr';
    } else if (rawPrice.toString() == '0' || rawPrice == 0 || displayPrice == 'FREE') {
      displayPrice = 'FREE';
    }

    final double rating = (svc['rating'] ?? 5.0).toDouble();
    final int reviews = (svc['reviews'] ?? 0).toInt();
    final String? avatarUrl = svc['tutorAvatar'];
    final String firstLetter = tutorName.isNotEmpty
        ? tutorName[0].toUpperCase()
        : 'T';

    // Extract numeric price for ServiceDetailsScreen
    final priceNum = displayPrice
        .replaceAll('₱', '')
        .replaceAll('/hr', '')
        .replaceAll(',', '')
        .replaceAll('FREE', '0')
        .trim();

    // Map service data to tutor format for ServiceDetailsScreen
    final tutorMap = <String, dynamic>{
      'name': tutorName,
      'tutorEmail': svc['tutorEmail'],
      'subject': title,
      'rating': rating,
      'reviews': reviews,
      'price': priceNum,
      'rate': priceNum,
      'avatar': avatarUrl,
      'college': 'University of Mindanao',
      'about':
          '$tutorName offers $title tutoring services. Book a session to learn more!',
    };

    final bool isPro = svc['subscriptionTier'] == 'Tutor Pro';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceDetailsScreen(tutor: tutorMap),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEEEFF0), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Tutor Avatar
            avatarUrl != null
                ? CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.primaryRed.withOpacity(0.1),
                    backgroundImage: NetworkImage(avatarUrl),
                    onBackgroundImageError: (_, __) {},
                  )
                : CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.primaryRed.withOpacity(0.1),
                    child: Text(
                      firstLetter,
                      style: GoogleFonts.manrope(
                        color: AppTheme.primaryRed,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
            const SizedBox(width: 14),
            // Service Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: const Color(0xFF1A1C1E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'by $tutorName',
                          style: GoogleFonts.manrope(
                            color: const Color(0xFF7A7C80),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isPro) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.stars,
                          color: AppTheme.secondaryGold,
                          size: 12,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Color(0xFFFBB03B),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$rating ($reviews)',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF495057),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Price & Book
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  displayPrice,
                  style: GoogleFonts.manrope(
                    color: displayPrice == 'FREE'
                        ? Colors.green
                        : AppTheme.primaryRed,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 30,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ServiceDetailsScreen(tutor: tutorMap),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryRed,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      isOwnService ? 'View' : 'Book',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewItemCard(
    String title,
    String author,
    String time,
    String price,
    List<String> tags,
    String imageUrl,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEFF0), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              imageUrl,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 72,
                height: 72,
                color: const Color(0xFFF1F3F5),
                child: const Icon(
                  LucideIcons.image,
                  color: Color(0xFFADB5BD),
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Center Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: const Color(0xFF1A1C1E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      (price == '₱0/hr' || price == '0') ? 'FREE' : price,
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: (price == '₱0/hr' || price == '0')
                            ? Colors.green
                            : AppTheme.primaryRed,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'by $author • $time',
                  style: GoogleFonts.manrope(
                    color: const Color(0xFF7A7C80),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                // Tags
                Row(
                  children: tags.map((tag) {
                    return Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F3F5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tag,
                        style: GoogleFonts.manrope(
                          color: const Color(0xFF495057),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

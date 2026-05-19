import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isClearing = false;

  Future<void> _clearAllNotifications(List<QueryDocumentSnapshot> docs) async {
    if (docs.isEmpty) return;

    setState(() {
      _isClearing = true;
    });

    try {
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'All notifications cleared.',
              style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppTheme.neutralColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to clear notifications: $e',
              style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppTheme.primaryRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isClearing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null || currentUser.email == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Notifications',
            style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
          ),
        ),
        body: Center(
          child: Text(
            'Please log in to view notifications.',
            style: GoogleFonts.manrope(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.manrope(
            color: const Color(0xFF1A1C1E),
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Color(0xFF1A1C1E)),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.email)
                .collection('notifications')
                .snapshots(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) return const SizedBox.shrink();

              return _isClearing
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primaryRed,
                          ),
                        ),
                      ),
                    )
                  : TextButton.icon(
                      icon: const Icon(LucideIcons.trash2, size: 15, color: AppTheme.primaryRed),
                      label: Text(
                        'Clear All',
                        style: GoogleFonts.manrope(
                          color: AppTheme.primaryRed,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      onPressed: () => _clearAllNotifications(docs),
                    );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.email)
            .collection('notifications')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryRed),
            );
          }

          final notifications = snapshot.data?.docs ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.bellOff,
                      size: 44,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No notifications yet',
                    style: GoogleFonts.manrope(
                      color: const Color(0xFF1A1C1E),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'We will let you know when something happens.',
                    style: GoogleFonts.manrope(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          // Auto mark all unread notifications as read when screen is opened
          final unreadDocs = notifications.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return (data['isRead'] ?? false) == false;
          }).toList();

          if (unreadDocs.isNotEmpty) {
            Future.microtask(() {
              final batch = FirebaseFirestore.instance.batch();
              for (var doc in unreadDocs) {
                batch.update(doc.reference, {'isRead': true});
              }
              batch.commit().catchError((e) {
                debugPrint('Failed to mark notifications as read: $e');
              });
            });
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final doc = notifications[index];
              final notif = doc.data() as Map<String, dynamic>;
              final bool isRead = notif['isRead'] ?? false;

              IconData iconData = LucideIcons.bell;
              Color iconColor = AppTheme.primaryRed;

              final String type = notif['type'] ?? '';
              if (type.contains('payment')) {
                iconData = LucideIcons.creditCard;
                iconColor = Colors.orange.shade700;
              } else if (type.contains('booking') || type.contains('session')) {
                iconData = LucideIcons.calendarRange;
                iconColor = Colors.blue.shade700;
              } else if (type.contains('approved') || type.contains('success')) {
                iconData = LucideIcons.checkCircle2;
                iconColor = Colors.green.shade700;
              } else if (type.contains('rejected') || type.contains('declined') || type.contains('fail')) {
                iconData = LucideIcons.xCircle;
                iconColor = Colors.red.shade700;
              }

              // Display beautiful relative time if possible, or fallback
              String timeStr = 'Just now';
              final Timestamp? ts = notif['timestamp'] as Timestamp?;
              if (ts != null) {
                final diff = DateTime.now().difference(ts.toDate());
                if (diff.inMinutes < 1) {
                  timeStr = 'Just now';
                } else if (diff.inMinutes < 60) {
                  timeStr = '${diff.inMinutes}m ago';
                } else if (diff.inHours < 24) {
                  timeStr = '${diff.inHours}h ago';
                } else {
                  timeStr = '${diff.inDays}d ago';
                }
              }

              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isRead ? const Color(0xFFEEEFF0) : AppTheme.primaryRed.withOpacity(0.2),
                    width: isRead ? 1.0 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      if (!isRead) {
                        doc.reference.update({'isRead': true});
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: iconColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              iconData,
                              color: iconColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        notif['title'] ?? 'System Update',
                                        style: GoogleFonts.manrope(
                                          fontWeight: isRead ? FontWeight.bold : FontWeight.w900,
                                          fontSize: 14,
                                          color: const Color(0xFF1A1C1E),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      timeStr,
                                      style: GoogleFonts.manrope(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  notif['message'] ?? '',
                                  style: GoogleFonts.manrope(
                                    color: const Color(0xFF495057),
                                    fontSize: 13,
                                    height: 1.45,
                                    fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

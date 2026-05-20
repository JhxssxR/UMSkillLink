import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static Future<void> sendNotification(String userEmail, String title, String message, String type) async {
    final String cleanEmail = userEmail.trim().toLowerCase();
    if (cleanEmail.isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(cleanEmail)
          .collection('notifications')
          .add({
        'title': title,
        'message': message,
        'type': type,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  static Future<void> sendAdminNotification(String title, String message, String type) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', whereIn: ['admin', 'superadmin', 'Admin', 'SuperAdmin', 'Super Admin'])
          .get();

      if (snapshot.docs.isEmpty) {
        // Fallback: If no users have the role, try to notify the known admin email
        await sendNotification('j.antukan.549054@umindanao.edu.ph', title, message, type);
        return;
      }

      for (var doc in snapshot.docs) {
        // Use the email field if it exists, otherwise use doc.id
        final data = doc.data() as Map<String, dynamic>;
        final String targetEmail = data['email'] ?? doc.id;
        await sendNotification(targetEmail, title, message, type);
      }
    } catch (e) {
      print('Error sending admin notification: $e');
    }
  }
}

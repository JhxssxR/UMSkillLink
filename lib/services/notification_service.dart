import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static Future<void> sendNotification(String userEmail, String title, String message, String type) async {
    if (userEmail.isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userEmail)
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
          .where('role', whereIn: ['admin', 'superadmin'])
          .get();

      for (var doc in snapshot.docs) {
        await sendNotification(doc.id, title, message, type);
      }
    } catch (e) {
      print('Error sending admin notification: $e');
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class MockData {
  // Live cache lists synced from Cloud Firestore
  static List<Map<String, dynamic>> tutors = [];
  static List<Map<String, dynamic>> learnerBookings = [];
  static List<Map<String, dynamic>> tutorRequests = [];
  static List<Map<String, dynamic>> favoriteTutors = [];
  static List<Map<String, dynamic>> messages = [];
  static List<Map<String, dynamic>> academicGoals = [
    {'title': '🐍 Master Python Programming Concepts', 'target': 'End of Term'},
    {
      'title': '📐 Score high on Differential Calculus II exam',
      'target': 'Next Week',
    },
  ];

  static void addMockGoal(Map<String, dynamic> goal) {
    academicGoals.add(goal);
  }

  // Initialize and synchronize all dynamic data directly from Cloud Firestore
  static Future<void> initializeFromFirestore() async {
    try {
      if (kIsWeb) {
        if (Firebase.apps.isEmpty) {
          debugPrint('MockData: Firebase has not been initialized.');
          return;
        }
      }

      // Attempt to access instance; this can throw JS TypeErrors if the JS SDK failed to load
      final firestore = FirebaseFirestore.instance;

      // 1. Synchronize Tutors
      try {
        final tutorsSnapshot = await firestore.collection('tutors').get();
        tutors = tutorsSnapshot.docs.map((doc) => doc.data()).toList();
      } catch (e) {
        debugPrint('MockData: Failed to sync tutors: $e');
      }

      // 2. Synchronize Learner Bookings
      try {
        final bookingsSnapshot = await firestore.collection('bookings').get();
        learnerBookings = bookingsSnapshot.docs
            .map((doc) => doc.data())
            .toList();
      } catch (e) {
        debugPrint('MockData: Failed to sync bookings: $e');
      }

      // 3. Synchronize Tutor Requests
      try {
        final requestsSnapshot = await firestore
            .collection('tutor_requests')
            .get();
        tutorRequests = requestsSnapshot.docs.map((doc) => doc.data()).toList();
      } catch (e) {
        debugPrint('MockData: Failed to sync tutor requests: $e');
      }

      // 4. Synchronize Favorite Tutors
      try {
        final favoritesSnapshot = await firestore.collection('favorites').get();
        favoriteTutors = favoritesSnapshot.docs
            .map((doc) => doc.data())
            .toList();
      } catch (e) {
        debugPrint('MockData: Failed to sync favorite tutors: $e');
      }

      // 5. Synchronize Messages
      try {
        final messagesSnapshot = await firestore.collection('messages').get();
        messages = messagesSnapshot.docs.map((doc) => doc.data()).toList();
      } catch (e) {
        debugPrint('MockData: Failed to sync messages: $e');
      }

      debugPrint(
        'MockData: Cleanly synced database collections from Cloud Firestore.',
      );
    } catch (e) {
      debugPrint('MockData initializeFromFirestore error: $e');
    }
  }

  // --- Dynamic Firestore Sync Methods ---

  static Future<void> syncBookingAdded(Map<String, dynamic> booking) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(booking['id'].toString())
          .set(booking, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore sync booking add exception: $e');
    }
  }

  static Future<void> syncTutorRequestAdded(
    Map<String, dynamic> request,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('tutor_requests')
          .doc(request['id'].toString())
          .set(request, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore sync request add exception: $e');
    }
  }

  static Future<void> syncBookingDeleted(String id) async {
    try {
      await FirebaseFirestore.instance.collection('bookings').doc(id).delete();
    } catch (e) {
      debugPrint('Firestore sync booking delete exception: $e');
    }
  }

  static Future<void> syncTutorRequestDeleted(String id) async {
    try {
      await FirebaseFirestore.instance
          .collection('tutor_requests')
          .doc(id)
          .delete();
    } catch (e) {
      debugPrint('Firestore sync request delete exception: $e');
    }
  }

  static Future<void> syncTutorRequestUpdated(String id, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('tutor_requests')
          .doc(id)
          .update({'status': status});
    } catch (e) {
      debugPrint('Firestore sync request update status exception: $e');
    }
  }

  static Future<void> syncBookingStatusUpdated(
    String id,
    String status, {
    bool? isUpcoming,
  }) async {
    try {
      final Map<String, dynamic> updates = {'status': status};
      if (isUpcoming != null) {
        updates['isUpcoming'] = isUpcoming;
      }
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(id)
          .update(updates);
    } catch (e) {
      debugPrint('Firestore sync booking update status exception: $e');
    }
  }
}

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
        tutors = tutorsSnapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
      } catch (e) {
        debugPrint('MockData: Failed to sync tutors: $e');
      }

      // 2. Synchronize Learner Bookings
      try {
        final bookingsSnapshot = await firestore.collection('bookings').get();
        learnerBookings = bookingsSnapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
      } catch (e) {
        debugPrint('MockData: Failed to sync bookings: $e');
      }

      // 3. Synchronize Tutor Requests
      try {
        final requestsSnapshot = await firestore
            .collection('tutor_requests')
            .get();
        tutorRequests = requestsSnapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
      } catch (e) {
        debugPrint('MockData: Failed to sync tutor requests: $e');
      }

      // 4. Synchronize Favorite Tutors
      try {
        final favoritesSnapshot = await firestore.collection('favorites').get();
        favoriteTutors = favoritesSnapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
      } catch (e) {
        debugPrint('MockData: Failed to sync favorite tutors: $e');
      }

      // 5. Synchronize Messages
      try {
        final messagesSnapshot = await firestore.collection('messages').get();
        messages = messagesSnapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
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

  static Future<void> acceptTutorRequest(String requestId, String tutorEmail, double amount) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('tutor_requests').doc(requestId);
      final doc = await docRef.get();
      
      if (doc.exists && doc.data()?['status'] != 'Confirmed') {
        final requestData = doc.data()!;
        final learnerName = requestData['learnerName'] ?? 'Student';
        final batch = FirebaseFirestore.instance.batch();
        
        // 1. Update request status
        batch.update(docRef, {'status': 'Confirmed'});
        
        // 2. Update booking status
        batch.update(
          FirebaseFirestore.instance.collection('bookings').doc(requestId), 
          {'status': 'Confirmed', 'isUpcoming': true}
        );
        
        // Get subscription tier to determine commission
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(tutorEmail.toLowerCase()).get();
        final userData = userDoc.data() ?? {};
        final tier = userData['subscriptionTier'] ?? 'Free';
        final commissionRate = getCommissionRate(tier);
        final netEarnings = amount * (1 - commissionRate);
        final deduction = amount * commissionRate;
        
        // 3. Increment tutor earnings
        batch.update(
          FirebaseFirestore.instance.collection('users').doc(tutorEmail.toLowerCase()),
          {'pendingEarnings': FieldValue.increment(netEarnings)}
        );

        // 4. Log Earnings History for the Tutor
        final earningsRef = FirebaseFirestore.instance
            .collection('users')
            .doc(tutorEmail.toLowerCase())
            .collection('earnings_history')
            .doc(requestId);
        
        batch.set(earningsRef, {
          'id': requestId,
          'bookingId': requestId,
          'amount': amount,
          'netAmount': netEarnings,
          'deduction': deduction,
          'commissionRate': commissionRate,
          'learnerName': learnerName,
          'subject': requestData['subject'] ?? 'Tutoring',
          'type': 'Tutoring Session',
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'Confirmed',
        });
        
        await batch.commit();
      }
    } catch (e) {
      debugPrint('Error accepting tutor request: $e');
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

  // --- Subscription Helpers ---

  static Future<String> getSubscriptionTier(String email) async {
    try {
      final subDoc = await FirebaseFirestore.instance
          .collection('subscriptions')
          .where('userEmail', isEqualTo: email.toLowerCase())
          .where('status', isEqualTo: 'Active')
          .limit(1)
          .get();
      
      if (subDoc.docs.isNotEmpty) {
        return subDoc.docs.first.data()['plan'] ?? 'Free';
      }
    } catch (e) {
      debugPrint('Error getting subscription tier: $e');
    }
    return 'Free';
  }

  static Future<void> requestSessionEnd(String requestId) async {
    try {
      await FirebaseFirestore.instance.collection('bookings').doc(requestId).update({
        'endRequestedAt': FieldValue.serverTimestamp(),
        'tutorConfirmedEnd': true,
      });
    } catch (e) {
      debugPrint('Error requesting session end: $e');
    }
  }

  static Future<void> finalizeSession(String requestId, String tutorEmail) async {
    try {
      final String safeEmail = tutorEmail.toLowerCase().trim();
      final bookingRef = FirebaseFirestore.instance.collection('bookings').doc(requestId);
      final bookingSnap = await bookingRef.get();
      
      if (!bookingSnap.exists) {
        debugPrint('MockData: Booking $requestId not found.');
        return;
      }
      
      final bookingData = bookingSnap.data() as Map<String, dynamic>;
      final batch = FirebaseFirestore.instance.batch();
      bool statusUpdated = false;

      // 1. Update status to Completed if not already done
      if (bookingData['status'] != 'Completed') {
        batch.update(bookingRef, {
          'status': 'Completed',
          'isUpcoming': false,
          'studentConfirmedEnd': true,
          'tutorConfirmedEnd': true,
          'completedAt': FieldValue.serverTimestamp(),
        });

        batch.update(
          FirebaseFirestore.instance.collection('tutor_requests').doc(requestId), 
          {'status': 'Completed'}
        );
        statusUpdated = true;
      }

      // 2. Process Earnings Transfer (Recovery-aware)
      final earningsHistoryRef = FirebaseFirestore.instance
          .collection('users')
          .doc(safeEmail)
          .collection('earnings_history')
          .doc(requestId);
      
      final earningsDoc = await earningsHistoryRef.get();
      bool earningsProcessed = false;

      if (earningsDoc.exists) {
        final eData = earningsDoc.data()!;
        if (eData['status'] == 'Completed') {
          earningsProcessed = true; 
        } else {
          final netAmount = (eData['netAmount'] ?? 0.0).toDouble();
          batch.update(
            FirebaseFirestore.instance.collection('users').doc(safeEmail),
            {
              'pendingEarnings': FieldValue.increment(-netAmount),
              'earnings': FieldValue.increment(netAmount),
              'completedSessions': FieldValue.increment(1),
            }
          );
          batch.update(earningsHistoryRef, {'status': 'Completed'});
          earningsProcessed = true;
        }
      } else {
        // FALLBACK: If earnings_history doc is missing, calculate from booking price
        final double amount = (bookingData['price'] ?? 0.0).toDouble();
        if (amount > 0) {
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(safeEmail).get();
          final userData = userDoc.data() ?? {};
          final tier = userData['subscriptionTier'] ?? 'Free';
          final commissionRate = getCommissionRate(tier);
          final netEarnings = amount * (1 - commissionRate);
          final deduction = amount * commissionRate;

          batch.update(
            FirebaseFirestore.instance.collection('users').doc(safeEmail),
            {
              'pendingEarnings': FieldValue.increment(-netEarnings),
              'earnings': FieldValue.increment(netEarnings),
              'completedSessions': FieldValue.increment(1),
            }
          );

          batch.set(earningsHistoryRef, {
            'id': requestId,
            'bookingId': requestId,
            'amount': amount,
            'netAmount': netEarnings,
            'deduction': deduction,
            'commissionRate': commissionRate,
            'learnerName': bookingData['learnerName'] ?? 'Student',
            'subject': bookingData['subject'] ?? 'Tutoring',
            'type': 'Tutoring Session',
            'timestamp': FieldValue.serverTimestamp(),
            'status': 'Completed',
          });
          earningsProcessed = true;
        }
      }
      
      if (statusUpdated || earningsProcessed) {
        await batch.commit();
        debugPrint('MockData: Finalized/Recovered session $requestId.');
      }
    } catch (e) {
      debugPrint('Error finalizing session: $e');
    }
  }

  static Future<void> confirmSessionEnd(String requestId, String userEmail, bool isTutor) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('bookings').doc(requestId);
      final doc = await docRef.get();
      
      if (doc.exists) {
        final data = doc.data()!;
        
        // If already completed, do nothing
        if (data['status'] == 'Completed') return;

        bool tutorConfirmed = data['tutorConfirmedEnd'] ?? false;
        bool studentConfirmed = data['studentConfirmedEnd'] ?? false;

        if (isTutor) tutorConfirmed = true;
        else studentConfirmed = true;

        if (tutorConfirmed && studentConfirmed) {
          // BOTH CONFIRMED - Delegate to finalizeSession
          await finalizeSession(requestId, data['tutorEmail'] ?? '');
        } else {
          // ONLY ONE CONFIRMED - Update flags
          await docRef.update({
            'tutorConfirmedEnd': tutorConfirmed,
            'studentConfirmedEnd': studentConfirmed,
          });
        }
      }
    } catch (e) {
      debugPrint('Error confirming session end: $e');
    }
  }

  static Future<void> completeSession(String requestId, String tutorEmail) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('tutor_requests').doc(requestId);
      final doc = await docRef.get();
      
      if (doc.exists && doc.data()?['status'] == 'Confirmed') {
        final requestData = doc.data()!;
        final batch = FirebaseFirestore.instance.batch();
        
        // 1. Update request status to Completed
        batch.update(docRef, {'status': 'Completed'});
        
        // 2. Update booking status to Completed
        batch.update(
          FirebaseFirestore.instance.collection('bookings').doc(requestId), 
          {'status': 'Completed', 'isUpcoming': false}
        );
        
        // 3. Move pending earnings to actual earnings for the tutor
        final earningsHistoryDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(tutorEmail.toLowerCase())
            .collection('earnings_history')
            .doc(requestId)
            .get();

        if (earningsHistoryDoc.exists) {
          final netAmount = (earningsHistoryDoc.data()?['netAmount'] ?? 0.0).toDouble();
          
          batch.update(
            FirebaseFirestore.instance.collection('users').doc(tutorEmail.toLowerCase()),
            {
              'pendingEarnings': FieldValue.increment(-netAmount),
              'earnings': FieldValue.increment(netAmount),
              'completedSessions': FieldValue.increment(1),
            }
          );

          // Update history record status
          batch.update(earningsHistoryDoc.reference, {'status': 'Completed'});
        }
        
        await batch.commit();
      }
    } catch (e) {
      debugPrint('Error completing session: $e');
    }
  }

  static double getCommissionRate(String tier) {
    if (tier == 'Tutor Pro') {
      return 0.03; // 3%
    }
    return 0.05; // 5% default
  }

  static int getSubjectLimit(String tier) {
    if (tier == 'Tutor Pro') {
      return 5;
    }
    return 2;
  }

  static int getBookingLimit(String tier) {
    if (tier == 'Learner Lite') {
      return 5;
    }
    return 2;
  }
}

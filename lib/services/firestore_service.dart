import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/worker.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========== WORKER OPERATIONS ==========

  /// Create or Update Worker Profile
  Future<void> saveWorkerProfile(Worker worker) async {
    await _firestore.collection('workers').doc(worker.id).set({
      'id': worker.id,
      'name': worker.name,
      'email': worker.email,
      'phone': worker.phone,
      'profileImage': worker.profileImage,
      'description': worker.description,
      'rating': worker.rating,
      'totalJobs': worker.totalJobs,
      'skills': worker.skills,
      'location': worker.location,
      'latitude': worker.latitude,
      'longitude': worker.longitude,
      'isAvailable': worker.isAvailable,
      'level': worker.level.toString().split('.').last,
      'yearsOfExperience': worker.yearsOfExperience,
      'completedProjects': worker.completedProjects,
      'successRate': worker.successRate,
      'portfolio': worker.portfolio,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Get Worker Profile by ID
  Future<DocumentSnapshot> getWorkerProfile(String workerId) async {
    return await _firestore.collection('workers').doc(workerId).get();
  }

  /// Get All Workers
  Stream<QuerySnapshot> getAllWorkers() {
    return _firestore
        .collection('workers')
        .where('isAvailable', isEqualTo: true)
        .snapshots();
  }

  // ========== GIG OPERATIONS ==========

  /// Create New Gig
  Future<String> createGig(Map<String, dynamic> gigData) async {
    gigData['createdAt'] = FieldValue.serverTimestamp();
    gigData['updatedAt'] = FieldValue.serverTimestamp();
    gigData['isAvailable'] = true;
    gigData['rating'] = 0.0;
    gigData['totalOrders'] = 0;

    DocumentReference ref = await _firestore.collection('gigs').add(gigData);
    return ref.id;
  }

  /// Update Gig
  Future<void> updateGig(String gigId, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection('gigs').doc(gigId).update(data);
  }

  /// Delete Gig
  Future<void> deleteGig(String gigId) async {
    await _firestore.collection('gigs').doc(gigId).delete();
  }

  /// Get All Gigs (for browsing)
  Stream<QuerySnapshot> getAllGigs() {
    // Note: Removing orderBy to avoid index requirement
    // Can be added back after creating composite index in Firebase Console
    return _firestore
        .collection('gigs')
        .where('isAvailable', isEqualTo: true)
        .snapshots();
  }

  /// Get Gigs by Category
  Stream<QuerySnapshot> getGigsByCategory(String category) {
    // Note: Removing orderBy to avoid index requirement
    // Can be added back after creating composite index in Firebase Console
    return _firestore
        .collection('gigs')
        .where('category', isEqualTo: category)
        .where('isAvailable', isEqualTo: true)
        .snapshots();
  }

  /// Get Worker's Gigs
  Stream<QuerySnapshot> getWorkerGigs(String workerId) {
    return _firestore
        .collection('gigs')
        .where('workerId', isEqualTo: workerId)
        .snapshots();
  }

  /// Search Gigs
  Future<List<DocumentSnapshot>> searchGigs(String query) async {
    // Note: For better search, consider using Algolia or similar
    QuerySnapshot snapshot = await _firestore
        .collection('gigs')
        .where('isAvailable', isEqualTo: true)
        .get();

    // Filter locally (simple implementation)
    return snapshot.docs.where((doc) {
      String title = doc.get('title').toString().toLowerCase();
      String description = doc.get('description').toString().toLowerCase();
      return title.contains(query.toLowerCase()) ||
          description.contains(query.toLowerCase());
    }).toList();
  }

  // ========== JOB REQUEST OPERATIONS ==========

  /// Create Job Request
  Future<String> createJobRequest({
    required String gigId,
    required String workerId,
    required String userId,
    required String description,
    required String location,
    required DateTime scheduledDate,
    required double selectedHours,
    required double totalCost,
    required String workerName,
    required String userName,
    required String category,
  }) async {
    Map<String, dynamic> jobData = {
      'gigId': gigId,
      'workerId': workerId,
      'workerName': workerName,
      'userId': userId,
      'userName': userName,
      'category': category,
      'description': description,
      'location': location,
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'selectedHours': selectedHours,
      'totalCost': totalCost,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    DocumentReference ref = await _firestore.collection('jobs').add(jobData);
    return ref.id;
  }

  /// Update Job Status
  Future<void> updateJobStatus(String jobId, String status) async {
    await _firestore.collection('jobs').doc(jobId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get Worker's Jobs
  Stream<QuerySnapshot> getWorkerJobs(String workerId) {
    return _firestore
        .collection('jobs')
        .where('workerId', isEqualTo: workerId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Get User's Jobs
  Stream<QuerySnapshot> getUserJobs(String userId) {
    return _firestore
        .collection('jobs')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ========== REVIEW OPERATIONS ==========

  /// Add Review
  Future<void> addReview({
    required String jobId,
    required String gigId,
    required String workerId,
    required String userId,
    required String userName,
    required double rating,
    required String comment,
  }) async {
    try {
      await _firestore.collection('reviews').add({
        'jobId': jobId,
        'gigId': gigId,
        'workerId': workerId,
        'userId': userId,
        'userName': userName,
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e, st) {
      developer.log('addReview: failed to add review document', error: e, stackTrace: st, name: 'FirestoreService');
      rethrow;
    }

    try {
      await _updateWorkerRating(workerId);
    } catch (e, st) {
      developer.log('addReview: failed to update worker rating', error: e, stackTrace: st, name: 'FirestoreService');
      rethrow;
    }

    try {
      await _updateGigRatingAndOrders(gigId);
    } catch (e, st) {
      developer.log('addReview: failed to update gig rating/orders', error: e, stackTrace: st, name: 'FirestoreService');
      rethrow;
    }
  }

  /// Update Worker's Average Rating
  Future<void> _updateWorkerRating(String workerId) async {
    try {
      QuerySnapshot reviews = await _firestore
          .collection('reviews')
          .where('workerId', isEqualTo: workerId)
          .get();

      if (reviews.docs.isNotEmpty) {
        double totalRating = 0;
        for (var doc in reviews.docs) {
          totalRating += (doc.get('rating') as num?)?.toDouble() ?? 0;
        }
        double avgRating = totalRating / reviews.docs.length;

        await _firestore.collection('workers').doc(workerId).update({
          'rating': avgRating,
          'totalJobs': reviews.docs.length,
        });
      }
    } catch (e, st) {
      developer.log('_updateWorkerRating: workerId=$workerId', error: e, stackTrace: st, name: 'FirestoreService');
      rethrow;
    }
  }

  /// Update gig's rating and totalOrders (call after review or job completion).
  Future<void> updateGigRatingAndOrders(String gigId) async {
    if (gigId.isEmpty) return;
    await _updateGigRatingAndOrdersImpl(gigId);
  }

  Future<void> _updateGigRatingAndOrders(String gigId) async {
    if (gigId.isEmpty) return;
    await _updateGigRatingAndOrdersImpl(gigId);
  }

  Future<void> _updateGigRatingAndOrdersImpl(String gigId) async {
    try {
      // Rating: average of all reviews for this gig
      QuerySnapshot reviewSnap = await _firestore
          .collection('reviews')
          .where('gigId', isEqualTo: gigId)
          .get();

      double avgRating = 0.0;
      if (reviewSnap.docs.isNotEmpty) {
        double total = 0;
        for (var doc in reviewSnap.docs) {
          total += (doc.get('rating') as num?)?.toDouble() ?? 0;
        }
        avgRating = total / reviewSnap.docs.length;
      }

      // Total orders: count of jobs for this gig that are completed or paid
      QuerySnapshot jobsSnap = await _firestore
          .collection('jobs')
          .where('gigId', isEqualTo: gigId)
          .get();

      int totalOrders = 0;
      for (var doc in jobsSnap.docs) {
        final raw = doc.data();
        if (raw == null) continue;
        final data = raw as Map<String, dynamic>;
        final status = data['status'] as String?;
        final paymentSubmitted = data['paymentSubmitted'] as bool?;
        if (status == 'completed' || status == 'paid' || paymentSubmitted == true) {
          totalOrders++;
        }
      }

      await _firestore.collection('gigs').doc(gigId).update({
        'rating': avgRating,
        'totalOrders': totalOrders,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e, st) {
      developer.log('_updateGigRatingAndOrdersImpl: gigId=$gigId', error: e, stackTrace: st, name: 'FirestoreService');
      rethrow;
    }
  }

  /// Get Reviews for Worker
  Stream<QuerySnapshot> getWorkerReviews(String workerId) {
    // Note: Removing orderBy to avoid index requirement
    // Will sort client-side by timestamp instead
    return _firestore
        .collection('reviews')
        .where('workerId', isEqualTo: workerId)
        .limit(50)
        .snapshots();
  }

  // ========== PAYMENTS (Stripe – status: pending → admin approves/denies) ==========

  /// Get all payments (for admin: filter by status 'pending', then approve/deny)
  Stream<QuerySnapshot> getPayments({String? status}) {
    if (status != null) {
      return _firestore
          .collection('payments')
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .snapshots();
    }
    return _firestore
        .collection('payments')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Update payment status (admin: 'approved' or 'denied')
  Future<void> updatePaymentStatus(String paymentId, String status) async {
    await _firestore.collection('payments').doc(paymentId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}


import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';
import 'firestore_service.dart';

class JobService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();
  final FirestoreService _firestoreService = FirestoreService();

  /// Accept Job Request
  Future<void> acceptJob(String jobId, String workerId, String userId, String workerName) async {
    try {
      await _firestore.collection('jobs').doc(jobId).update({
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Send notification to client
      await _notificationService.sendJobAcceptedNotification(
        userId: userId,
        workerName: workerName,
        jobTitle: 'Your job request',
        jobId: jobId,
      );
    } catch (e) {
      throw 'Error accepting job: $e';
    }
  }

  /// Reject Job Request
  Future<void> rejectJob(String jobId, String userId, String workerName) async {
    try {
      await _firestore.collection('jobs').doc(jobId).update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Send notification to client
      await _notificationService.sendJobRejectedNotification(
        userId: userId,
        workerName: workerName,
        jobTitle: 'Your job request',
        jobId: jobId,
      );
    } catch (e) {
      throw 'Error rejecting job: $e';
    }
  }

  /// Start Job
  Future<void> startJob(String jobId) async {
    try {
      await _firestore.collection('jobs').doc(jobId).update({
        'status': 'in_progress',
        'startedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Error starting job: $e';
    }
  }

  /// Complete Job
  Future<void> completeJob(String jobId, String userId, String workerName, double actualHours) async {
    try {
      await _firestore.collection('jobs').doc(jobId).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'actualHours': actualHours,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Send notification to client
      await _notificationService.sendJobCompletedNotification(
        userId: userId,
        workerName: workerName,
        jobId: jobId,
      );

      // Update worker stats
      await _updateWorkerStats(jobId);
      // Update gig rating and total orders
      DocumentSnapshot jobDoc = await _firestore.collection('jobs').doc(jobId).get();
      if (jobDoc.exists) {
        final gigId = jobDoc.get('gigId') as String?;
        if (gigId != null && gigId.isNotEmpty) {
          await _firestoreService.updateGigRatingAndOrders(gigId);
        }
      }
    } catch (e) {
      throw 'Error completing job: $e';
    }
  }

  /// Update Worker Statistics
  Future<void> _updateWorkerStats(String jobId) async {
    try {
      DocumentSnapshot jobDoc = await _firestore.collection('jobs').doc(jobId).get();
      if (jobDoc.exists) {
        String workerId = jobDoc.get('workerId');

        DocumentReference workerRef = _firestore.collection('workers').doc(workerId);
        
        await _firestore.runTransaction((transaction) async {
          DocumentSnapshot workerDoc = await transaction.get(workerRef);
          
          if (workerDoc.exists) {
            int currentJobs = workerDoc.get('completedProjects') ?? 0;
            transaction.update(workerRef, {
              'completedProjects': currentJobs + 1,
              'totalJobs': currentJobs + 1,
            });
          }
        });
      }
    } catch (e) {
      print('Error updating worker stats: $e');
    }
  }

  /// Mark Job as Paid
  Future<void> markAsPaid(String jobId, String workerId, String userId, String paymentMethod) async {
    try {
      await _firestore.collection('jobs').doc(jobId).update({
        'status': 'paid',
        'paidAt': FieldValue.serverTimestamp(),
        'paymentMethod': paymentMethod,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Send notification to worker
      await _notificationService.sendPaymentReceivedNotification(
        workerId: workerId,
        userId: userId,
        jobId: jobId,
      );

      // Update worker earnings
      await _updateWorkerEarnings(jobId);
    } catch (e) {
      throw 'Error processing payment: $e';
    }
  }

  /// Update Worker Earnings after Payment
  Future<void> _updateWorkerEarnings(String jobId) async {
    try {
      DocumentSnapshot jobDoc = await _firestore.collection('jobs').doc(jobId).get();
      if (jobDoc.exists) {
        String workerId = jobDoc.get('workerId');
        double totalCost = (jobDoc.get('totalCost') ?? 0).toDouble();

        DocumentReference workerRef = _firestore.collection('workers').doc(workerId);
        
        await _firestore.runTransaction((transaction) async {
          DocumentSnapshot workerDoc = await transaction.get(workerRef);
          
          if (workerDoc.exists) {
            double currentEarnings = (workerDoc.get('totalEarnings') ?? 0).toDouble();
            transaction.update(workerRef, {
              'totalEarnings': currentEarnings + totalCost,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        });
      }
    } catch (e) {
      print('Error updating worker earnings: $e');
    }
  }

  /// Get Worker Earnings
  Future<Map<String, dynamic>> getWorkerEarnings(String workerId) async {
    try {
      QuerySnapshot paidJobs = await _firestore
          .collection('jobs')
          .where('workerId', isEqualTo: workerId)
          .where('status', isEqualTo: 'paid')
          .get();

      double totalEarnings = 0;
      double thisMonth = 0;
      double thisWeek = 0;
      int totalJobs = paidJobs.docs.length;

      DateTime now = DateTime.now();
      DateTime startOfMonth = DateTime(now.year, now.month, 1);
      DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));

      for (var doc in paidJobs.docs) {
        double amount = (doc.get('totalCost') ?? 0).toDouble();
        totalEarnings += amount;

        Timestamp? paidAt = doc.get('paidAt');
        if (paidAt != null) {
          DateTime paidDate = paidAt.toDate();
          
          if (paidDate.isAfter(startOfMonth)) {
            thisMonth += amount;
          }
          
          if (paidDate.isAfter(startOfWeek)) {
            thisWeek += amount;
          }
        }
      }

      return {
        'totalEarnings': totalEarnings,
        'thisMonth': thisMonth,
        'thisWeek': thisWeek,
        'totalJobs': totalJobs,
        'averagePerJob': totalJobs > 0 ? totalEarnings / totalJobs : 0,
      };
    } catch (e) {
      return {
        'totalEarnings': 0.0,
        'thisMonth': 0.0,
        'thisWeek': 0.0,
        'totalJobs': 0,
        'averagePerJob': 0.0,
      };
    }
  }

  /// Get Worker Jobs by Status
  Stream<QuerySnapshot> getWorkerJobsByStatus(String workerId, String status) {
    return _firestore
        .collection('jobs')
        .where('workerId', isEqualTo: workerId)
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Get User Stats
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      QuerySnapshot allJobs = await _firestore
          .collection('jobs')
          .where('userId', isEqualTo: userId)
          .get();

      int totalJobs = allJobs.docs.length;
      int activeJobs = allJobs.docs.where((doc) {
        String status = doc.get('status') ?? '';
        return status == 'pending' || status == 'accepted' || status == 'in_progress';
      }).length;
      
      int completedJobs = allJobs.docs.where((doc) {
        String status = doc.get('status') ?? '';
        return status == 'completed' || status == 'paid';
      }).length;

      double totalSpent = 0;
      for (var doc in allJobs.docs) {
        String status = doc.get('status') ?? '';
        if (status == 'paid' || status == 'completed') {
          totalSpent += (doc.get('totalCost') ?? 0).toDouble();
        }
      }

      return {
        'totalJobs': totalJobs,
        'activeJobs': activeJobs,
        'completedJobs': completedJobs,
        'totalSpent': totalSpent,
      };
    } catch (e) {
      return {
        'totalJobs': 0,
        'activeJobs': 0,
        'completedJobs': 0,
        'totalSpent': 0.0,
      };
    }
  }
}



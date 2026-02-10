import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/constants.dart';
import '../../services/firestore_service.dart';
import 'payment_screen.dart';
import '../chat/chat_screen.dart';

class UserJobsScreen extends StatefulWidget {
  const UserJobsScreen({super.key});

  @override
  State<UserJobsScreen> createState() => _UserJobsScreenState();
}

class _UserJobsScreenState extends State<UserJobsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          title: const Text('My Jobs', style: TextStyle(color: Colors.white)),
        ),
        body: const Center(child: Text('Please login to view jobs')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'My Jobs',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _FirebaseUserJobsList(
            userId: currentUser.uid,
            statuses: ['pending', 'accepted', 'in_progress'],
            emptyMessage: 'No active jobs',
            showActions: true,
          ),
          _FirebaseUserJobsList(
            userId: currentUser.uid,
            statuses: ['completed', 'paid'],
            emptyMessage: 'No completed jobs',
            showActions: true,
          ),
          _FirebaseUserJobsList(
            userId: currentUser.uid,
            statuses: ['rejected'],
            emptyMessage: 'No cancelled jobs',
            showActions: false,
          ),
        ],
      ),
    );
  }
}

class _FirebaseUserJobsList extends StatelessWidget {
  final String userId;
  final List<String> statuses;
  final String emptyMessage;
  final bool showActions;

  const _FirebaseUserJobsList({
    required this.userId,
    required this.statuses,
    required this.emptyMessage,
    required this.showActions,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('jobs')
          .where('userId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 80,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading jobs: ${snapshot.error}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.work_outline,
                  size: 80,
                  color: AppColors.textSecondary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  emptyMessage,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        // Filter by status
        List<DocumentSnapshot> filtered = snapshot.data!.docs.where((doc) {
          String status = doc.get('status') ?? '';
          return statuses.contains(status);
        }).toList();

        // Sort by createdAt (newest first) - client-side
        filtered.sort((a, b) {
          Timestamp? aTime = a.get('createdAt') as Timestamp?;
          Timestamp? bTime = b.get('createdAt') as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.work_outline,
                  size: 80,
                  color: AppColors.textSecondary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  emptyMessage,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            return _UserJobCard(
              jobDoc: filtered[index],
              showActions: showActions,
            );
          },
        );
      },
    );
  }
}

class _UserJobCard extends StatefulWidget {
  final DocumentSnapshot jobDoc;
  final bool showActions;

  const _UserJobCard({
    required this.jobDoc,
    required this.showActions,
  });

  @override
  State<_UserJobCard> createState() => _UserJobCardState();
}

class _UserJobCardState extends State<_UserJobCard> {
  bool _hasReview = false;

  @override
  void initState() {
    super.initState();
    _checkExistingReview();
  }

  Future<void> _checkExistingReview() async {
    try {
      QuerySnapshot reviewSnapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('jobId', isEqualTo: widget.jobDoc.id)
          .limit(1)
          .get();
      
      if (mounted) {
        setState(() {
          _hasReview = reviewSnapshot.docs.isNotEmpty;
        });
      }
    } catch (e) {
      // Error checking review, assume no review exists
    }
  }

  Future<void> _showReviewDialog() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final jobData = widget.jobDoc.data() as Map<String, dynamic>;
    
    await showDialog(
      context: context,
      builder: (context) => _ReviewDialog(
        jobId: widget.jobDoc.id,
        gigId: jobData['gigId'] ?? '',
        workerId: jobData['workerId'] ?? '',
        workerName: jobData['workerName'] ?? 'the worker',
        userId: currentUser.uid,
        userName: currentUser.displayName ?? 'User',
        onReviewSubmitted: () {
          _checkExistingReview();
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.accent;
      case 'accepted':
      case 'in_progress':
        return AppColors.primary;
      case 'completed':
        return AppColors.secondary;
      case 'paid':
        return AppColors.secondary;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'paid':
        return 'Paid';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    var jobData = widget.jobDoc.data() as Map<String, dynamic>;
    String status = jobData['status'] ?? '';
    // From user's perspective: show "Paid" once they've submitted payment
    String displayStatus = status;
    if (status == 'completed' && jobData['paymentSubmitted'] == true) {
      displayStatus = 'paid';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundImage: NetworkImage(
                  jobData['workerImage'] ?? 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(jobData['workerName'] ?? 'Worker')}&background=2563EB&color=fff',
                ),
                onBackgroundImageError: (_, __) {},
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      jobData['workerName'] ?? 'Worker',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      jobData['category'] ?? 'Service',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(displayStatus).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getStatusText(displayStatus),
                  style: TextStyle(
                    color: _getStatusColor(displayStatus),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  jobData['description'] ?? 'No description provided',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${jobData['selectedHours']?.toStringAsFixed(1) ?? '0'} hours',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                if (jobData['scheduledDate'] != null) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(jobData['scheduledDate']),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
                Row(
                  children: [
                    Text(
                      '\$${jobData['totalCost']?.toStringAsFixed(2) ?? '0.00'}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.attach_money,
                      size: 18,
                      color: AppColors.secondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (widget.showActions && status == 'completed') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (status != 'paid') ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _hasReview
                          ? null
                          : () {
                              _showReviewDialog();
                            },
                      icon: Icon(_hasReview ? Icons.star : Icons.star_border),
                      label: Text(_hasReview ? 'Reviewed' : 'Review'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _hasReview
                            ? AppColors.textSecondary
                            : AppColors.accent,
                        side: BorderSide(
                          color: _hasReview
                              ? AppColors.textSecondary
                              : AppColors.accent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Show Pay only if user hasn't submitted payment yet
                  if (jobData['paymentSubmitted'] != true)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PaymentScreen(
                                jobId: widget.jobDoc.id,
                                jobData: jobData,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.payment),
                        label: const Text('Pay'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.secondary),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, color: AppColors.secondary, size: 20),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Paid',
                                style: const TextStyle(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ] else ...[
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.secondary),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: AppColors.secondary, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Payment Completed',
                            style: TextStyle(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
          if (widget.showActions && (status == 'in_progress' || status == 'accepted' || status == 'pending')) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        recipientId: jobData['workerId'] ?? '',
                        recipientName: jobData['workerName'] ?? 'Worker',
                        recipientImage: jobData['workerImage'] ?? 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(jobData['workerName'] ?? 'Worker')}&background=2563EB&color=fff',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Contact Worker'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    try {
      if (date is Timestamp) {
        DateTime dateTime = date.toDate();
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      } else if (date is DateTime) {
        return '${date.day}/${date.month}/${date.year}';
      }
      return 'Date not set';
    } catch (e) {
      return 'Date not set';
    }
  }
}

class _ReviewDialog extends StatefulWidget {
  final String jobId;
  final String gigId;
  final String workerId;
  final String workerName;
  final String userId;
  final String userName;
  final VoidCallback onReviewSubmitted;

  const _ReviewDialog({
    required this.jobId,
    required this.gigId,
    required this.workerId,
    required this.workerName,
    required this.userId,
    required this.userName,
    required this.onReviewSubmitted,
  });

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  final TextEditingController _commentController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  double _selectedRating = 5.0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      await _firestoreService.addReview(
        jobId: widget.jobId,
        gigId: widget.gigId,
        workerId: widget.workerId,
        userId: widget.userId,
        userName: widget.userName,
        rating: _selectedRating,
        comment: _commentController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review submitted successfully!'),
            backgroundColor: AppColors.secondary,
          ),
        );
        widget.onReviewSubmitted();
      }
    } catch (e, st) {
      developer.log(
        'Review submit error: jobId=${widget.jobId}, gigId=${widget.gigId}, workerId=${widget.workerId}',
        error: e,
        stackTrace: st,
        name: 'UserJobsScreen._submitReview',
      );
      setState(() {
        _isSubmitting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting review: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rate Your Experience'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How was your experience with ${widget.workerName}?',
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            const Text(
              'Rating',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedRating = (index + 1).toDouble();
                    });
                  },
                  child: Icon(
                    index < _selectedRating ? Icons.star : Icons.star_border,
                    color: AppColors.accent,
                    size: 40,
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            const Text(
              'Comment (Optional)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Share your experience...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.background,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting
              ? null
              : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitReview,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }
}




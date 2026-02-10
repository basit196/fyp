import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/constants.dart';
import '../../services/notification_service.dart';
import '../../services/firestore_service.dart';
import '../../services/job_service.dart';
import 'worker_profile_screen.dart';
import 'worker_jobs_screen.dart';
import 'worker_earnings_screen.dart';
import 'create_gig_screen.dart';
import 'my_gigs_screen.dart';
import '../chat/chat_list_screen.dart';
import '../../services/chat_service.dart';
import '../notifications/notifications_screen.dart';

class WorkerDashboard extends StatefulWidget {
  const WorkerDashboard({super.key});

  @override
  State<WorkerDashboard> createState() => _WorkerDashboardState();
}

class _WorkerDashboardState extends State<WorkerDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const WorkerHomeTab(),
    const WorkerJobsScreen(),
    const WorkerEarningsScreen(),
    const WorkerProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      extendBody: true,
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textSecondary.withOpacity(0.5),
            selectedFontSize: 12,
            unselectedFontSize: 11,
            elevation: 0,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
            items: [
              BottomNavigationBarItem(
                icon: _NavIcon(
                  icon: Iconsax.home,
                  iconBold: Iconsax.home_15,
                  isSelected: _selectedIndex == 0,
                ),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: _NavIcon(
                  icon: Iconsax.task_square,
                  iconBold: Iconsax.task_square5,
                  isSelected: _selectedIndex == 1,
                ),
                label: 'Jobs',
              ),
              BottomNavigationBarItem(
                icon: _NavIcon(
                  icon: Iconsax.dollar_square,
                  iconBold: Iconsax.dollar_square5,
                  isSelected: _selectedIndex == 2,
                ),
                label: 'Earnings',
              ),
              BottomNavigationBarItem(
                icon: _NavIcon(
                  icon: Iconsax.profile_circle,
                  iconBold: Iconsax.profile_circle5,
                  isSelected: _selectedIndex == 3,
                ),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final IconData? iconBold;
  final bool isSelected;

  const _NavIcon({
    required this.icon,
    this.iconBold,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SizedBox(
        width: 26,
        height: 26,
        child: Center(
          child: Icon(
            isSelected && iconBold != null ? iconBold : icon,
            size: 26,
          ),
        ),
      ),
    );
  }
}

class WorkerHomeTab extends StatefulWidget {
  const WorkerHomeTab({super.key});

  @override
  State<WorkerHomeTab> createState() => _WorkerHomeTabState();
}

class _WorkerHomeTabState extends State<WorkerHomeTab> {
  final FirestoreService _firestoreService = FirestoreService();
  final JobService _jobService = JobService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please login to continue')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Worker Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Iconsax.message, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChatListScreen(),
                      ),
                    );
                  },
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: StreamBuilder<int>(
                    stream: ChatService().getTotalUnreadCountStream(
                      currentUser.uid,
                    ),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data! == 0) {
                        return const SizedBox.shrink();
                      }
                      return Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Center(
                          child: Text(
                            snapshot.data! > 9 ? '9+' : '${snapshot.data}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                IconButton(
                  icon: const Icon(Iconsax.notification, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationsScreen(),
                      ),
                    );
                  },
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: StreamBuilder<int>(
                    stream: NotificationService().getUnreadCountStream(currentUser.uid),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data == 0) {
                        return const SizedBox.shrink();
                      }
                      return Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Center(
                          child: Text(
                            snapshot.data! > 9 ? '9+' : snapshot.data.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _firestoreService.getWorkerProfile(currentUser.uid),
        builder: (context, profileSnapshot) {
          if (profileSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (profileSnapshot.hasError || !profileSnapshot.hasData || !profileSnapshot.data!.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  const Text(
                    'Profile not found',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Please complete your profile first'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WorkerProfileScreen(),
                        ),
                      );
                    },
                    child: const Text('Go to Profile'),
                  ),
                ],
              ),
            );
          }

          final workerData = profileSnapshot.data!.data() as Map<String, dynamic>;
          final workerName = workerData['name'] ?? currentUser.displayName ?? 'Worker';
          final workerImage = workerData['profileImage'] ?? 
                             currentUser.photoURL ??
                             'https://ui-avatars.com/api/?name=${Uri.encodeComponent(workerName)}&background=2563EB&color=fff';
          final isAvailable = workerData['isAvailable'] ?? true;
          final rating = (workerData['rating'] ?? 0.0).toStringAsFixed(1);
          
          // Get real-time stats from Firebase
          return FutureBuilder<Map<String, dynamic>>(
            future: _getWorkerStats(currentUser.uid),
            builder: (context, statsSnapshot) {
              final stats = statsSnapshot.data ?? {
                'totalJobs': 0,
                'totalEarnings': 0.0,
              };
              final totalJobs = stats['totalJobs'] ?? 0;
              final totalEarnings = (stats['totalEarnings'] ?? 0.0).toDouble();

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage: NetworkImage(workerImage),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  workerName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Service Provider',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isAvailable
                                  ? AppColors.secondary
                                  : AppColors.error,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isAvailable ? 'Available' : 'Busy',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Stats Cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Iconsax.star1,
                          label: 'Rating',
                          value: rating,
                          color: AppColors.accent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Iconsax.briefcase,
                          label: 'Jobs',
                          value: statsSnapshot.connectionState == ConnectionState.waiting
                              ? '...'
                              : totalJobs.toString(),
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Iconsax.wallet_money,
                          label: 'Total Earnings',
                          value: statsSnapshot.connectionState == ConnectionState.waiting
                              ? '...'
                              : '\$${totalEarnings.toStringAsFixed(0)}',
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Pending Job Requests
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Job Requests',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // Navigate to jobs screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const WorkerJobsScreen(),
                            ),
                          );
                        },
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Action Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CreateGigScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Iconsax.add_circle),
                          label: const Text('Create Gig'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MyGigsScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Iconsax.briefcase),
                          label: const Text('My Gigs'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Pending Jobs List
                StreamBuilder<QuerySnapshot>(
                  stream: _jobService.getWorkerJobsByStatus(currentUser.uid, 'pending'),
                  builder: (context, jobsSnapshot) {
                    if (jobsSnapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (jobsSnapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                          child: Text(
                            'Error loading jobs: ${jobsSnapshot.error}',
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ),
                      );
                    }

                    if (!jobsSnapshot.hasData || jobsSnapshot.data!.docs.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.work_outline,
                                size: 64,
                                color: AppColors.textSecondary.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No pending job requests',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: jobsSnapshot.data!.docs
                          .map((doc) => _JobRequestCard(
                                jobDoc: doc,
                                workerId: currentUser.uid,
                                workerName: workerName,
                                onUpdate: () {
                                  setState(() {}); // Refresh the list
                                },
                              ))
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 100),
              ],
            ),
          );
            },
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _getWorkerStats(String workerId) async {
    try {
      // Get total completed/paid jobs and total earnings (fetch all jobs and filter client-side to avoid index issues)
      QuerySnapshot allJobs = await FirebaseFirestore.instance
          .collection('jobs')
          .where('workerId', isEqualTo: workerId)
          .get();

      int totalJobs = 0;
      double totalEarnings = 0.0;

      for (var doc in allJobs.docs) {
        String status = doc.get('status') ?? '';
        if (status == 'completed' || status == 'paid') {
          totalJobs++;
          // Only count earnings from paid jobs
          if (status == 'paid') {
            double totalCost = (doc.get('totalCost') ?? 0).toDouble();
            totalEarnings += totalCost;
          }
        }
      }

      return {
        'totalJobs': totalJobs,
        'totalEarnings': totalEarnings,
      };
    } catch (e) {
      print('Error getting worker stats: $e');
      return {
        'totalJobs': 0,
        'totalEarnings': 0.0,
      };
    }
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _JobRequestCard extends StatefulWidget {
  final DocumentSnapshot jobDoc;
  final String workerId;
  final String workerName;
  final VoidCallback onUpdate;

  const _JobRequestCard({
    required this.jobDoc,
    required this.workerId,
    required this.workerName,
    required this.onUpdate,
  });

  @override
  State<_JobRequestCard> createState() => _JobRequestCardState();
}

class _JobRequestCardState extends State<_JobRequestCard> {
  bool _isProcessing = false;
  final JobService _jobService = JobService();

  Future<void> _acceptJob() async {
    setState(() => _isProcessing = true);
    try {
      final jobData = widget.jobDoc.data() as Map<String, dynamic>;
      await _jobService.acceptJob(
        widget.jobDoc.id,
        widget.workerId,
        jobData['userId'] ?? '',
        widget.workerName,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job accepted successfully!'),
            backgroundColor: AppColors.secondary,
          ),
        );
        widget.onUpdate();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accepting job: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _rejectJob() async {
    setState(() => _isProcessing = true);
    try {
      final jobData = widget.jobDoc.data() as Map<String, dynamic>;
      await _jobService.rejectJob(
        widget.jobDoc.id,
        jobData['userId'] ?? '',
        widget.workerName,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job rejected'),
            backgroundColor: AppColors.textSecondary,
          ),
        );
        widget.onUpdate();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting job: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobData = widget.jobDoc.data() as Map<String, dynamic>;
    final userName = jobData['userName'] ?? 'Unknown User';
    final location = jobData['location'] ?? 'Not specified';
    final category = jobData['category'] ?? 'General';
    final description = jobData['description'] ?? 'No description';
    final selectedHours = (jobData['selectedHours'] ?? 0).toDouble();
    final totalCost = (jobData['totalCost'] ?? 0).toDouble();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      location,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  category,
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Iconsax.clock, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                '${selectedHours.toStringAsFixed(1)} hours',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Iconsax.dollar_circle, size: 16, color: AppColors.secondary),
              const SizedBox(width: 4),
              Text(
                '\$${totalCost.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isProcessing ? null : _rejectJob,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Decline'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _acceptJob,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Accept'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


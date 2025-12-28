import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';
import '../../utils/constants.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/job_service.dart';
import 'edit_profile_screen.dart';
import '../welcome_screen.dart';

class WorkerProfileScreen extends StatefulWidget {
  const WorkerProfileScreen({super.key});

  @override
  State<WorkerProfileScreen> createState() => _WorkerProfileScreenState();
}

class _WorkerProfileScreenState extends State<WorkerProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'My Profile',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.logout, color: Colors.white),
            onPressed: () async {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () async {
                        await AuthService().signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) => const WelcomeScreen(),
                            ),
                            (route) => false,
                          );
                        }
                      },
                      child: const Text(
                        'Logout',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirestoreService().getWorkerProfile(currentUser!.uid),
        builder: (context, profileSnapshot) {
          if (profileSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (profileSnapshot.hasError || !profileSnapshot.hasData || !profileSnapshot.data!.exists) {
            // If worker profile doesn't exist, show basic info from Firebase Auth with "Complete Profile" button
            return _buildBasicProfile(context, currentUser);
          }

          // Check if profile is incomplete (missing required fields)
          var workerData = profileSnapshot.data!.data() as Map<String, dynamic>;
          bool isIncomplete = _isProfileIncomplete(workerData);

          if (isIncomplete) {
            return _buildIncompleteProfile(context, currentUser, workerData);
          }

          return FutureBuilder<Map<String, dynamic>>(
            future: JobService().getWorkerEarnings(currentUser.uid),
            builder: (context, earningsSnapshot) {
              final earnings = earningsSnapshot.data ?? {
                'totalEarnings': 0.0,
                'totalJobs': 0,
              };

              return SingleChildScrollView(
                child: Column(
                  children: [
                    // Header Section
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
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: NetworkImage(
                              workerData['profileImage'] ?? 
                              currentUser.photoURL ??
                              'https://ui-avatars.com/api/?name=${Uri.encodeComponent(workerData['name'] ?? currentUser.displayName ?? 'Worker')}&background=2563EB&color=fff',
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            workerData['name'] ?? currentUser.displayName ?? 'Worker',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              workerData['category'] ?? 'Service Provider',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 20),
                              const SizedBox(width: 4),
                              Text(
                                '${(workerData['rating'] ?? 0.0).toStringAsFixed(1)} (${earnings['totalJobs']} jobs)',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
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
                              icon: Iconsax.wallet_money,
                              label: 'Total Earnings',
                              value: '\$${earnings['totalEarnings'].toStringAsFixed(0)}',
                              color: AppColors.secondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              icon: Iconsax.briefcase,
                              label: 'Jobs Done',
                              value: '${earnings['totalJobs']}',
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.trending_up,
                              label: 'Avg/Job',
                              value: '\$${earnings['averagePerJob']?.toStringAsFixed(0) ?? '0'}',
                              color: AppColors.accent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              icon: Iconsax.star,
                              label: 'Rating',
                              value: '${(workerData['rating'] ?? 0.0).toStringAsFixed(1)}',
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Contact Information
                    _InfoSection(
                      title: 'Contact Information',
                      children: [
                        _InfoTile(
                          icon: Icons.email,
                          label: 'Email',
                          value: currentUser.email ?? workerData['email'] ?? 'N/A',
                        ),
                        _InfoTile(
                          icon: Icons.phone,
                          label: 'Phone',
                          value: workerData['phone'] ?? 'Not provided',
                        ),
                        _InfoTile(
                          icon: Icons.location_on,
                          label: 'Location',
                          value: workerData['location'] ?? 'Not provided',
                        ),
                      ],
                    ),
                    // Service Details
                    _InfoSection(
                      title: 'Service Details',
                      children: [
                        _InfoTile(
                          icon: Icons.attach_money,
                          label: 'Hourly Rate',
                          value: '\$${(workerData['hourlyRate'] ?? 0).toStringAsFixed(0)}/hour',
                        ),
                        _InfoTile(
                          icon: Icons.work,
                          label: 'Total Jobs Completed',
                          value: '${earnings['totalJobs']}',
                        ),
                        if (workerData['level'] != null)
                          _InfoTile(
                            icon: Icons.trending_up,
                            label: 'Level',
                            value: (workerData['level'] as String).toUpperCase(),
                            valueColor: AppColors.primary,
                          ),
                        if (workerData['yearsOfExperience'] != null)
                          _InfoTile(
                            icon: Icons.calendar_today,
                            label: 'Experience',
                            value: '${workerData['yearsOfExperience']} years',
                          ),
                      ],
                    ),
                    // Skills
                    if (workerData['skills'] != null && (workerData['skills'] as List).isNotEmpty)
                      _InfoSection(
                        title: 'Skills',
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: (workerData['skills'] as List)
                                  .map(
                                    (skill) => Chip(
                                      label: Text(skill.toString()),
                                      backgroundColor: AppColors.primary.withOpacity(0.1),
                                      labelStyle: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    // About
                    if (workerData['description'] != null && workerData['description'].toString().isNotEmpty)
                      _InfoSection(
                        title: 'About',
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              workerData['description'],
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    // Edit Profile Button
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditProfileScreen(
                                  workerData: workerData,
                                  userId: currentUser.uid,
                                ),
                              ),
                            ).then((_) {
                              // Refresh profile when returning
                              setState(() {});
                            });
                          },
                          icon: const Icon(Iconsax.edit_2, size: 24),
                          label: const Text(
                            'Edit Profile',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
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

  bool _isProfileIncomplete(Map<String, dynamic> workerData) {
    // Check for required fields
    String? phone = workerData['phone'];
    String? location = workerData['location'];
    String? category = workerData['category'];
    double? hourlyRate = workerData['hourlyRate'];
    String? description = workerData['description'];
    List? skills = workerData['skills'];

    return phone == null || 
           phone.isEmpty || 
           location == null || 
           location.isEmpty ||
           category == null || 
           category.isEmpty ||
           hourlyRate == null ||
           hourlyRate == 0 ||
           description == null ||
           description.isEmpty ||
           skills == null ||
           skills.isEmpty;
  }

  Widget _buildIncompleteProfile(BuildContext context, User currentUser, Map<String, dynamic> workerData) {
    return SingleChildScrollView(
      child: Column(
        children: [
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
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(
                    workerData['profileImage'] ?? 
                    currentUser.photoURL ??
                    'https://ui-avatars.com/api/?name=${Uri.encodeComponent(workerData['name'] ?? currentUser.displayName ?? 'Worker')}&background=2563EB&color=fff',
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  workerData['name'] ?? currentUser.displayName ?? 'Worker',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.accent),
              ),
              child: Column(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 48, color: AppColors.accent),
                  const SizedBox(height: 16),
                  const Text(
                    'Complete Your Profile',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add your information to start getting job requests',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Missing: ${_getMissingFields(workerData).join(', ')}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditProfileScreen(
                              workerData: workerData,
                              userId: currentUser.uid,
                            ),
                          ),
                        ).then((_) {
                          // Refresh when returning
                          setState(() {});
                        });
                      },
                      icon: const Icon(Iconsax.add_circle, size: 24),
                      label: const Text(
                        'Complete Profile',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _InfoSection(
            title: 'Current Information',
            children: [
              _InfoTile(
                icon: Icons.email,
                label: 'Email',
                value: currentUser.email ?? 'N/A',
              ),
              if (workerData['phone'] != null && workerData['phone'].toString().isNotEmpty)
                _InfoTile(
                  icon: Icons.phone,
                  label: 'Phone',
                  value: workerData['phone'],
                ),
              if (workerData['location'] != null && workerData['location'].toString().isNotEmpty)
                _InfoTile(
                  icon: Icons.location_on,
                  label: 'Location',
                  value: workerData['location'],
                ),
            ],
          ),
        ],
      ),
    );
  }

  List<String> _getMissingFields(Map<String, dynamic> workerData) {
    List<String> missing = [];
    if (workerData['phone'] == null || workerData['phone'].toString().isEmpty) {
      missing.add('Phone');
    }
    if (workerData['location'] == null || workerData['location'].toString().isEmpty) {
      missing.add('Location');
    }
    if (workerData['category'] == null || workerData['category'].toString().isEmpty) {
      missing.add('Service Category');
    }
    if (workerData['hourlyRate'] == null || workerData['hourlyRate'] == 0) {
      missing.add('Hourly Rate');
    }
    if (workerData['description'] == null || workerData['description'].toString().isEmpty) {
      missing.add('Description');
    }
    if (workerData['skills'] == null || (workerData['skills'] as List).isEmpty) {
      missing.add('Skills');
    }
    return missing;
  }

  Widget _buildBasicProfile(BuildContext context, User currentUser) {
    return SingleChildScrollView(
      child: Column(
        children: [
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
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(
                    currentUser.photoURL ??
                    'https://ui-avatars.com/api/?name=${Uri.encodeComponent(currentUser.displayName ?? 'Worker')}&background=2563EB&color=fff',
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  currentUser.displayName ?? 'Worker',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  currentUser.email ?? '',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Icon(Icons.info_outline, size: 48, color: AppColors.textSecondary),
                  SizedBox(height: 16),
                  Text(
                    'Complete your profile',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Update your profile information to start getting job requests',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
                  ),
                  const SizedBox(height: 20),
                  _InfoSection(
                    title: 'Account Information',
                    children: [
                      _InfoTile(
                        icon: Icons.email,
                        label: 'Email',
                        value: currentUser.email ?? 'N/A',
                      ),
                      _InfoTile(
                        icon: Icons.calendar_today,
                        label: 'Member Since',
                        value: currentUser.metadata.creationTime != null
                            ? '${currentUser.metadata.creationTime!.month}/${currentUser.metadata.creationTime!.year}'
                            : 'N/A',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProfileScreen(
                                workerData: {},
                                userId: currentUser.uid,
                              ),
                            ),
                          ).then((_) {
                            // Refresh when returning
                            setState(() {});
                          });
                        },
                        icon: const Icon(Iconsax.add_circle, size: 24),
                        label: const Text(
                          'Complete Profile',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),
        ],
      ),
    );
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
      padding: const EdgeInsets.all(20),
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
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: valueColor ?? AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


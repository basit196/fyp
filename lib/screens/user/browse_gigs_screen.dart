import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/gig.dart';
import '../../utils/constants.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../services/chat_service.dart';
import '../../widgets/level_badge.dart';
import '../../models/worker.dart';
import 'gig_detail_screen.dart';
import 'user_jobs_screen.dart';
import 'user_profile_screen.dart';
import 'ai_search_screen.dart';
import '../chat/chat_list_screen.dart';
import '../notifications/notifications_screen.dart';

class BrowseGigsScreen extends StatefulWidget {
  const BrowseGigsScreen({super.key});

  @override
  State<BrowseGigsScreen> createState() => _BrowseGigsScreenState();
}

class _BrowseGigsScreenState extends State<BrowseGigsScreen> {
  String _selectedCategory = 'All';
  /// 'All' = all locations (default), 'NearMe' = within 30 km (requires GPS)
  String _locationFilterMode = 'All';
  double? _userLatitude;
  double? _userLongitude;
  final TextEditingController _searchController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> _getGigsStream() {
    if (_selectedCategory == 'All') {
      return _firestoreService.getAllGigs();
    } else if (_selectedCategory == 'Others') {
      // For "Others", we'll fetch all gigs and filter client-side
      return _firestoreService.getAllGigs();
    } else {
      return _firestoreService.getGigsByCategory(_selectedCategory);
    }
  }

  // Get list of predefined category names
  List<String> get _predefinedCategories {
    return WorkerCategories.categories.map((cat) => cat['name'] as String).toList();
  }

  // Check if a category is custom (not in predefined list)
  bool _isCustomCategory(String category) {
    return !_predefinedCategories.contains(category);
  }

  List<DocumentSnapshot> _filterBySearch(List<DocumentSnapshot> docs) {
    if (_searchController.text.isEmpty) {
      return docs;
    }
    
    final query = _searchController.text.toLowerCase();
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final title = (data['title'] ?? '').toString().toLowerCase();
      final description = (data['description'] ?? '').toString().toLowerCase();
      final category = (data['category'] ?? '').toString().toLowerCase();
      
      return title.contains(query) ||
          description.contains(query) ||
          category.contains(query);
    }).toList();
  }

  static const double _nearMeRadiusKm = 30.0;

  List<DocumentSnapshot> _filterByLocation(List<DocumentSnapshot> docs) {
    if (_locationFilterMode != 'NearMe' || _userLatitude == null || _userLongitude == null) {
      return docs;
    }
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final gigLat = (data['latitude'] as num?)?.toDouble();
      final gigLng = (data['longitude'] as num?)?.toDouble();
      if (gigLat == null || gigLng == null) return false;
      final distanceMeters = Geolocator.distanceBetween(
        _userLatitude!,
        _userLongitude!,
        gigLat,
        gigLng,
      );
      final distanceKm = distanceMeters / 1000.0;
      return distanceKm <= _nearMeRadiusKm;
    }).toList();
  }

  Future<void> _showFilterSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter by location',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'By default all locations are shown. Turn on GPS and select "Near me" to find workers within 30 km.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    _locationFilterMode == 'All' ? Iconsax.tick_circle5 : Iconsax.location,
                    color: _locationFilterMode == 'All' ? AppColors.primary : AppColors.textSecondary,
                  ),
                  title: const Text('All locations'),
                  subtitle: const Text('Show services from everywhere'),
                  onTap: () {
                    setState(() {
                      _locationFilterMode = 'All';
                      _userLatitude = null;
                      _userLongitude = null;
                    });
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    _locationFilterMode == 'NearMe' ? Iconsax.tick_circle5 : Iconsax.gps,
                    color: _locationFilterMode == 'NearMe' ? AppColors.primary : AppColors.textSecondary,
                  ),
                  title: const Text('Near me (within 30 km)'),
                  subtitle: const Text('Turn on GPS to find workers nearby'),
                  onTap: () async {
                    Navigator.pop(context);
                    final position = await _getUserLocationForFilter();
                    if (position != null && mounted) {
                      setState(() {
                        _locationFilterMode = 'NearMe';
                        _userLatitude = position.latitude;
                        _userLongitude = position.longitude;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<Position?> _getUserLocationForFilter() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enable location services (GPS) to use "Near me".'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return null;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission is required for "Near me" filter.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return null;
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Showing workers within 30 km'),
            backgroundColor: AppColors.secondary,
          ),
        );
      }
      return position;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not get location: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return null;
    }
  }

  Gig _documentToGig(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    Timestamp? createdAtTimestamp = data['createdAt'] as Timestamp?;
    
    return Gig(
      id: doc.id,
      workerId: data['workerId'] ?? '',
      workerName: data['workerName'] ?? 'Worker',
      workerImage: data['workerImage'] ?? 'https://ui-avatars.com/api/?name=Worker&background=2563EB&color=fff',
      title: data['title'] ?? 'Untitled',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      hourlyRate: (data['hourlyRate'] ?? 0).toDouble(),
      minHours: data['minHours'] ?? 1,
      maxHours: data['maxHours'] ?? 8,
      rating: (data['rating'] ?? 0.0).toDouble(),
      totalOrders: data['totalOrders'] ?? 0,
      skills: data['skills'] != null ? List<String>.from(data['skills']) : [],
      requirements: data['requirements'] != null ? List<String>.from(data['requirements']) : [],
      location: data['location'] ?? 'Location not specified',
      isAvailable: data['isAvailable'] ?? true,
      createdAt: createdAtTimestamp?.toDate() ?? DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: FutureBuilder<Map<String, dynamic>?>(
          future: FirebaseAuth.instance.currentUser != null
              ? AuthService().getUserData(FirebaseAuth.instance.currentUser!.uid)
              : Future.value(null),
          builder: (context, snapshot) {
            final name = snapshot.data?['name'] as String? ??
                FirebaseAuth.instance.currentUser?.displayName ??
                'User';
            return Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            );
          },
        ),
        leading: IconButton(
          icon: const Icon(Iconsax.user, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const UserProfileScreen(),
              ),
            );
          },
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
                      FirebaseAuth.instance.currentUser?.uid ?? '',
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
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Iconsax.briefcase, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserJobsScreen(),
                  ),
                );
              },
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
                    stream: NotificationService().getUnreadCountStream(
                      FirebaseAuth.instance.currentUser?.uid ?? '',
                    ),
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
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 16),
                onChanged: (value) {
                  setState(() {});
                },
                decoration: InputDecoration(
                  hintText: 'Search services...',
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary.withOpacity(0.6),
                  ),
                  prefixIcon: const Icon(
                    Iconsax.search_normal_1,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Iconsax.magicpen,
                          color: AppColors.accent,
                          size: 24,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AISearchScreen(),
                            ),
                          );
                        },
                        tooltip: 'AI Search',
                      ),
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(
                            Iconsax.close_circle,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                            });
                          },
                        ),
                    ],
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Browse Services',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Categories
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _CategoryChip(
                  label: 'All',
                  isSelected: _selectedCategory == 'All',
                      onTap: () {
                    setState(() {
                      _selectedCategory = 'All';
                    });
                  },
                ),
                ...WorkerCategories.categories.map((cat) => _CategoryChip(
                      label: cat['name'] as String,
                      isSelected: _selectedCategory == cat['name'],
                      onTap: () {
                        setState(() {
                          _selectedCategory = cat['name'] as String;
                        });
                      },
                    )),
                _CategoryChip(
                  label: 'Others',
                  isSelected: _selectedCategory == 'Others',
                  onTap: () {
                    setState(() {
                      _selectedCategory = 'Others';
                    });
                  },
                ),
              ],
            ),
          ),
          // Gigs List (Real-time from Firebase)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getGigsStream(),
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
                          Iconsax.warning_2,
                          size: 64,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading services',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
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
                          Iconsax.briefcase,
                          size: 80,
                          color: AppColors.textSecondary.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No services available',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Check back later for new services',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Filter by category (if "Others" is selected, filter for custom categories)
                List<DocumentSnapshot> categoryFiltered = snapshot.data!.docs;
                if (_selectedCategory == 'Others') {
                  categoryFiltered = categoryFiltered.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final category = data['category'] ?? '';
                    return _isCustomCategory(category);
                  }).toList();
                }
                
                // Filter by search query
                List<DocumentSnapshot> filteredDocs = _filterBySearch(categoryFiltered);
                // Filter by location: All or Near me (30 km radius, requires GPS)
                filteredDocs = _filterByLocation(filteredDocs);
                
                // Sort by createdAt (newest first) - client-side sorting
                filteredDocs.sort((a, b) {
                  Timestamp? aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                  Timestamp? bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                  if (aTime == null && bTime == null) return 0;
                  if (aTime == null) return 1;
                  if (bTime == null) return -1;
                  return bTime.compareTo(aTime); // Descending (newest first)
                });

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Iconsax.search_normal,
                          size: 80,
                          color: AppColors.textSecondary.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No services found',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Try a different search or category',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Results Count + Filter (location: All / Near me 30 km)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${filteredDocs.length} Services Available',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _showFilterSheet,
                            icon: Icon(
                              Iconsax.filter,
                              size: 18,
                              color: _locationFilterMode == 'NearMe' ? AppColors.primary : null,
                            ),
                            label: Text(
                              _locationFilterMode == 'NearMe' ? 'Near me (30 km)' : 'Filter',
                              style: TextStyle(
                                fontWeight: _locationFilterMode == 'NearMe' ? FontWeight.w600 : null,
                                color: _locationFilterMode == 'NearMe' ? AppColors.primary : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Gigs List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          bottom: 100,
                        ),
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          final gig = _documentToGig(filteredDocs[index]);
                          return _GigCard(
                            gig: gig,
                            gigData: filteredDocs[index].data() as Map<String, dynamic>,
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Helper function to parse level string to WorkerLevel enum
WorkerLevel _parseLevel(String? levelStr) {
  if (levelStr == null) return WorkerLevel.newbie;
  switch (levelStr.toLowerCase()) {
    case 'professional':
      return WorkerLevel.professional;
    case 'expert':
      return WorkerLevel.expert;
    default:
      return WorkerLevel.newbie;
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _GigCard extends StatelessWidget {
  final Gig gig;
  final Map<String, dynamic> gigData;

  const _GigCard({
    required this.gig,
    required this.gigData,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GigDetailScreen(gig: gig),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundImage: NetworkImage(gig.workerImage),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          gig.workerName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Iconsax.star1, size: 14, color: AppColors.accent),
                            const SizedBox(width: 4),
                            Text(
                              '${gig.rating} (${gig.totalOrders})',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (gigData['level'] != null)
                              LevelBadge(
                                level: _parseLevel(gigData['level']),
                                size: 10,
                              ),
                            if (gig.location.isNotEmpty && gig.location != 'Not specified') ...[
                              const SizedBox(width: 8),
                              Icon(Iconsax.location, size: 12, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                gig.location,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ],
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
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      gig.category,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                gig.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                gig.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 12),
            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Starting at',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${gig.hourlyRate}/hr',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Until complete',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


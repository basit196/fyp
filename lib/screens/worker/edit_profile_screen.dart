import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconsax/iconsax.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../models/worker.dart';
import '../../utils/constants.dart';
import '../../services/firestore_service.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> workerData;
  final String userId;

  const EditProfileScreen({
    super.key,
    required this.workerData,
    required this.userId,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;
  late TextEditingController _descriptionController;
  late TextEditingController _yearsOfExperienceController;
  late String _selectedLevel;
  bool _isLoading = false;
  bool _isGettingLocation = false;
  double? _savedLatitude;
  double? _savedLongitude;

  @override
  void initState() {
    super.initState();
    final currentUser = _auth.currentUser;
    final data = widget.workerData;
    
    _nameController = TextEditingController(text: data['name'] ?? currentUser?.displayName ?? '');
    _emailController = TextEditingController(text: data['email'] ?? currentUser?.email ?? '');
    _phoneController = TextEditingController(text: data['phone'] ?? '');
    _locationController = TextEditingController(text: data['location'] ?? '');
    _descriptionController = TextEditingController(text: data['description'] ?? '');
    _yearsOfExperienceController = TextEditingController(
      text: (data['yearsOfExperience'] ?? 0).toString(),
    );
    _selectedLevel = data['level'] ?? 'newbie';
    _savedLatitude = (data['latitude'] as num?)?.toDouble();
    _savedLongitude = (data['longitude'] as num?)?.toDouble();
  }

  Future<void> _setLocationFromGps() async {
    setState(() => _isGettingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enable location services'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permission is required to use GPS'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return;
        }
      }
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark p = placemarks.first;
        // Prefer locality (city), then subAdministrativeArea, then administrativeArea
        String city = p.locality ?? p.subAdministrativeArea ?? p.administrativeArea ?? '';
        if (city.isEmpty && p.country != null) city = p.country!;
        if (city.isNotEmpty) {
          _locationController.text = city;
          if (mounted) {
            setState(() {
              _savedLatitude = position.latitude;
              _savedLongitude = position.longitude;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Location set to: $city'),
                backgroundColor: AppColors.secondary,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not get city name. Enter it manually.'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _yearsOfExperienceController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Location must be set via GPS (field is read-only)
    if (_locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set your location using the Use GPS button'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw 'Please login to continue';
      }

      // Create Worker object
      Worker worker = Worker(
        id: widget.userId,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        profileImage: widget.workerData['profileImage'] ?? 
                      currentUser.photoURL ??
                      'https://ui-avatars.com/api/?name=${Uri.encodeComponent(_nameController.text.trim())}&background=2563EB&color=fff',
        hourlyRate: (widget.workerData['hourlyRate'] as num?)?.toDouble(),
        description: _descriptionController.text.trim(),
        skills: const [], // Skills are per gig, not on worker profile
        location: _locationController.text.trim(),
        latitude: _savedLatitude ?? (widget.workerData['latitude'] as num?)?.toDouble(),
        longitude: _savedLongitude ?? (widget.workerData['longitude'] as num?)?.toDouble(),
        isAvailable: true, // Always set to true
        level: _selectedLevel == 'professional' 
            ? WorkerLevel.professional 
            : _selectedLevel == 'expert' 
                ? WorkerLevel.expert 
                : WorkerLevel.newbie,
        yearsOfExperience: int.tryParse(_yearsOfExperienceController.text.trim()) ?? 0,
        rating: widget.workerData['rating'] ?? 0.0,
        totalJobs: widget.workerData['totalJobs'] ?? 0,
        completedProjects: widget.workerData['completedProjects'] ?? 0,
        successRate: widget.workerData['successRate'] ?? 100.0,
      );

      // Save to Firebase
      await _firestoreService.saveWorkerProfile(worker);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved successfully!'),
            backgroundColor: AppColors.secondary,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          widget.workerData.isEmpty ? 'Complete Profile' : 'Edit Profile',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        backgroundImage: NetworkImage(
                          widget.workerData['profileImage'] ?? 
                          _auth.currentUser?.photoURL ??
                          'https://ui-avatars.com/api/?name=${Uri.encodeComponent(_auth.currentUser?.displayName ?? 'Worker')}&background=fff&color=2563EB',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.workerData.isEmpty 
                            ? 'Complete Your Profile'
                            : 'Update Your Information',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Fill in your details to start getting job requests',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Personal Information Section
                _buildSectionTitle('Personal Information'),
                const SizedBox(height: 12),
                _buildTextField('Full Name', _nameController, Iconsax.user, required: true),
                const SizedBox(height: 16),
                _buildTextField('Email', _emailController, Iconsax.sms, required: true, enabled: false),
                const SizedBox(height: 16),
                _buildTextField('Phone Number', _phoneController, Iconsax.call, required: true, keyboardType: TextInputType.phone, hintText: 'e.g., +1 234 567 8900'),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildTextField('Location', _locationController, Iconsax.location, required: true, hintText: 'Tap Use GPS to set', enabled: false),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: _isGettingLocation ? null : _setLocationFromGps,
                          icon: _isGettingLocation
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Iconsax.gps, size: 20),
                          label: Text(_isGettingLocation ? '...' : 'Use GPS'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Professional Information Section
                _buildSectionTitle('Professional Information'),
                const SizedBox(height: 12),
                _buildTextField(
                  'Years of Experience',
                  _yearsOfExperienceController,
                  Iconsax.calendar,
                  keyboardType: TextInputType.number,
                  hintText: 'e.g., 5',
                ),
                const SizedBox(height: 16),
                _buildDropdownField(
                  'Experience Level *',
                  _selectedLevel,
                  Iconsax.star,
                  'Select your experience level',
                  const [
                    DropdownMenuItem(value: 'newbie', child: Text('🌱 Newbie')),
                    DropdownMenuItem(value: 'professional', child: Text('⭐ Professional')),
                    DropdownMenuItem(value: 'expert', child: Text('👑 Expert')),
                  ],
                  (value) {
                    setState(() {
                      _selectedLevel = value!;
                    });
                  },
                  required: true,
                ),
                const SizedBox(height: 24),
                // About Section
                _buildSectionTitle('About You'),
                const SizedBox(height: 12),
                _buildTextField(
                  'Description *',
                  _descriptionController,
                  Iconsax.document_text,
                  maxLines: 5,
                  hintText: 'Tell clients about your services, experience, and what makes you unique...',
                  required: true,
                ),
                const SizedBox(height: 24),
                // Save Button
                Container(
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
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _saveProfile,
                      icon: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Iconsax.tick_circle, size: 24),
                      label: Text(
                        _isLoading
                            ? 'Saving...'
                            : widget.workerData.isEmpty
                                ? 'Complete Profile'
                                : 'Save Changes',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        disabledBackgroundColor: AppColors.textSecondary,
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    int maxLines = 1,
    TextInputType? keyboardType,
    String? hintText,
    bool required = false,
    bool enabled = true,
  }) {
    return Container(
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (required) ...[
                  const SizedBox(width: 4),
                  const Text(
                    '*',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextFormField(
              controller: controller,
              maxLines: maxLines,
              keyboardType: keyboardType,
              enabled: enabled,
              validator: required
                  ? (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'This field is required';
                      }
                      return null;
                    }
                  : null,
              decoration: InputDecoration(
                hintText: hintText,
                filled: true,
                fillColor: enabled ? AppColors.background : AppColors.border,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.error, width: 1),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.error, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    String? value,
    IconData icon,
    String hintText,
    List<DropdownMenuItem<String>> items,
    ValueChanged<String?> onChanged, {
    bool required = false,
  }) {
    return Container(
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (required) ...[
                  const SizedBox(width: 4),
                  const Text(
                    '*',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              constraints: const BoxConstraints(minHeight: 52),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: value == null && required
                    ? Border.all(color: AppColors.error, width: 1)
                    : null,
              ),
              alignment: Alignment.centerLeft,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: value,
                  isExpanded: true,
                  hint: Text(
                    hintText,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                  icon: Icon(Iconsax.arrow_down_2, color: AppColors.primary),
                  items: items,
                  onChanged: onChanged,
                  dropdownColor: AppColors.cardBackground,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}




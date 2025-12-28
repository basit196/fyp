import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/gig.dart';
import '../../utils/constants.dart';
import '../../services/firestore_service.dart';

class CreateGigScreen extends StatefulWidget {
  const CreateGigScreen({super.key});

  @override
  State<CreateGigScreen> createState() => _CreateGigScreenState();
}

class _CreateGigScreenState extends State<CreateGigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _skillsController = TextEditingController();
  final _requirementsController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  
  String _selectedCategory = GigCategories.predefined[0];
  String _customCategory = '';
  int _minHours = 1;
  int _maxHours = 8;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _hourlyRateController.dispose();
    _skillsController.dispose();
    _requirementsController.dispose();
    super.dispose();
  }

  void _handleCreateGig() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategory == 'Custom' && _customCategory.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a custom category'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          throw 'Please login to continue';
        }

        // Create gig in Firebase
        await _firestoreService.createGig({
          'workerId': currentUser.uid,
          'workerName': currentUser.displayName ?? 'Worker',
          'workerImage': 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(currentUser.displayName ?? 'Worker')}&background=2563EB&color=fff',
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'category': _selectedCategory == 'Custom' ? _customCategory : _selectedCategory,
          'hourlyRate': double.parse(_hourlyRateController.text.trim()),
          'minHours': _minHours,
          'maxHours': _maxHours,
          'skills': _skillsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
          'requirements': _requirementsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
          'location': 'Location', // Add location field if needed
        });

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gig created successfully! 🎉'),
              backgroundColor: AppColors.secondary,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Create New Gig', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                _buildSectionTitle('Gig Title'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  decoration: _inputDecoration(
                    'e.g., Professional Electrical Services',
                    Iconsax.edit,
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Please enter a title' : null,
                ),
                const SizedBox(height: 20),
                
                // Category
                _buildSectionTitle('Category'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      icon: const Icon(Iconsax.arrow_down_1),
                      items: GigCategories.predefined
                          .map((cat) => DropdownMenuItem(
                                value: cat,
                                child: Text(cat),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                    ),
                  ),
                ),
                if (_selectedCategory == 'Custom') ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: _inputDecoration(
                      'Enter custom category',
                      Iconsax.category,
                    ),
                    onChanged: (value) => _customCategory = value,
                    validator: (value) => _selectedCategory == 'Custom' &&
                            (value?.isEmpty ?? true)
                        ? 'Please enter category'
                        : null,
                  ),
                ],
                const SizedBox(height: 20),
                
                // Description
                _buildSectionTitle('Description'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 5,
                  decoration: _inputDecoration(
                    'Describe your service in detail...',
                    Iconsax.document_text,
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Please enter description' : null,
                ),
                const SizedBox(height: 20),
                
                // Hourly Rate
                _buildSectionTitle('Hourly Rate (\$)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _hourlyRateController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(
                    'e.g., 50',
                    Iconsax.dollar_circle,
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Please enter rate';
                    final rate = double.tryParse(value!);
                    if (rate == null || rate <= 0) return 'Invalid rate';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                
                // Hours Range
                _buildSectionTitle('Hours Range'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Minimum Hours'),
                                const SizedBox(height: 8),
                                Text(
                                  '$_minHours hours',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Maximum Hours'),
                                const SizedBox(height: 8),
                                Text(
                                  '$_maxHours hours',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Slider(
                                  value: _minHours.toDouble(),
                                  min: 1,
                                  max: 12,
                                  divisions: 11,
                                  activeColor: AppColors.primary,
                                  onChanged: (value) {
                                    setState(() {
                                      _minHours = value.toInt();
                                      if (_minHours > _maxHours) {
                                        _maxHours = _minHours;
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              children: [
                                Slider(
                                  value: _maxHours.toDouble(),
                                  min: 1,
                                  max: 12,
                                  divisions: 11,
                                  activeColor: AppColors.primary,
                                  onChanged: (value) {
                                    setState(() {
                                      _maxHours = value.toInt();
                                      if (_maxHours < _minHours) {
                                        _minHours = _maxHours;
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Skills
                _buildSectionTitle('Skills (comma separated)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _skillsController,
                  decoration: _inputDecoration(
                    'e.g., Wiring, Installation, Repair',
                    Iconsax.star,
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Please enter skills' : null,
                ),
                const SizedBox(height: 20),
                
                // Requirements
                _buildSectionTitle('Requirements (comma separated)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _requirementsController,
                  decoration: _inputDecoration(
                    'e.g., Licensed, Insured, 10+ years',
                    Iconsax.task_square,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Create Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleCreateGig,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Create Gig',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
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
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.primary),
      filled: true,
      fillColor: AppColors.cardBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
    );
  }
}


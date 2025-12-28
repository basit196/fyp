import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/gig.dart';
import '../../utils/constants.dart';
import 'gig_detail_screen.dart';

class AISearchScreen extends StatefulWidget {
  const AISearchScreen({super.key});

  @override
  State<AISearchScreen> createState() => _AISearchScreenState();
}

class _AISearchScreenState extends State<AISearchScreen> {
  final TextEditingController _queryController = TextEditingController();
  bool _isSearching = false;
  List<DocumentSnapshot> _suggestedGigs = [];
  String? _errorMessage;

  // Replace with your actual Gemini API key
  // You can get it from: https://makersuite.google.com/app/apikey
  static const String _geminiApiKey = 'AIzaSyBkzgubUQx0o6JfiZYSbqPFuhf8iGAPEBA';

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _performAISearch() async {
    if (_queryController.text.trim().isEmpty) {
      return;
    }

    setState(() {
      _isSearching = true;
      _suggestedGigs = [];
      _errorMessage = null;
    });

    try {
      // Get all available gigs from Firebase
      QuerySnapshot allGigs = await FirebaseFirestore.instance
          .collection('gigs')
          .where('isAvailable', isEqualTo: true)
          .get();

      if (allGigs.docs.isEmpty) {
        setState(() {
          _isSearching = false;
          _errorMessage = 'No services available at the moment.';
        });
        return;
      }

      // Prepare gig data for AI
      List<Map<String, dynamic>> gigsData = allGigs.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'title': data['title'] ?? '',
          'description': data['description'] ?? '',
          'category': data['category'] ?? '',
          'skills': data['skills'] ?? [],
          'workerName': data['workerName'] ?? '',
        };
      }).toList();

      // Create prompt for AI
      String prompt = '''
You are a service matching assistant. A user has the following request:
"${_queryController.text.trim()}"

Here are the available services (gigs) in the database:
${gigsData.map((gig) => 
  '- Title: ${gig['title']}\n  Category: ${gig['category']}\n  Description: ${gig['description']}\n  Skills: ${(gig['skills'] as List).join(', ')}\n  Worker: ${gig['workerName']}\n  ID: ${gig['id']}'
).join('\n\n')}

Based on the user's request, identify which services are most relevant. 
Return ONLY a JSON array of service IDs that match the user's need, in order of relevance (most relevant first).
Format: ["id1", "id2", "id3"]
If no services match, return an empty array: []
''';

      // Get AI response using direct HTTP call
      print('🔍 Sending request to Gemini AI...');
      print('📝 User Query: ${_queryController.text.trim()}');
      print('📊 Total Gigs Available: ${gigsData.length}');
      
      // Make HTTP request to Gemini API
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent?key=$_geminiApiKey'
      );
      
      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ]
      };
      
      print('🌐 API URL: $url');
      print('📤 Request Body: ${jsonEncode(requestBody)}');
      
      final httpResponse = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );
      
      print('✅ HTTP Response Status: ${httpResponse.statusCode}');
      print('📄 Raw Response Body: ${httpResponse.body}');
      
      if (httpResponse.statusCode != 200) {
        throw Exception('API Error: ${httpResponse.statusCode} - ${httpResponse.body}');
      }
      
      final responseData = jsonDecode(httpResponse.body) as Map<String, dynamic>;
      print('📊 Parsed Response: $responseData');
      
      // Extract text from response
      String aiText = '[]';
      if (responseData.containsKey('candidates') && 
          (responseData['candidates'] as List).isNotEmpty) {
        final candidate = (responseData['candidates'] as List)[0] as Map<String, dynamic>;
        if (candidate.containsKey('content')) {
          final content = candidate['content'] as Map<String, dynamic>;
          if (content.containsKey('parts') && (content['parts'] as List).isNotEmpty) {
            final part = (content['parts'] as List)[0] as Map<String, dynamic>;
            aiText = part['text'] ?? '[]';
          }
        }
      }
      
      print('📝 Extracted AI Text: $aiText');

      // Parse AI response to get relevant gig IDs
      // Clean the response (remove markdown code blocks if present)
      aiText = aiText.trim();
      print('📝 Initial AI Text: $aiText');
      
      if (aiText.startsWith('```')) {
        print('🧹 Removing markdown code blocks...');
        final parts = aiText.split('```');
        if (parts.length > 1) {
          aiText = parts[1];
          if (aiText.startsWith('json')) {
            aiText = aiText.substring(4);
          }
          aiText = aiText.trim();
        }
        print('📝 After cleaning: $aiText');
      }
      
      // Try to extract JSON array from the response
      List<String> ids = [];
      
      // Method 1: Direct JSON array
      if (aiText.startsWith('[') && aiText.endsWith(']')) {
        print('✅ Response is a valid JSON array');
        try {
          final jsonString = aiText;
          ids = jsonString
              .substring(1, jsonString.length - 1)
              .split(',')
              .map((s) => s.trim().replaceAll('"', '').replaceAll("'", '').replaceAll('`', ''))
              .where((s) => s.isNotEmpty)
              .toList();
        } catch (e) {
          print('❌ Error parsing JSON array: $e');
        }
      } 
      // Method 2: Look for IDs in the text (extract any document IDs mentioned)
      else {
        print('⚠️ Response is not a direct JSON array, trying to extract IDs...');
        // Try to find IDs in the response text
        for (var doc in allGigs.docs) {
          if (aiText.contains(doc.id)) {
            ids.add(doc.id);
          }
        }
        // If still no IDs found, look for category matches
        if (ids.isEmpty) {
          print('🔍 No IDs found, trying category matching...');
          final queryLower = _queryController.text.toLowerCase();
          final aiTextLower = aiText.toLowerCase();
          for (var doc in allGigs.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final category = (data['category'] ?? '').toString().toLowerCase();
            final title = (data['title'] ?? '').toString().toLowerCase();
            
            // Check if AI response mentions this category/title
            if (aiTextLower.contains(category) ||
                aiTextLower.contains(title) ||
                queryLower.contains(category)) {
              ids.add(doc.id);
            }
          }
        }
      }
      
      print('🆔 Extracted IDs: $ids');
      print('📊 Number of IDs found: ${ids.length}');

      // Get suggested gigs based on AI recommendations
      _suggestedGigs = allGigs.docs
          .where((doc) => ids.contains(doc.id))
          .toList();
      
      print('✅ Matched Gigs from AI: ${_suggestedGigs.length}');

      // If AI didn't return good matches, do a fallback keyword search
      if (_suggestedGigs.isEmpty) {
        print('⚠️ No matches from AI, using fallback keyword search...');
        _suggestedGigs = _fallbackKeywordSearch(allGigs.docs);
        print('🔍 Fallback results: ${_suggestedGigs.length}');
      }

      setState(() {
        _isSearching = false;
      });
    } catch (e, stackTrace) {
      print('❌ Error in AI search: $e');
      print('📚 Stack trace: $stackTrace');
      // Fallback to keyword-based search if AI fails
      try {
        print('🔄 Attempting fallback keyword search...');
        QuerySnapshot allGigs = await FirebaseFirestore.instance
            .collection('gigs')
            .where('isAvailable', isEqualTo: true)
            .get();
        _suggestedGigs = _fallbackKeywordSearch(allGigs.docs);
        print('✅ Fallback search completed: ${_suggestedGigs.length} results');
        setState(() {
          _isSearching = false;
        });
      } catch (fallbackError) {
        print('❌ Fallback search also failed: $fallbackError');
        setState(() {
          _errorMessage = 'Error searching: ${e.toString()}';
          _isSearching = false;
        });
      }
    }
  }

  List<DocumentSnapshot> _fallbackKeywordSearch(List<DocumentSnapshot> allGigs) {
    final query = _queryController.text.toLowerCase();
    final keywords = query.split(' ').where((w) => w.length > 2).toList();

    return allGigs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final title = (data['title'] ?? '').toString().toLowerCase();
      final description = (data['description'] ?? '').toString().toLowerCase();
      final category = (data['category'] ?? '').toString().toLowerCase();
      final skillsList = data['skills'] ?? [];
      final skills = (skillsList as List)
          .map((s) => s.toString().toLowerCase())
          .toList();

      // Check if any keyword matches
      for (var keyword in keywords) {
        if (title.contains(keyword) ||
            description.contains(keyword) ||
            category.contains(keyword) ||
            skills.any((s) => s.contains(keyword))) {
          return true;
        }
      }
      return false;
    }).toList();
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
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'AI Search',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // AI Search Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                Container(
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
                    controller: _queryController,
                    style: const TextStyle(fontSize: 16),
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Describe what you need...\nExample: "My car is not working, I want to repair it"',
                      hintStyle: TextStyle(
                        color: AppColors.textSecondary.withOpacity(0.6),
                      ),
                      prefixIcon: const Icon(
                        Iconsax.magic_star,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      suffixIcon: _queryController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Iconsax.close_circle,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () {
                                setState(() {
                                  _queryController.clear();
                                });
                              },
                            )
                          : null,
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
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSearching ? null : _performAISearch,
                    icon: _isSearching
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Iconsax.search_normal_1),
                    label: Text(_isSearching ? 'Searching...' : 'Search with AI'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
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
          // Results
          Expanded(
            child: _buildResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
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
              _errorMessage!,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_suggestedGigs.isEmpty && _queryController.text.isNotEmpty) {
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
              'No matching services found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try rephrasing your request',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_suggestedGigs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.magic_star,
              size: 80,
              color: AppColors.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            const Text(
              'AI-Powered Search',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Describe what you need in natural language, and AI will find the best matching services for you.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_suggestedGigs.length} Services Found',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Iconsax.magic_star,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'AI Matched',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: 100,
            ),
            itemCount: _suggestedGigs.length,
            itemBuilder: (context, index) {
              final gig = _documentToGig(_suggestedGigs[index]);
              return _GigCard(
                gig: gig,
                gigData: _suggestedGigs[index].data() as Map<String, dynamic>,
              );
            },
          ),
        ),
      ],
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
                    '${gig.minHours}-${gig.maxHours} hours',
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


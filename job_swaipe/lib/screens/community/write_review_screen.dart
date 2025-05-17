import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../models/company_review.dart';
import '../../services/company_service.dart';
import '../../services/auth_service.dart';

class WriteReviewScreen extends StatefulWidget {
  final String? companyId;
  final String? companyName;
  
  const WriteReviewScreen({
    super.key, 
    this.companyId,
    this.companyName,
  });

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  final CompanyService _companyService = CompanyService();
  final AuthService _authService = AuthService();
  final Uuid _uuid = const Uuid();
  final _formKey = GlobalKey<FormState>();
  
  // Search related
  final _searchController = TextEditingController();
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];
  
  // Form fields
  String _selectedCompanyId = '';
  String _selectedCompanyName = '';
  final _jobTitleController = TextEditingController();
  final _salaryController = TextEditingController();
  final _reviewController = TextEditingController();
  final _prosController = TextEditingController();
  final _consController = TextEditingController();
  double _rating = 3.0;
  bool _isAnonymous = true;
  bool _wouldRecommend = true;
  
  // Custom aspects rating
  final Map<String, int> _aspectRatings = {};
  final _newAspectController = TextEditingController();
  
  // Custom tags support
  final List<String> _selectedTags = [];
  final _newTagController = TextEditingController();
  
  // Pre-defined tags
  final List<String> _availableTags = [
    'toxic', 'fun', 'work-life balance', 'good pay',
    'career growth', 'learning opportunities', 'poor management',
    'great culture', 'stressful', 'flexible', 'remote-friendly'
  ];
  
  bool _isSubmitting = false;
  bool _isConnected = true;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    
    // If company information was passed to the screen
    if (widget.companyId != null && widget.companyName != null) {
      _selectedCompanyId = widget.companyId!;
      _selectedCompanyName = widget.companyName!;
    }
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _jobTitleController.dispose();
    _salaryController.dispose();
    _reviewController.dispose();
    _prosController.dispose();
    _consController.dispose();
    _newAspectController.dispose();
    _newTagController.dispose();
    super.dispose();
  }
  
  // Search for companies
  void _searchCompany(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }
    
    setState(() {
      _isSearching = true;
    });
    
    try {
      final results = await _companyService.searchCompanies(query);
      
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Search failed: ${e.toString()}';
          _isSearching = false;
        });
      }
    }
  }
  
  // Select a company from search results
  void _selectCompany(String id, String name) {
    setState(() {
      _selectedCompanyId = id;
      _selectedCompanyName = name;
      _searchController.text = name;
      _isSearching = false;
      _searchResults = [];
    });
  }
  
  // Toggle tag selection
  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }
  
  // Submit the review
  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_selectedCompanyId.isEmpty || _selectedCompanyName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a company')),
      );
      return;
    }
    
    // Check connectivity first
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No internet connection. Please check your network and try again.')),
      );
      return;
    }
    
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    
    try {
      final user = _authService.getCurrentUser();
      
      // Get device ID for anonymous reviews
      String? deviceId;
      if (_isAnonymous) {
        try {
          deviceId = await _authService.getDeviceId();
        } catch (e) {
          // If device ID retrieval fails, generate a temporary one
          deviceId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
          print('Using temporary device ID: $e');
        }
      }
      
      final review = CompanyReview(
        id: _uuid.v4(),
        companyId: _selectedCompanyId,
        companyName: _selectedCompanyName,
        jobTitle: _jobTitleController.text.trim(),
        rating: _rating,
        reviewText: _reviewController.text.trim(),
        pros: _prosController.text.trim(),
        cons: _consController.text.trim(),
        wouldRecommend: _wouldRecommend,
        ceoApproval: null,
        salary: _salaryController.text.trim(),
        tags: _selectedTags,
        emojiRatings: _aspectRatings,
        createdAt: DateTime.now(),
        isAnonymous: _isAnonymous,
        userId: _isAnonymous ? null : user?.uid,
        userDisplayName: _isAnonymous ? null : user?.email?.split('@').first,
        deviceId: _isAnonymous ? deviceId : null, // Store device ID only for anonymous reviews
      );
      
      // Add timeout to prevent indefinite waiting
      await _companyService.addCompanyReview(review)
        .timeout(const Duration(seconds: 15), 
          onTimeout: () {
            throw 'Review submission is taking too long. Please try again later.';
          });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review submitted successfully'),
            duration: Duration(seconds: 2),
          ),
        );
        
        // Navigate back to the main Community screen
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.toString().contains('timed out') 
            ? 'Review submission timed out. Check your internet connection.' 
            : 'Failed to submit review: ${e.toString()}';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Write Company Review'),
        elevation: 0,
      ),
      body: _isSubmitting
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('Submitting your review...', style: theme.textTheme.bodyLarge),
                ],
              ),
            )
          : Form(
              key: _formKey,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colorScheme.primary.withOpacity(0.05),
                      Colors.white,
                    ],
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Company selection card
                      Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: _selectedCompanyId.isEmpty
                              ? _buildCompanySearch()
                              : _buildSelectedCompany(),
                        ),
                      ),
                      
                      // Overall Rating card
                      Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Overall Rating', 
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                              const SizedBox(height: 16),
                              Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    5,
                                    (index) => GestureDetector(
                                      onTap: () => setState(() => _rating = index + 1.0),
                                      child: Icon(
                                        index < _rating ? Icons.star : Icons.star_border,
                                        color: Colors.amber,
                                        size: 40,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    _getRatingDescription(_rating),
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Job Details card
                      Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Your Job Details', 
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Job Title
                              TextFormField(
                                controller: _jobTitleController,
                                decoration: InputDecoration(
                                  labelText: 'Job Title',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  prefixIcon: const Icon(Icons.work),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your job title';
                                  }
                                  return null;
                                },
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Salary Range
                              TextFormField(
                                controller: _salaryController,
                                decoration: InputDecoration(
                                  labelText: 'Salary Range (Optional)',
                                  hintText: 'e.g. RM 5,000 - RM 7,000',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  prefixIcon: const Icon(Icons.attach_money),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Pros and Cons card
                      Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Pros & Cons', 
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Pros
                              TextFormField(
                                controller: _prosController,
                                decoration: InputDecoration(
                                  labelText: 'Pros',
                                  hintText: 'What did you like about working here?',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  prefixIcon: const Icon(Icons.thumb_up, color: Colors.green),
                                ),
                                maxLines: 3,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please share at least one pro';
                                  }
                                  return null;
                                },
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Cons
                              TextFormField(
                                controller: _consController,
                                decoration: InputDecoration(
                                  labelText: 'Cons',
                                  hintText: 'What did you dislike about working here?',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  prefixIcon: const Icon(Icons.thumb_down, color: Colors.red),
                                ),
                                maxLines: 3,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please share at least one con';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Additional Review Text card
                      Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Additional Comments', 
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              TextFormField(
                                controller: _reviewController,
                                decoration: InputDecoration(
                                  hintText: 'Share more details about your experience...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                maxLines: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Specific Ratings card
                      Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Rate Specific Aspects', 
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add and rate specific aspects of your experience',
                                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                              ),
                              const SizedBox(height: 16),
                              
                              // Add a new aspect input
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _newAspectController,
                                      decoration: InputDecoration(
                                        hintText: 'Add aspect (e.g., Work Environment, Benefits, etc)',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      final aspect = _newAspectController.text.trim();
                                      if (aspect.isNotEmpty && !_aspectRatings.containsKey(aspect)) {
                                        setState(() {
                                          _aspectRatings[aspect] = 3; // Default to 3 stars
                                          _newAspectController.clear();
                                        });
                                      }
                                    },
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colorScheme.primary,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              // Show existing aspects
                              if (_aspectRatings.isEmpty)
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                                    child: Text(
                                      'No aspects added yet. Add some aspects to rate!',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.grey[600], 
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _aspectRatings.length,
                                  itemBuilder: (context, index) {
                                    final entry = _aspectRatings.entries.elementAt(index);
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12.0),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 5,
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    entry.key,
                                                    style: theme.textTheme.bodyLarge,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.close, size: 18),
                                                  onPressed: () {
                                                    setState(() {
                                                      _aspectRatings.remove(entry.key);
                                                    });
                                                  },
                                                  visualDensity: VisualDensity.compact,
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            flex: 5,
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: List.generate(
                                                5,
                                                (starIndex) => InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      _aspectRatings[entry.key] = starIndex + 1;
                                                    });
                                                  },
                                                  child: Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 2),
                                                    child: Icon(
                                                      starIndex < entry.value ? Icons.star : Icons.star_border,
                                                      size: 24,
                                                      color: Colors.amber,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Recommendations card
                      Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Recommendations', 
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Would Recommend
                              ListTile(
                                title: const Text('Would you recommend working here?'),
                                trailing: Switch(
                                  value: _wouldRecommend,
                                  activeColor: Colors.green,
                                  onChanged: (value) {
                                    setState(() {
                                      _wouldRecommend = value;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Tags card
                      Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Tags', 
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text('Select or add tags that describe this workplace'),
                              const SizedBox(height: 16),
                              
                              // Custom tag input
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _newTagController,
                                      decoration: InputDecoration(
                                        hintText: 'Add custom tag...',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      final tag = _newTagController.text.trim();
                                      if (tag.isNotEmpty && !_selectedTags.contains(tag) && !_availableTags.contains(tag)) {
                                        setState(() {
                                          _selectedTags.add(tag);
                                          _newTagController.clear();
                                        });
                                      }
                                    },
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colorScheme.primary,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              // Predefined tags
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _availableTags.map((tag) {
                                  final isSelected = _selectedTags.contains(tag);
                                  return FilterChip(
                                    label: Text(tag),
                                    selected: isSelected,
                                    onSelected: (_) => _toggleTag(tag),
                                    backgroundColor: Colors.grey.shade200,
                                    selectedColor: colorScheme.primaryContainer,
                                    checkmarkColor: colorScheme.onPrimaryContainer,
                                  );
                                }).toList(),
                              ),
                              
                              // Show selected custom tags (if any)
                              if (_selectedTags.any((tag) => !_availableTags.contains(tag))) ...[
                                const SizedBox(height: 16),
                                const Text('Your custom tags:', style: TextStyle(fontWeight: FontWeight.w500)),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _selectedTags
                                      .where((tag) => !_availableTags.contains(tag))
                                      .map((tag) {
                                        return Chip(
                                          label: Text(tag),
                                          backgroundColor: colorScheme.primaryContainer,
                                          deleteIcon: const Icon(Icons.close, size: 16),
                                          onDeleted: () {
                                            setState(() {
                                              _selectedTags.remove(tag);
                                            });
                                          },
                                        );
                                      }).toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      
                      // Anonymous option card
                      Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: SwitchListTile(
                          title: const Text('Post anonymously'),
                          subtitle: const Text('Your name will not be shown with this review'),
                          value: _isAnonymous,
                          onChanged: (bool value) {
                            setState(() {
                              _isAnonymous = value;
                            });
                          },
                          secondary: Icon(
                            _isAnonymous ? Icons.visibility_off : Icons.visibility,
                            color: _isAnonymous ? Colors.grey : colorScheme.primary,
                          ),
                        ),
                      ),
                      
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: colorScheme.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      
                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _submitReview,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 3,
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                          ),
                          child: const Text('SUBMIT REVIEW', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildCompanySearch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Which company are you reviewing?',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search for a company...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onChanged: _searchCompany,
        ),
        if (_isSearching)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_searchResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _searchResults.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade300),
              itemBuilder: (context, index) {
                final company = _searchResults[index];
                return ListTile(
                  title: Text(company['name']),
                  onTap: () => _selectCompany(company['id'], company['name']),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSelectedCompany() {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            _selectedCompanyName.isNotEmpty ? _selectedCompanyName[0].toUpperCase() : '',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _selectedCompanyName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text('Writing review for this company'),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () {
            setState(() {
              _selectedCompanyId = '';
              _selectedCompanyName = '';
              _searchController.text = '';
            });
          },
        ),
      ],
    );
  }

  String _getRatingDescription(double rating) {
    if (rating >= 4.5) return 'Excellent!';
    if (rating >= 4.0) return 'Very Good';
    if (rating >= 3.0) return 'Average';
    if (rating >= 2.0) return 'Poor';
    return 'Terrible';
  }
}

// Extension to capitalize strings
extension StringExtension on String {
  String toCapitalized() => length > 0 ? '${this[0].toUpperCase()}${substring(1)}' : '';
} 
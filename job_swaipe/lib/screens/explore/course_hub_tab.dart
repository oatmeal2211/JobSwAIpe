import 'package:flutter/material.dart';
import 'package:job_swaipe/models/course.dart';
import 'package:job_swaipe/services/course_service.dart';
import 'package:job_swaipe/screens/explore/my_learning_screen.dart';

class CourseHubTab extends StatefulWidget {
  final List<SkillGap> skillGaps;

  const CourseHubTab({super.key, required this.skillGaps});

  @override
  State<CourseHubTab> createState() => _CourseHubTabState();
}

class _CourseHubTabState extends State<CourseHubTab> {
  final CourseService _courseService = CourseService();
  final TextEditingController _searchController = TextEditingController();
  List<Course> _courses = [];
  List<Course> _filteredCourses = [];
  bool _isLoading = false;
  bool _showOnlyFree = false;
  CourseLevel? _selectedLevel;
  String? _selectedProvider;
  String? _selectedCategory;
  List<String> _providers = [];
  List<String> _categories = [
    'Technology',
    'Business',
    'Design',
    'Marketing',
    'Personal Development',
    'Language Learning',
    'Health & Wellness',
    'Arts & Creativity',
  ];

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final courses = await _courseService.getCourses();
      
      // Extract unique providers
      final providers = courses.map((c) => c.provider).toSet().toList();
      providers.sort();
      
      setState(() {
        _courses = courses;
        _filteredCourses = courses;
        _providers = providers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading courses: ${e.toString()}')),
        );
      }
    }
  }

  void _filterCourses() {
    final searchTerm = _searchController.text.toLowerCase();
    
    setState(() {
      _filteredCourses = _courses.where((course) {
        // Apply search filter
        final matchesSearch = searchTerm.isEmpty ||
            course.title.toLowerCase().contains(searchTerm) ||
            course.description.toLowerCase().contains(searchTerm) ||
            course.skills.any((skill) => skill.toLowerCase().contains(searchTerm));
        
        // Apply free filter
        final matchesFree = !_showOnlyFree || course.isFree;
        
        // Apply level filter
        final matchesLevel = _selectedLevel == null || course.level == _selectedLevel;
        
        // Apply provider filter
        final matchesProvider = _selectedProvider == null || course.provider == _selectedProvider;
        
        // Apply category filter (simplified implementation - would need proper categories in the Course model)
        final matchesCategory = _selectedCategory == null || 
            (_selectedCategory == 'Technology' && _isTechCourse(course));
        
        return matchesSearch && matchesFree && matchesLevel && matchesProvider && matchesCategory;
      }).toList();
    });
  }

  // Simple helper to categorize courses (would be better with proper categories in the model)
  bool _isTechCourse(Course course) {
    final techKeywords = ['programming', 'coding', 'development', 'software', 'web', 'app', 'data', 'computer'];
    return course.skills.any((skill) => 
      techKeywords.any((keyword) => skill.toLowerCase().contains(keyword)));
  }

  Future<void> _searchOnlineCourses(String skillName) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Show a loading message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Searching for courses on "$skillName"...'),
          duration: const Duration(seconds: 2),
        ),
      );

      final onlineCourses = await _courseService.searchOnlineCourses(skillName);
      
      setState(() {
        // Add online courses to the list
        _courses = [..._courses, ...onlineCourses];
        _filterCourses();
        _isLoading = false;
      });
      
      // Extract and add new providers
      final newProviders = onlineCourses.map((c) => c.provider).toSet().toList();
      setState(() {
        _providers = [...{..._providers, ...newProviders}];
      });

      // Show success message
      if (onlineCourses.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Found ${onlineCourses.length} courses for "$skillName"'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching online courses: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCourses,
              child: ListView(
                padding: EdgeInsets.only(bottom: 80),
                children: [
                  // Search Bar with improved UI
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary.withOpacity(0.8),
                          Theme.of(context).colorScheme.primary.withOpacity(0.6),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome message for non-technical users
                        const Text(
                          'Find courses to learn new skills and advance your career',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        
                        // Search Bar with clearer purpose
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search for any skill or topic...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      _filterCourses();
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          onChanged: (_) => _filterCourses(),
                        ),
                      ],
                    ),
                  ),
                  
                  // Quick Filter Pills
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    color: Colors.grey[100],
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          // Free courses filter
                          FilterChip(
                            label: const Text('Free Only'),
                            selected: _showOnlyFree,
                            onSelected: (selected) {
                              setState(() {
                                _showOnlyFree = selected;
                                _filterCourses();
                              });
                            },
                            avatar: _showOnlyFree ? const Icon(Icons.check, size: 18) : null,
                            selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          ),
                          const SizedBox(width: 8),
                          
                          // Level filter as chip
                          ChoiceChip(
                            label: Text(_selectedLevel == null 
                              ? 'All Levels' 
                              : _getLevelDisplayName(_selectedLevel!)),
                            selected: _selectedLevel != null,
                            onSelected: (_) {
                              _showLevelPicker();
                            },
                            selectedColor: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                          ),
                          const SizedBox(width: 8),
                          
                          // Provider filter as chip
                          if (_providers.isNotEmpty)
                            ChoiceChip(
                              label: Text(_selectedProvider == null 
                                ? 'All Providers' 
                                : _selectedProvider!),
                              selected: _selectedProvider != null,
                              onSelected: (_) {
                                _showProviderPicker();
                              },
                              selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                            ),
                          const SizedBox(width: 8),
                          
                          // Category filter as chip
                          ChoiceChip(
                            label: Text(_selectedCategory == null 
                              ? 'All Categories' 
                              : _selectedCategory!),
                            selected: _selectedCategory != null,
                            onSelected: (_) {
                              _showCategoryPicker();
                            },
                            selectedColor: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Skill Suggestions
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.skillGaps.isNotEmpty ? 'Recommended Skills to Learn:' : 'Popular Skills:',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 50,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: widget.skillGaps.isNotEmpty
                                ? widget.skillGaps.map((skillGap) {
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: ActionChip(
                                        label: Text(skillGap.skillName),
                                        avatar: const Icon(Icons.trending_up, size: 16),
                                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                        onPressed: () {
                                          _searchController.text = skillGap.skillName;
                                          _filterCourses();
                                          _searchOnlineCourses(skillGap.skillName);
                                        },
                                      ),
                                    );
                                  }).toList()
                                : _getPopularSkills().map((skill) {
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: ActionChip(
                                        label: Text(skill),
                                        avatar: const Icon(Icons.star, size: 16),
                                        backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                                        onPressed: () {
                                          _searchController.text = skill;
                                          _filterCourses();
                                          _searchOnlineCourses(skill);
                                        },
                                      ),
                                    );
                                  }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Course List
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Available Courses (${_filteredCourses.length})',
                              style: const TextStyle(
                                fontSize: 18, 
                                fontWeight: FontWeight.bold
                              ),
                            ),
                            if (_filteredCourses.isNotEmpty)
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _showOnlyFree = false;
                                    _selectedLevel = null;
                                    _selectedProvider = null;
                                    _selectedCategory = null;
                                    _searchController.clear();
                                    _filterCourses();
                                  });
                                },
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text('Reset Filters'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _filteredCourses.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _filteredCourses.length,
                                itemBuilder: (context, index) {
                                  return _buildCourseCard(_filteredCourses[index]);
                                },
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MyLearningScreen()),
          );
        },
        label: const Text('My Learning'),
        icon: const Icon(Icons.school),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No courses found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try different search terms or filters',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _showOnlyFree = false;
                _selectedLevel = null;
                _selectedProvider = null;
                _selectedCategory = null;
              });
              _filterCourses();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Clear All Filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(Course course) {
    final isEnrolled = _courseService.isEnrolledInCourse(course.id);
    final progress = _courseService.getCourseProgress(course.id);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course image with overlay for status
          Stack(
            children: [
              if (course.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: SizedBox(
                    height: 150,
                    width: double.infinity,
                    child: Image.network(
                      course.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 150,
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.image_not_supported, size: 60, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                ),
              // Status badges
              Positioned(
                top: 8,
                right: 8,
                child: Row(
                  children: [
                    if (course.isFree)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'FREE',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    if (isEnrolled) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'ENROLLED',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          // Progress bar if enrolled
          if (isEnrolled)
            LinearProgressIndicator(
              value: progress / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                progress == 100 ? Colors.green : Theme.of(context).colorScheme.primary,
              ),
              minHeight: 6,
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Course title
                Text(
                  course.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                
                // Provider and duration
                Row(
                  children: [
                    Icon(Icons.school, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      course.provider,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      course.duration,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                
                // Level indicator
                Row(
                  children: [
                    Icon(Icons.bar_chart, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      _getLevelDisplayName(course.level),
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    if (isEnrolled) ...[
                      const Spacer(),
                      Text(
                        '$progress% Complete',
                        style: TextStyle(
                          color: progress == 100 ? Colors.green : Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                
                // Description
                Text(
                  course.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                
                // Skills
                if (course.skills.isNotEmpty) ...[
                  const Text(
                    'Skills you\'ll learn:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: course.skills.take(3).map((skill) {
                      return Chip(
                        label: Text(skill),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        labelStyle: const TextStyle(fontSize: 12),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
                ],
                
                const SizedBox(height: 8),
                
                // Rating
                Row(
                  children: [
                    ...List.generate(5, (index) {
                      return Icon(
                        index < course.rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 20,
                      );
                    }),
                    const SizedBox(width: 8),
                    Text('${course.rating}'),
                    if (course.enrollmentCount > 0) ...[
                      const Spacer(),
                      Icon(Icons.people, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${_formatEnrollmentCount(course.enrollmentCount)} enrolled',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.info_outline),
                        label: const Text('DETAILS'),
                        onPressed: () => _showCourseDetails(course),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: isEnrolled ? const Icon(Icons.play_arrow) : const Icon(Icons.school),
                        label: Text(isEnrolled ? 'CONTINUE' : 'ENROLL'),
                        onPressed: () => _enrollInCourse(course),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: isEnrolled ? Colors.green : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to get level display name
  String _getLevelDisplayName(CourseLevel level) {
    switch (level) {
      case CourseLevel.beginner:
        return 'Beginner';
      case CourseLevel.intermediate:
        return 'Intermediate';
      case CourseLevel.advanced:
        return 'Advanced';
      default:
        return level.toString();
    }
  }

  // Show level picker dialog
  void _showLevelPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('All Levels'),
                leading: _selectedLevel == null ? const Icon(Icons.check) : null,
                onTap: () {
                  setState(() {
                    _selectedLevel = null;
                    _filterCourses();
                  });
                  Navigator.pop(context);
                },
              ),
              ...CourseLevel.values.map((level) => ListTile(
                title: Text(_getLevelDisplayName(level)),
                leading: _selectedLevel == level ? const Icon(Icons.check) : null,
                onTap: () {
                  setState(() {
                    _selectedLevel = level;
                    _filterCourses();
                  });
                  Navigator.pop(context);
                },
              )),
            ],
          ),
        );
      },
    );
  }

  // Show provider picker dialog
  void _showProviderPicker() {
    if (_providers.isEmpty) return;
    
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('All Providers'),
                leading: _selectedProvider == null ? const Icon(Icons.check) : null,
                onTap: () {
                  setState(() {
                    _selectedProvider = null;
                    _filterCourses();
                  });
                  Navigator.pop(context);
                },
              ),
              ..._providers.map((provider) => ListTile(
                title: Text(provider),
                leading: _selectedProvider == provider ? const Icon(Icons.check) : null,
                onTap: () {
                  setState(() {
                    _selectedProvider = provider;
                    _filterCourses();
                  });
                  Navigator.pop(context);
                },
              )),
            ],
          ),
        );
      },
    );
  }

  // Show category picker dialog
  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('All Categories'),
                leading: _selectedCategory == null ? const Icon(Icons.check) : null,
                onTap: () {
                  setState(() {
                    _selectedCategory = null;
                    _filterCourses();
                  });
                  Navigator.pop(context);
                },
              ),
              ..._categories.map((category) => ListTile(
                title: Text(category),
                leading: _selectedCategory == category ? const Icon(Icons.check) : null,
                onTap: () {
                  setState(() {
                    _selectedCategory = category;
                    _filterCourses();
                  });
                  Navigator.pop(context);
                },
              )),
            ],
          ),
        );
      },
    );
  }

  // Show course details dialog
  void _showCourseDetails(Course course) {
    try {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            course.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (course.imageUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        course.imageUrl,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 150,
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(Icons.image_not_supported, size: 60, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  const Text(
                    'Course Details:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow('Provider', course.provider),
                  _buildDetailRow('Duration', course.duration),
                  _buildDetailRow('Level', _getLevelDisplayName(course.level)),
                  _buildDetailRow('Free Course', course.isFree ? 'Yes' : 'No'),
                  const SizedBox(height: 16),
                  const Text(
                    'Description:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(course.description),
                  if (course.skills.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Skills You\'ll Learn:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...course.skills.take(5).map((skill) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, size: 16, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(child: Text(skill)),
                        ],
                      ),
                    )),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CLOSE'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _enrollInCourse(course);
              },
              child: Text(_courseService.isEnrolledInCourse(course.id) ? 'CONTINUE' : 'ENROLL NOW'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error showing course details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not display course details')),
      );
    }
  }

  // Helper to build detail rows
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  // Enroll in course action
  void _enrollInCourse(Course course) {
    final isEnrolled = _courseService.isEnrolledInCourse(course.id);
    
    if (isEnrolled) {
      // Continue the course
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Continuing "${course.title}"'),
          action: SnackBarAction(
            label: 'VIEW PROGRESS',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyLearningScreen()),
              );
            },
          ),
        ),
      );
    } else {
      // Enroll in the course
      _courseService.enrollInCourse(course.id).then((success) {
        if (success) {
          setState(() {}); // Refresh UI to show enrolled status
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully enrolled in "${course.title}"'),
              action: SnackBarAction(
                label: 'VIEW COURSE',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MyLearningScreen()),
                  );
                },
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      });
    }
  }

  // Helper method to get popular skills when no skill gaps are available
  List<String> _getPopularSkills() {
    return [
      'Communication',
      'Project Management',
      'Microsoft Excel',
      'Public Speaking',
      'Digital Marketing',
      'Leadership',
      'Graphic Design',
      'Writing',
      'Photography',
      'Business Analytics',
      'Social Media',
      'Python',
      'Web Design',
      'Data Analysis',
    ];
  }

  // Format large enrollment numbers
  String _formatEnrollmentCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
} 
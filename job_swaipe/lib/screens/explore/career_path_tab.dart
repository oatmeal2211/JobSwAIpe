import 'package:flutter/material.dart';
import 'package:job_swaipe/models/course.dart';
import 'package:job_swaipe/services/course_service.dart';

class CareerPathTab extends StatefulWidget {
  final List<SkillGap> skillGaps;

  const CareerPathTab({super.key, required this.skillGaps});

  @override
  State<CareerPathTab> createState() => _CareerPathTabState();
}

class _CareerPathTabState extends State<CareerPathTab> {
  final CourseService _courseService = CourseService();
  List<LearningPath> _learningPaths = [];
  List<LearningPath> _enrolledPaths = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  // For custom path recommendation
  final TextEditingController _careerGoalController = TextEditingController();
  bool _isRecommending = false;
  LearningPath? _recommendedPath;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadEnrolledPaths();
  }

  @override
  void dispose() {
    _careerGoalController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadEnrolledPaths() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final enrolledPaths = await _courseService.getEnrolledLearningPaths();
      
      setState(() {
        _enrolledPaths = enrolledPaths;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load learning paths: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _getRecommendedPath() async {
    final careerGoal = _careerGoalController.text.trim();
    if (careerGoal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a career goal')),
      );
      return;
    }

    setState(() {
      _isRecommending = true;
      _recommendedPath = null;
    });

    try {
      // Show a loading message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generating personalized learning path...'),
          duration: Duration(seconds: 2),
        ),
      );

      // Extract current skills from skill gaps (as a simple example)
      final currentSkills = widget.skillGaps.isNotEmpty
          ? widget.skillGaps.map((gap) => gap.skillName).toList()
          : <String>[];

      final recommendedPath = await _courseService.getRecommendedLearningPath(
        careerGoal,
        currentSkills,
      );

      setState(() {
        _recommendedPath = recommendedPath;
        _isRecommending = false;
      });

      // Scroll to the recommended path section
      if (recommendedPath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Learning path for "$careerGoal" created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Scroll to recommended section after a short delay
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }
        });
      }
    } catch (e) {
      setState(() {
        _isRecommending = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Delete a learning path
  Future<void> _deletePath(LearningPath path) async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Learning Path'),
          content: Text('Are you sure you want to delete "${path.title}"? This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('DELETE', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      
      if (confirmed == true) {
        await _courseService.unenrollFromLearningPath(path.id);
        
        // Refresh the list
        await _loadEnrolledPaths();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed "${path.title}"'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Error deleting path: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing path: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Enroll in a learning path and refresh UI
  Future<void> _enrollInPath(LearningPath path) async {
    try {
      final success = await _courseService.enrollInLearningPath(path);
      
      if (success) {
        // Refresh the list to show updated enrollment status
        await _loadEnrolledPaths();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You\'ve enrolled in "${path.title}"'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error enrolling in path: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error enrolling in path: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          controller: _scrollController,
          children: [
            // Introduction text
            const Text(
              'Create personalized learning paths based on your career goals.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            
            // Career Goal Input Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lightbulb, color: Colors.amber),
                        const SizedBox(width: 8),
                        const Text(
                          'Get a Personalized Learning Path',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enter your desired job title or career goal, and we\'ll recommend a learning path for you.',
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _careerGoalController,
                      decoration: InputDecoration(
                        labelText: 'Career Goal',
                        hintText: 'e.g., Marketing Manager, Data Analyst',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.work),
                      ),
                      onSubmitted: (_) => _getRecommendedPath(),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isRecommending ? null : _getRecommendedPath,
                        icon: _isRecommending
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.search),
                        label: Text(_isRecommending ? 'GENERATING...' : 'GET RECOMMENDATIONS'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    // Examples of popular career goals
                    const SizedBox(height: 12),
                    const Text(
                      'Popular career goals:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        'Data Analyst',
                        'Marketing Manager',
                        'UX Designer',
                        'Project Manager',
                        'Content Writer',
                      ].map((goal) => ActionChip(
                        label: Text(goal),
                        onPressed: () {
                          _careerGoalController.text = goal;
                          _getRecommendedPath();
                        },
                      )).toList(),
                    ),
                  ],
                ),
              ),
            ),
            
            // Recommended Path (if available)
            if (_recommendedPath != null) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  const Icon(Icons.recommend, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    'Recommended Learning Path',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildLearningPathCard(_recommendedPath!, isRecommended: true),
            ],
            
            // Your Learning Paths
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(Icons.school, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Your Learning Paths',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              )
            else if (_enrolledPaths.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(Icons.school, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No learning paths yet',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Create a personalized path above to get started',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...(_enrolledPaths.map((path) => _buildLearningPathCard(path, canDelete: true))),
          ],
        ),
      ),
    );
  }

  Widget _buildLearningPathCard(LearningPath path, {bool isRecommended = false, bool canDelete = false}) {
    final isEnrolled = _courseService.isEnrolledInPath(path.id);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isRecommended ? 3 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isRecommended 
            ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isRecommended 
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
                  : Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        path.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isRecommended)
                      const Chip(
                        label: Text('RECOMMENDED'),
                        backgroundColor: Colors.green,
                        labelStyle: TextStyle(color: Colors.white, fontSize: 10),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[700]),
                    const SizedBox(width: 4),
                    Text(
                      'Estimated Time: ${path.estimatedTimeToComplete}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  path.description,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                
                // Target Roles
                if (path.targetRoles.isNotEmpty) ...[
                  const Text(
                    'Target Roles:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 32,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: path.targetRoles.map((role) {
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            role,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                              fontSize: 12,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Progress Bar (if applicable)
                if (isEnrolled && path.completionPercentage > 0) ...[
                  Row(
                    children: [
                      const Text(
                        'Progress:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(width: 8),
                      Text('${path.completionPercentage}%'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: path.completionPercentage / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Course Count
                Row(
                  children: [
                    Icon(Icons.book, size: 16, color: Colors.grey[700]),
                    const SizedBox(width: 4),
                    Text(
                      '${path.courses.length} courses in this path',
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                    ),
                    if (isEnrolled) ...[
                      const Spacer(),
                      Text(
                        '${path.userEnrolledCourses.length} enrolled',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.visibility),
                        label: const Text('DETAILS'),
                        onPressed: () => _showPathDetails(path),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: canDelete && isEnrolled
                          ? OutlinedButton.icon(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              label: const Text('DELETE', style: TextStyle(color: Colors.red)),
                              onPressed: () => _deletePath(path),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                              ),
                            )
                          : ElevatedButton.icon(
                              icon: isEnrolled ? const Icon(Icons.play_arrow) : const Icon(Icons.add),
                              label: Text(isEnrolled ? 'CONTINUE' : 'START PATH'),
                              onPressed: () => _enrollInPath(path),
                              style: ElevatedButton.styleFrom(
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

  void _showPathDetails(LearningPath path) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                AppBar(
                  title: Text(path.title),
                  automaticallyImplyLeading: false,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Path description
                      Text(
                        path.description,
                        style: const TextStyle(fontSize: 16),
                      ),
                      
                      // Path overview
                      const SizedBox(height: 24),
                      const Text(
                        'Path Overview',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildPathInfoRow(
                                'Time to Complete',
                                path.estimatedTimeToComplete,
                                Icons.access_time,
                              ),
                              const Divider(),
                              _buildPathInfoRow(
                                'Number of Courses',
                                '${path.courses.length} courses',
                                Icons.book,
                              ),
                              const Divider(),
                              _buildPathInfoRow(
                                'Level',
                                _getPathLevel(path),
                                Icons.bar_chart,
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Course sequence
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Course Sequence',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          if (!_courseService.isEnrolledInPath(path.id))
                            TextButton.icon(
                              onPressed: () async {
                                // Enroll in the entire path
                                await _enrollInPath(path);
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('ENROLL IN PATH'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Complete these courses in order for the best learning experience',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      
                      // Timeline view of courses
                      ...path.courses.asMap().entries.map((entry) {
                        final index = entry.key;
                        final course = entry.value;
                        final isLastCourse = index == path.courses.length - 1;
                        
                        return IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Timeline
                              Column(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  if (!isLastCourse)
                                    Expanded(
                                      child: Container(
                                        width: 2,
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              // Course card
                              Expanded(
                                child: Column(
                                  children: [
                                    _buildDetailedCourseCard(course, onEnrollmentChanged: () {
                                      // Refresh the path data when course enrollment changes
                                      setState(() {
                                        _loadEnrolledPaths();
                                      });
                                    }),
                                    if (!isLastCourse) const SizedBox(height: 16),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () async {
                          // Start or continue the learning path
                          await _enrollInPath(path);
                          Navigator.pop(context);
                        },
                        icon: _courseService.isEnrolledInPath(path.id) 
                            ? const Icon(Icons.play_arrow) 
                            : const Icon(Icons.school),
                        label: Text(_courseService.isEnrolledInPath(path.id) 
                            ? 'CONTINUE PATH' 
                            : 'START THIS PATH'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDetailedCourseCard(Course course, {Function()? onEnrollmentChanged}) {
    final isEnrolled = _courseService.isEnrolledInCourse(course.id);
    final progress = _courseService.getCourseProgress(course.id);
    
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (course.imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      course.imageUrl,
                      width: 80,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 80,
                        height: 60,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported, size: 30, color: Colors.grey),
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        course.provider,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Course details in a horizontal layout
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildCourseDetailChip(Icons.access_time, course.duration),
                _buildCourseDetailChip(Icons.bar_chart, _getLevelName(course.level)),
                if (course.isFree)
                  _buildCourseDetailChip(Icons.attach_money, 'Free', color: Colors.green),
                _buildCourseDetailChip(Icons.star, '${course.rating}', color: Colors.amber),
              ],
            ),
            
            // Course description
            const SizedBox(height: 12),
            Text(
              course.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            ),
            
            // Skills
            if (course.skills.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Skills:',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 8,
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
            
            // Progress bar if enrolled
            if (isEnrolled) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your Progress: $progress%',
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                  ),
                  if (progress == 100)
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: progress / 100,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress == 100 ? Colors.green : Theme.of(context).colorScheme.primary,
                ),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ],
            
            // Action button
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  // Enroll in this specific course
                  final success = await _courseService.enrollInCourse(course.id);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Enrolled in "${course.title}"'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    // Call the callback to update UI
                    if (onEnrollmentChanged != null) {
                      onEnrollmentChanged();
                    }
                  }
                },
                icon: Icon(isEnrolled ? Icons.play_circle_outline : Icons.add),
                label: Text(isEnrolled ? 'CONTINUE' : 'ENROLL'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isEnrolled ? Colors.green : null,
                  foregroundColor: isEnrolled ? Colors.white : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseDetailChip(IconData icon, String label, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color ?? Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color ?? Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildPathInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _getPathLevel(LearningPath path) {
    // Simple logic to determine path level based on courses
    if (path.courses.isEmpty) return 'Beginner';
    
    final levels = path.courses.map((c) => c.level).toList();
    if (levels.contains(CourseLevel.advanced)) {
      return 'Advanced';
    } else if (levels.contains(CourseLevel.intermediate)) {
      return 'Intermediate';
    } else {
      return 'Beginner';
    }
  }

  String _getLevelName(CourseLevel level) {
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
} 
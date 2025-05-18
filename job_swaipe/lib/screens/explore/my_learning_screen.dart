import 'package:flutter/material.dart';
import 'package:job_swaipe/models/course.dart';
import 'package:job_swaipe/services/course_service.dart';

class MyLearningScreen extends StatefulWidget {
  const MyLearningScreen({super.key});

  @override
  State<MyLearningScreen> createState() => _MyLearningScreenState();
}

class _MyLearningScreenState extends State<MyLearningScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final CourseService _courseService = CourseService();
  
  List<Course> _enrolledCourses = [];
  List<LearningPath> _enrolledPaths = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadEnrollments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEnrollments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final courses = await _courseService.getEnrolledCourses();
      final paths = await _courseService.getEnrolledLearningPaths();
      
      setState(() {
        _enrolledCourses = courses;
        _enrolledPaths = paths;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading your learning data: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _updateCourseProgress(Course course, int progress) async {
    try {
      await _courseService.updateCourseProgress(course.id, progress);
      await _loadEnrollments(); // Refresh data to show updated progress
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Progress for "${course.title}" updated to $progress%'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating progress: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Learning'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'MY COURSES'),
            Tab(text: 'MY PATHS'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEnrollments,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadEnrollments,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCoursesTab(),
                  _buildPathsTab(),
                ],
              ),
            ),
    );
  }

  Widget _buildCoursesTab() {
    if (_enrolledCourses.isEmpty) {
      return _buildEmptyState(
        'You haven\'t enrolled in any courses yet',
        'Explore our Course Hub to find courses that match your interests and career goals.',
        Icons.school,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _enrolledCourses.length,
      itemBuilder: (context, index) {
        final course = _enrolledCourses[index];
        return _buildEnrolledCourseCard(course);
      },
    );
  }

  Widget _buildPathsTab() {
    if (_enrolledPaths.isEmpty) {
      return _buildEmptyState(
        'You haven\'t started any learning paths yet',
        'Learning paths help you master skills in a structured way. Check out our Career Path section to find one that matches your goals.',
        Icons.route,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _enrolledPaths.length,
      itemBuilder: (context, index) {
        final path = _enrolledPaths[index];
        return _buildEnrolledPathCard(path);
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              subtitle,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.explore),
              label: const Text('EXPLORE COURSES'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnrolledCourseCard(Course course) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported, color: Colors.grey),
                      ),
                    ),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        course.provider,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            course.duration,
                            style: TextStyle(color: Colors.grey[600], fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Progress section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Progress: ${course.courseProgress}%',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    if (course.courseProgress == 100)
                      const Chip(
                        label: Text('COMPLETED'),
                        backgroundColor: Colors.green,
                        labelStyle: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: course.courseProgress / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    course.courseProgress == 100 ? Colors.green : Theme.of(context).colorScheme.primary,
                  ),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                
                // Quick progress buttons
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text('Set progress:', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 8),
                      for (final progress in [25, 50, 75, 100])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            label: Text('$progress%'),
                            backgroundColor: course.courseProgress >= progress 
                                ? Colors.green.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: course.courseProgress >= progress ? Colors.green : Colors.grey[700],
                              fontWeight: FontWeight.bold,
                            ),
                            onPressed: () => _updateCourseProgress(course, progress),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Continue learning - would launch the course
                      // For now, increase progress by 25% as a simulation
                      final newProgress = (course.courseProgress + 25).clamp(0, 100);
                      _updateCourseProgress(course, newProgress);
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Continuing course... Progress increased by 25%')),
                      );
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('CONTINUE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    _showUpdateProgressDialog(course);
                  },
                  icon: const Icon(Icons.edit),
                  tooltip: 'Update progress',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnrolledPathCard(LearningPath path) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  path.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Estimated time: ${path.estimatedTimeToComplete}',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overall progress
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Overall Progress: ${path.completionPercentage}%',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${path.userEnrolledCourses.length}/${path.courses.length} courses',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: path.completionPercentage / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    path.completionPercentage == 100 ? Colors.green : Theme.of(context).colorScheme.primary,
                  ),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Your Courses:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        await _courseService.unenrollFromLearningPath(path.id);
                        _loadEnrollments();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Removed "${path.title}"'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                      label: const Text('REMOVE PATH', style: TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Course list with progress
                ...path.courses.asMap().entries.map((entry) {
                  final index = entry.key;
                  final course = entry.value;
                  final isEnrolled = path.userEnrolledCourses.contains(course.id);
                  final canEnroll = index == 0 || 
                      (path.userEnrolledCourses.contains(path.courses[index - 1].id) && 
                      path.courses[index - 1].courseProgress >= 100);
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: isEnrolled ? Colors.white : Colors.grey[100],
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: isEnrolled 
                                    ? (course.courseProgress == 100 ? Colors.green : Theme.of(context).colorScheme.primary) 
                                    : (canEnroll ? Colors.amber : Colors.grey[400]),
                                child: isEnrolled 
                                    ? (course.courseProgress == 100 
                                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                                        : Text('${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 12)))
                                    : Text('${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      course.title,
                                      style: TextStyle(
                                        fontWeight: isEnrolled ? FontWeight.bold : FontWeight.normal,
                                        color: isEnrolled ? null : (canEnroll ? Colors.black87 : Colors.grey[600]),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      course.provider,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isEnrolled)
                                Chip(
                                  label: Text('${course.courseProgress}%'),
                                  backgroundColor: course.courseProgress == 100 
                                      ? Colors.green.withOpacity(0.2) 
                                      : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  labelStyle: TextStyle(
                                    color: course.courseProgress == 100 ? Colors.green : Theme.of(context).colorScheme.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                          
                          if (isEnrolled) ...[
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: course.courseProgress / 100,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                course.courseProgress == 100 ? Colors.green : Theme.of(context).colorScheme.primary,
                              ),
                              minHeight: 4,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () {
                                    _showUpdateProgressDialog(course);
                                  },
                                  icon: const Icon(Icons.edit, size: 16),
                                  label: const Text('UPDATE PROGRESS', style: TextStyle(fontSize: 12)),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    // Simulate continuing course by adding 25% progress
                                    final newProgress = (course.courseProgress + 25).clamp(0, 100);
                                    _updateCourseProgress(course, newProgress);
                                  },
                                  icon: const Icon(Icons.play_arrow, size: 16),
                                  label: const Text('CONTINUE', style: TextStyle(fontSize: 12)),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                ),
                              ],
                            ),
                          ] else if (canEnroll) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () async {
                                  await _courseService.enrollInCourse(course.id);
                                  _loadEnrollments();
                                  
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Enrolled in "${course.title}"'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                },
                                child: const Text('START COURSE'),
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.lock, size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(
                                  'Complete previous courses first',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
                
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      // Find the next course to continue or the first course if none started
                      final nextCourseIndex = path.courses.indexWhere((course) {
                        final isEnrolled = path.userEnrolledCourses.contains(course.id);
                        return isEnrolled && course.courseProgress < 100;
                      });
                      
                      if (nextCourseIndex >= 0) {
                        // Continue an existing course
                        final nextCourse = path.courses[nextCourseIndex];
                        final newProgress = (nextCourse.courseProgress + 25).clamp(0, 100);
                        await _updateCourseProgress(nextCourse, newProgress);
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Continuing "${nextCourse.title}"... Progress increased by 25%'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        // Try to enroll in the next course in the path
                        final enrolled = await _courseService.enrollInNextPathCourse(path.id);
                        await _loadEnrollments();
                        
                        if (enrolled) {
                          // Find which course was enrolled
                          final paths = await _courseService.getEnrolledLearningPaths();
                          final updatedPathIndex = paths.indexWhere((p) => p.id == path.id);
                          
                          if (updatedPathIndex >= 0) {
                            final updatedPath = paths[updatedPathIndex];
                            final newCourses = updatedPath.userEnrolledCourses
                                .where((id) => !path.userEnrolledCourses.contains(id))
                                .toList();
                            
                            if (newCourses.isNotEmpty) {
                              int newCourseIndex = -1;
                              for (int i = 0; i < updatedPath.courses.length; i++) {
                                if (newCourses.contains(updatedPath.courses[i].id)) {
                                  newCourseIndex = i;
                                  break;
                                }
                              }
                              
                              if (newCourseIndex >= 0) {
                                final newCourse = updatedPath.courses[newCourseIndex];
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Started new course: "${newCourse.title}"'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                return;
                              }
                            }
                          }
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Started next course in path'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          // All courses completed or no more courses available
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('All courses in this path are completed or already enrolled!'),
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('CONTINUE PATH'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showUpdateProgressDialog(Course course) {
    int progress = course.courseProgress;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Progress'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Update your progress for "${course.title}"'),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    Text('$progress%', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Slider(
                      value: progress.toDouble(),
                      min: 0,
                      max: 100,
                      divisions: 20,
                      label: '$progress%',
                      onChanged: (value) {
                        setState(() {
                          progress = value.round();
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => setState(() => progress = 0),
                          child: const Text('0%'),
                        ),
                        TextButton(
                          onPressed: () => setState(() => progress = 25),
                          child: const Text('25%'),
                        ),
                        TextButton(
                          onPressed: () => setState(() => progress = 50),
                          child: const Text('50%'),
                        ),
                        TextButton(
                          onPressed: () => setState(() => progress = 75),
                          child: const Text('75%'),
                        ),
                        TextButton(
                          onPressed: () => setState(() => progress = 100),
                          child: const Text('100%'),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateCourseProgress(course, progress);
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }
} 
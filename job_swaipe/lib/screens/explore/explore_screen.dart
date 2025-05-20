import 'package:flutter/material.dart';
import 'package:job_swaipe/models/course.dart';
import 'package:job_swaipe/services/course_service.dart';
import 'package:job_swaipe/screens/explore/course_hub_tab.dart';
import 'package:job_swaipe/screens/explore/career_path_tab.dart';
import 'package:job_swaipe/screens/explore/skill_gap_view.dart';
import 'package:job_swaipe/screens/explore/my_learning_screen.dart';

class ExploreScreen extends StatefulWidget {
  final String? resumeJson;
  final String? jobJson;

  const ExploreScreen({super.key, this.resumeJson, this.jobJson});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final CourseService _courseService = CourseService();
  List<SkillGap> _skillGaps = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedIndex = _tabController.index;
        });
      }
    });
    
    if (widget.resumeJson != null && widget.jobJson != null) {
      _loadSkillGaps();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSkillGaps() async {
    if (widget.resumeJson == null || widget.jobJson == null) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final skillGaps = await _courseService.getSkillGaps(
        widget.resumeJson!,
        widget.jobJson!,
      );
      
      setState(() {
        _skillGaps = skillGaps;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load skill gaps: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _navigateToMyLearning() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MyLearningScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore Learning'),
        actions: [
          // My Learning button
          IconButton(
            icon: const Icon(Icons.school),
            tooltip: 'My Learning',
            onPressed: _navigateToMyLearning,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.search),
              text: 'COURSES',
            ),
            Tab(
              icon: Icon(Icons.route),
              text: 'PATHS',
            ),
            
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Help text based on selected tab
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.blue.withOpacity(0.1),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getHelpText(),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            
            // Skill Gap Section (if available)
            if (_skillGaps.isNotEmpty && _selectedIndex < 2)
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
                child: SkillGapView(skillGaps: _skillGaps),
              ),
            
            // Loading or Error State
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            
            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  CourseHubTab(skillGaps: _skillGaps),
                  CareerPathTab(skillGaps: _skillGaps),
                  
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _selectedIndex == 0 ? FloatingActionButton(
        onPressed: () {
          _showFilterBottomSheet();
        },
        child: const Icon(Icons.filter_list),
        tooltip: 'Filter Courses',
      ) : null,
    );
  }

  String _getHelpText() {
    switch (_selectedIndex) {
      case 0:
        return 'Find individual courses to learn specific skills. Tap on a course to see details.';
      case 1:
        return 'Learning paths help you master skills in a structured way. Enter your career goal to get personalized recommendations.';
      case 2:
        return 'Save courses and learning paths to access them quickly later.';
      default:
        return '';
    }
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.filter_list),
                      const SizedBox(width: 8),
                      const Text(
                        'Filter Courses',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Filter sections would go here
                      _buildFilterSection('Course Type', [
                        'All Courses',
                        'Free Courses',
                        'Paid Courses',
                      ]),
                      const Divider(),
                      _buildFilterSection('Level', [
                        'All Levels',
                        'Beginner',
                        'Intermediate',
                        'Advanced',
                      ]),
                      const Divider(),
                      _buildFilterSection('Duration', [
                        'Any Duration',
                        'Under 2 hours',
                        '2-5 hours',
                        '5-10 hours',
                        'Over 10 hours',
                      ]),
                      const Divider(),
                      _buildFilterSection('Category', [
                        'All Categories',
                        'Technology',
                        'Business',
                        'Design',
                        'Marketing',
                        'Personal Development',
                      ]),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                // Reset filters
                                Navigator.pop(context);
                              },
                              child: const Text('RESET'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                // Apply filters
                                Navigator.pop(context);
                              },
                              child: const Text('APPLY'),
                            ),
                          ),
                        ],
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

  Widget _buildFilterSection(String title, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            return FilterChip(
              label: Text(option),
              selected: option == options[0], // First option is selected by default
              onSelected: (selected) {
                // Would handle filter selection
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
} 
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:job_swaipe/services/auth_service.dart';
import 'package:job_swaipe/screens/review_resume_page.dart';
import 'package:job_swaipe/screens/community/community_screen.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class JobListing {
  final String id;
  final String title;
  final String company;
  final String location;
  final String description;
  final String salary;
  final String? postedDate;
  final String? benefits;
  final String? link;
  final String? searchKeyword;
  final String? jobType;

  JobListing({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.description,
    required this.salary,
    this.postedDate,
    this.benefits,
    this.link,
    this.searchKeyword,
    this.jobType,
  });

  factory JobListing.fromMap(String id, Map<String, dynamic> map) {
    return JobListing(
      id: id,
      title: map['title'] ?? '',
      company: map['company'] ?? '',
      location: map['location'] ?? '',
      description: map['description'] ?? '',
      salary: map['salary'] ?? '',
      postedDate: map['posted_date'],
      benefits: map['benefits'],
      link: map['link'],
      searchKeyword: map['search_keyword'],
      jobType: map['job_type'],
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  List<JobListing> _jobListings = [];
  List<JobListing> _swipedRightJobs = [];
  final CardSwiperController _swiperController = CardSwiperController();
  bool _isLoading = true;
  int _selectedIndex = 0;
  bool _showTutorialOverlay = false;

  List<Widget> _buildPages() {
    return <Widget>[
      _buildJobSwipeView(),
      const ReviewResumePage(),
      ComingSoonPage(pageName: 'Explore'),
      CommunityScreen(),
    ];
  }

  @override
  void initState() {
    super.initState();
    _loadJobListings();
    _checkShowTutorial();
  }

  Future<void> _checkShowTutorial() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool hasSeenTutorial = prefs.getBool('hasSeenSwipeTutorial') ?? false;
    if (!hasSeenTutorial) {
      if (mounted) {
        setState(() {
          _showTutorialOverlay = true;
        });
      }
    }
  }

  Future<void> _markTutorialAsSeen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenSwipeTutorial', true);
    if (mounted) {
      setState(() {
        _showTutorialOverlay = false;
      });
    }
  }

  Future<void> _loadJobListings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final String jsonString = await rootBundle.loadString('assets/data/jobstreet_all_jobs.json');
      final List<dynamic> jsonList = json.decode(jsonString);

      final List<JobListing> jobs = jsonList.asMap().entries.map((entry) {
        int idx = entry.key;
        Map<String, dynamic> jobMap = entry.value as Map<String, dynamic>;
        return JobListing.fromMap(idx.toString(), jobMap);
      }).toList();
      
      setState(() {
        _jobListings = jobs;
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading local jobs: $e");
      setState(() {
        _isLoading = false;
        _jobListings = [];
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading jobs: ${e.toString()}')),
        );
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildJobSwipeView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_jobListings.isEmpty && !_showTutorialOverlay) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No more jobs to swipe for now!'),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Jobs'),
              onPressed: _loadJobListings,
            )
          ],
        ),
      );
    }

    Widget tutorialOverlay = Container();
    if (_showTutorialOverlay && _jobListings.isNotEmpty) {
      tutorialOverlay = Positioned.fill(
        child: GestureDetector(
          onTap: _markTutorialAsSeen,
          child: Container(
            color: Colors.black.withOpacity(0.7),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Swipe Right to Save a Job!',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const Icon(Icons.arrow_forward, color: Colors.green, size: 80),
                const SizedBox(height: 40),
                const Text(
                  'Swipe Left to Skip.',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const Icon(Icons.arrow_back, color: Colors.red, size: 80),
                const SizedBox(height: 60),
                ElevatedButton(
                  onPressed: _markTutorialAsSeen,
                  child: const Text('Got it!'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: CardSwiper(
                  controller: _swiperController,
                  cardsCount: _jobListings.length,
                  onSwipe: _onSwipe,
                  onUndo: _onUndo,
                  numberOfCardsDisplayed: _jobListings.length < 3 ? _jobListings.length : 3,
                  backCardOffset: const Offset(20, 20),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 50.0),
                  cardBuilder: (
                    context,
                    index,
                    horizontalThresholdPercentage,
                    verticalThresholdPercentage,
                  ) {
                    return SizedBox(
                      child: JobCard(job: _jobListings[index]),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FloatingActionButton(
                    heroTag: 'undo_swipe',
                    mini: true,
                    onPressed: () {
                       _swiperController.undo();
                       if (_showTutorialOverlay) _markTutorialAsSeen();
                    } ,
                    backgroundColor: Colors.amber,
                    child: const Icon(Icons.undo, color: Colors.white),
                    tooltip: 'Undo Last Swipe',
                  ),
                  FloatingActionButton(
                    heroTag: 'swipe_left_button',
                    onPressed: () {
                      _swiperController.swipe(CardSwiperDirection.left);
                      if (_showTutorialOverlay) _markTutorialAsSeen();
                    },
                    backgroundColor: Colors.redAccent,
                    child: const Icon(Icons.close, color: Colors.white, size: 30),
                  ),
                  FloatingActionButton(
                    heroTag: 'swipe_right_button',
                    onPressed: () {
                      _swiperController.swipe(CardSwiperDirection.right);
                       if (_showTutorialOverlay) _markTutorialAsSeen();
                    },
                    backgroundColor: Colors.green,
                    child: const Icon(Icons.check, color: Colors.white, size: 30),
                  ),
                  FloatingActionButton(
                    heroTag: 'smart_filters',
                    mini: true,
                    onPressed: _showSmartFilters,
                    backgroundColor: Colors.blueAccent,
                    child: const Icon(Icons.filter_list, color: Colors.white),
                    tooltip: 'Smart Filters',
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text("✨ Daily AI Job Drop (Coming Soon!) ✨", style: TextStyle(fontStyle: FontStyle.italic)),
            )
          ],
        ),
        if (_showTutorialOverlay && _jobListings.isNotEmpty) tutorialOverlay,
      ],
    );
  }

  bool _onSwipe(int previousIndex, int? currentIndex, CardSwiperDirection direction) {
    if (previousIndex >= _jobListings.length) return false;
    
    final job = _jobListings[previousIndex];
    debugPrint('Swiped job: ${job.title} in direction ${direction.name}');

    if (_showTutorialOverlay) {
      _markTutorialAsSeen();
    }

    if (direction == CardSwiperDirection.right) {
      setState(() {
        _swipedRightJobs.add(job);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved: ${job.title}'),
          duration: const Duration(seconds: 2),
        ),
      );
    } else if (direction == CardSwiperDirection.left) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Skipped: ${job.title}'),
            duration: const Duration(seconds: 2),
          ),
        );
    }
    return true;
  }

  bool _onUndo(int? previousIndex, int currentIndex, CardSwiperDirection direction) {
    final job = _jobListings[currentIndex];
    debugPrint('Undo swipe for job: ${job.title}');
    if (direction == CardSwiperDirection.right) {
      setState(() {
        _swipedRightJobs.removeWhere((swipedJob) => swipedJob.id == job.id);
      });
    }
    return true;
  }

  void _showSmartFilters() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Smart Filters', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              const Text('Job Type (e.g., Full-time, Part-time) - Coming Soon'),
              const SizedBox(height: 8),
              const Text('Remote Only - Coming Soon'),
              const SizedBox(height: 8),
              const Text('Salary Range - Coming Soon'),
              const SizedBox(height: 8),
              const Text('Location - Coming Soon'),
              const SizedBox(height: 20),
              ElevatedButton(
                child: const Text('Apply Filters'),
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Filter functionality coming soon!')),
                  );
                },
              )
            ],
          ),
        );
      },
    );
  }
  
  void _viewSavedJobs() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SavedJobsScreen(savedJobs: _swipedRightJobs)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = _buildPages();
    return Scaffold(
      appBar: AppBar(
        title: const Text('JobSwAIpe'),
        actions: [
          if (_selectedIndex == 0)
            IconButton(
              icon: const Icon(Icons.favorite),
              tooltip: 'Saved Jobs',
              onPressed: _viewSavedJobs,
            ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: Center(
        child: pages.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'HOME',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'RESUME REVIEW',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'EXPLORE',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'COMMUNITY',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  Widget _buildJobsList() {
    return ListView.builder(
      itemCount: _jobListings.length,
      itemBuilder: (context, index) {
        final job = _jobListings[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(
              job.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${job.company} • ${job.location}'),
                Text('Salary: ${job.salary}'),
                const SizedBox(height: 4),
                Text(
                  job.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            isThreeLine: true,
            onTap: () => _showJobDetails(job),
            trailing: IconButton(
              icon: const Icon(Icons.favorite_border),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Job saved to favorites')),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileSection() {
    final user = _authService.getCurrentUser();
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage("https://example.com/user_avatar.png"),
            child: Icon(Icons.person, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            user?.email ?? 'User',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _signOut,
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showJobDetails(JobListing job) {
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
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      job.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${job.company} • ${job.location}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Salary: ${job.salary}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Job Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(job.description),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Application submitted!')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Apply Now'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: ${e.toString()}')),
        );
      }
    }
  }
}

class JobCard extends StatefulWidget {
  final JobListing job;
  const JobCard({super.key, required this.job});

  @override
  State<JobCard> createState() => _JobCardState();
}

class _JobCardState extends State<JobCard> {
  String? _matchPercentage;
  String? _matchReasoning;
  bool _isMatchingLoading = true;
  String? _matchError;

  @override
  void initState() {
    super.initState();
    _fetchJobMatchDetails();
  }

  Future<void> _fetchJobMatchDetails() async {
    if (!mounted) return;
    setState(() {
      _isMatchingLoading = true;
      _matchError = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final resumeJsonString = prefs.getString('saved_resume_json');

      if (resumeJsonString == null || resumeJsonString.isEmpty) {
        if (mounted) {
          setState(() {
            _matchPercentage = null;
            _matchReasoning = "Save your resume to see match insights!";
            _isMatchingLoading = false;
          });
        }
        return;
      }
      
      // Validate resumeJsonString is valid JSON before parsing
      try {
        jsonDecode(resumeJsonString); // Try to parse to check validity
      } catch (e) {
        if (mounted) {
          setState(() {
            _matchError = "Error: Saved resume data is corrupted. Please re-save.";
            _isMatchingLoading = false;
          });
        }
        return;
      }


      final apiKey = dotenv.env['DASHSCOPE_API_KEY'];
      if (apiKey == null) {
        throw Exception('DASHSCOPE_API_KEY not found in .env file');
      }

      final prompt = """
Given the following resume in JSON format:
<resume_json>
$resumeJsonString
</resume_json>

And the following job details:
<job_details>
Title: ${widget.job.title}
Company: ${widget.job.company}
Description: ${widget.job.description}
Location: ${widget.job.location}
Salary: ${widget.job.salary}
Benefits: ${widget.job.benefits ?? 'Not specified'}
Job Type: ${widget.job.jobType ?? 'Not specified'}
</job_details>

Please perform the following:
1. Calculate a match percentage (e.g., "85%").
2. Provide a concise explanation (2-3 bullet points, Markdown formatted) for this match percentage, highlighting key strengths and potential gaps relevant to the job.
3. Return ONLY the percentage on the first line, followed by the Markdown explanation. For example:
85%
**Reasoning:**
* Strong alignment in required skills.
* Relevant project experience.
""";

      final response = await http.post(
        Uri.parse('https://dashscope-intl.aliyuncs.com/compatible-mode/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'qwen-plus', // Using qwen-plus
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'stream': false,
        }),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(utf8.decode(response.bodyBytes));
        if (responseBody['choices'] != null && responseBody['choices'].isNotEmpty) {
          final content = responseBody['choices'][0]['message']['content'] as String;
          final lines = content.split('\\n');
          if (mounted) {
            setState(() {
              _matchPercentage = lines.isNotEmpty ? lines[0].trim() : "N/A";
              _matchReasoning = lines.length > 1 ? lines.sublist(1).join('\\n').trim() : "No detailed explanation provided.";
              _isMatchingLoading = false;
            });
          }
        } else {
          throw Exception('Failed to parse match details from API response');
        }
      } else {
        final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception('Failed to get match details: ${response.statusCode} ${errorBody['error']?['message'] ?? response.body}');
      }
    } catch (e) {
      print('Error fetching job match details: $e');
      if (mounted) {
        setState(() {
          _matchError = 'Error: Could not fetch match insights. $e';
          _matchReasoning = 'Could not load match insights at this time.';
          _isMatchingLoading = false;
        });
      }
    }
  }

  String _formatPostedDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(isoDate);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoDate; // return original if parsing fails
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // Slightly more rounded
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(vertical: 8.0), // Add some vertical margin
      child: Padding(
        padding: const EdgeInsets.all(16.0), // Increased padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Job Title
            Text(
              widget.job.title,
              style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // Company and Location
            if (widget.job.company.isNotEmpty || widget.job.location.isNotEmpty)
              Row(
                children: [
                  if (widget.job.company.isNotEmpty)
                    Icon(Icons.business, size: 16, color: textTheme.bodySmall?.color),
                  if (widget.job.company.isNotEmpty)
                    const SizedBox(width: 4),
                  if (widget.job.company.isNotEmpty)
                    Expanded(
                      child: Text(
                        widget.job.company,
                        style: textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (widget.job.company.isNotEmpty && widget.job.location.isNotEmpty)
                     Text(" • ", style: textTheme.titleSmall),
                  if (widget.job.location.isNotEmpty)
                    Icon(Icons.location_on, size: 16, color: textTheme.bodySmall?.color),
                  if (widget.job.location.isNotEmpty)
                    const SizedBox(width: 4),
                  if (widget.job.location.isNotEmpty)
                    Expanded(
                      child: Text(
                        widget.job.location,
                        style: textTheme.titleSmall?.copyWith(color: Colors.grey[700]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 8),

            // Salary and Job Type
            if (widget.job.salary.isNotEmpty || (widget.job.jobType != null && widget.job.jobType!.isNotEmpty))
              Row(
                children: [
                  if (widget.job.salary.isNotEmpty)
                    Icon(Icons.attach_money, size: 16, color: Colors.green[700]),
                  if (widget.job.salary.isNotEmpty)
                    const SizedBox(width: 4),
                  if (widget.job.salary.isNotEmpty)
                    Expanded(
                      child: Text(
                        widget.job.salary, // Removed "Salary: " prefix as icon implies it
                        style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                   if (widget.job.salary.isNotEmpty && (widget.job.jobType != null && widget.job.jobType!.isNotEmpty))
                     const SizedBox(width: 10),
                  if (widget.job.jobType != null && widget.job.jobType!.isNotEmpty)
                    Icon(Icons.work_outline, size: 16, color: textTheme.bodySmall?.color),
                  if (widget.job.jobType != null && widget.job.jobType!.isNotEmpty)
                    const SizedBox(width: 4),
                  if (widget.job.jobType != null && widget.job.jobType!.isNotEmpty)
                    Expanded(
                      child: Text(
                        widget.job.jobType!, // Removed "Type: " prefix
                        style: textTheme.bodyMedium,
                        textAlign: widget.job.salary.isNotEmpty ? TextAlign.end : TextAlign.start,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            if (widget.job.salary.isNotEmpty || (widget.job.jobType != null && widget.job.jobType!.isNotEmpty))
              const SizedBox(height: 8),

            // Posted Date
            if (widget.job.postedDate != null && widget.job.postedDate!.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: textTheme.bodySmall?.color),
                  const SizedBox(width: 4),
                  Text(
                    'Posted: ${_formatPostedDate(widget.job.postedDate)}',
                    style: textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],

            // Benefits (collapsible or summarized if too long)
            if (widget.job.benefits != null && widget.job.benefits!.isNotEmpty) ...[
              Text(
                'Benefits:',
                style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                widget.job.benefits!,
                style: textTheme.bodySmall,
                maxLines: 2, // Limit lines for brevity
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
            ],

            // Description (limited lines, expandable on tap maybe in future)
            if (widget.job.description.isNotEmpty)
              Expanded( // Use Expanded for description to take available space
                flex: 3, // Give more flex to description
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Description:',
                      style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: SingleChildScrollView( // Make description scrollable if it overflows
                        child: Text(
                          widget.job.description,
                          style: textTheme.bodySmall?.copyWith(fontSize: 13), // Slightly smaller for more text
                        ),
                      ),
                    )
                  ],
                )
              ),
            if (widget.job.description.isNotEmpty) const SizedBox(height: 16),

            // "Why You Matched" Section
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.7), // Use a theme color
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outline.withOpacity(0.5), width: 1)
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "✨ Why You Might Match ",
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (_matchPercentage != null && _matchPercentage != "N/A" && !_isMatchingLoading)
                        Text(
                          "($_matchPercentage)",
                           style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary, // Highlight percentage
                           )
                        ),
                      const Spacer(),
                       IconButton(
                        icon: Icon(Icons.refresh, size: 20),
                        onPressed: _isMatchingLoading ? null : _fetchJobMatchDetails,
                        tooltip: "Refresh Match Analysis",
                       )
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_isMatchingLoading)
                    const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(strokeWidth: 2)))
                  else if (_matchError != null)
                    Text(_matchError!, style: TextStyle(color: colorScheme.error))
                  else if (_matchReasoning != null)
                    MarkdownBody(
                        data: _matchReasoning!,
                        styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                          p: textTheme.bodyMedium?.copyWith(fontSize: 14, color: colorScheme.onSurfaceVariant),
                          listBullet: textTheme.bodyMedium?.copyWith(fontSize: 14, color: colorScheme.onSurfaceVariant),
                        ),
                      )
                  else
                    Text("No match information available.", style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SavedJobsScreen extends StatelessWidget {
  final List<JobListing> savedJobs;

  const SavedJobsScreen({super.key, required this.savedJobs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Jobs'),
      ),
      body: savedJobs.isEmpty
          ? const Center(child: Text('No jobs saved yet! Swipe right on jobs you like.'))
          : ListView.builder(
              itemCount: savedJobs.length,
              itemBuilder: (context, index) {
                final job = savedJobs[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(job.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${job.company} - ${job.location}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.open_in_new),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Opening job application link... (Coming Soon)')),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class ComingSoonPage extends StatelessWidget {
  final String pageName;

  const ComingSoonPage({super.key, required this.pageName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$pageName is coming soon!',
        style: const TextStyle(fontSize: 24),
      ),
    );
  }
} 
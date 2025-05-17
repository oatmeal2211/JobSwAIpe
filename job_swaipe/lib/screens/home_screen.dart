import 'package:flutter/material.dart';
import 'package:job_swaipe/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:job_swaipe/screens/community/community_screen.dart';

class JobListing {
  final String id;
  final String title;
  final String company;
  final String location;
  final String description;
  final String salary;

  JobListing({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.description,
    required this.salary,
  });

  factory JobListing.fromMap(String id, Map<String, dynamic> map) {
    return JobListing(
      id: id,
      title: map['title'] ?? '',
      company: map['company'] ?? '',
      location: map['location'] ?? '',
      description: map['description'] ?? '',
      salary: map['salary'] ?? '',
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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<JobListing> _jobListings = [];
  bool _isLoading = true;
  int _selectedIndex = 0;

  // List of pages to navigate to
  final List<Widget> _pages = const <Widget>[
    ComingSoonPage(pageName: 'Home'), // Placeholder for actual Home content
    ComingSoonPage(pageName: 'Resume Review'),
    ComingSoonPage(pageName: 'Explore'),
    CommunityScreen(), // Use our new CommunityScreen
  ];

  @override
  void initState() {
    super.initState();
    _loadJobListings();
  }

  Future<void> _loadJobListings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot = await _firestore.collection('jobs').get();
      final jobs = snapshot.docs.map((doc) => JobListing.fromMap(doc.id, doc.data())).toList();
      
      setState(() {
        _jobListings = jobs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JobSwAIpe'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              // Navigate to a profile page or show a profile dialog
              // For now, let's keep it simple or integrate with _buildProfileSection if desired
              // This could be a 5th item in BottomNav or an AppBar action
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile button clicked! Implement navigation.')),
              );
            },
          ),
          IconButton( // Added sign out button to AppBar for easier access
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: Center( // Ensures the ComingSoonPage content is centered
        child: _pages.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'HOME',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment), // Example icon for Resume Review
            label: 'RESUME REVIEW',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore), // Example icon for Explore
            label: 'EXPLORE',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group), // Example icon for Community
            label: 'COMMUNITY',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary, // Color for selected item
        unselectedItemColor: Colors.grey, // Color for unselected items
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Ensures all labels are visible
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
            backgroundImage: NetworkImage("https://example.com/user_avatar.png"), // Placeholder for user image
            child: Icon(Icons.person, size: 50, color: Colors.white), // Fallback icon
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

// A simple page to show that the page is coming soon
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
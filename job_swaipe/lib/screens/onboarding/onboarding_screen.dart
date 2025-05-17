import 'package:flutter/material.dart';
import 'package:job_swaipe/services/auth_service.dart';
import 'package:job_swaipe/services/user_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController(initialPage: 0);
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  
  // Form controllers
  final _formKey = GlobalKey<FormState>();
  String _jobCategory = 'Software Development';
  String _employmentType = 'Full-time';
  String _location = '';
  int _yearsOfExperience = 0;
  final List<String> _skills = [];
  
  // Options
  final List<String> _jobCategories = [
    'Software Development',
    'Data Science',
    'Design',
    'Marketing',
    'Sales',
    'Customer Service',
    'Finance',
    'HR',
    'Legal',
    'Healthcare',
    'Other'
  ];
  
  final List<String> _employmentTypes = [
    'Full-time',
    'Part-time',
    'Contract',
    'Internship',
    'Freelance',
    'Remote'
  ];
  
  // State
  int _currentPage = 0;
  bool _isLoading = false;
  String _errorMessage = '';
  
  // Skill input controller
  final TextEditingController _skillController = TextEditingController();
  
  @override
  void dispose() {
    _pageController.dispose();
    _skillController.dispose();
    super.dispose();
  }
  
  void _addSkill() {
    final skill = _skillController.text.trim();
    if (skill.isNotEmpty && !_skills.contains(skill)) {
      setState(() {
        _skills.add(skill);
        _skillController.clear();
      });
    }
  }
  
  void _removeSkill(String skill) {
    setState(() {
      _skills.remove(skill);
    });
  }
  
  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
  
  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
  
  Future<void> _completeOnboarding() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      
      try {
        final user = _authService.getCurrentUser();
        if (user != null) {
          await _userService.updateOnboardingData(
            userId: user.uid,
            jobCategory: _jobCategory,
            employmentType: _employmentType,
            location: _location,
            yearsOfExperience: _yearsOfExperience,
            skills: _skills,
          );
          
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/home');
          }
        } else {
          throw 'User not authenticated';
        }
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        automaticallyImplyLeading: false,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: (_currentPage + 1) / 3, // 3 pages total
              backgroundColor: Colors.grey[200],
              color: Theme.of(context).colorScheme.primary,
            ),
            
            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // Page 1: Job Category and Employment Type
                  _buildJobPreferencesPage(),
                  
                  // Page 2: Location
                  _buildLocationPage(),
                  
                  // Page 3: Experience and Skills
                  _buildExperienceAndSkillsPage(),
                ],
              ),
            ),
            
            // Error message
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            
            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button (hidden on first page)
                  _currentPage > 0
                      ? TextButton(
                          onPressed: _previousPage,
                          child: const Text('Back'),
                        )
                      : const SizedBox(width: 80),
                  
                  // Next/Finish button
                  ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : (_currentPage < 2 ? _nextPage : _completeOnboarding),
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : Text(_currentPage < 2 ? 'Next' : 'Finish'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Page 1: Job Category and Employment Type
  Widget _buildJobPreferencesPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What kind of job are you looking for?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Job Category
          const Text(
            'Job Category',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Select a job category',
            ),
            value: _jobCategory,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _jobCategory = value;
                });
              }
            },
            items: _jobCategories.map((category) {
              return DropdownMenuItem<String>(
                value: category,
                child: Text(category),
              );
            }).toList(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a job category';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          
          // Employment Type
          const Text(
            'Employment Type',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Select employment type',
            ),
            value: _employmentType,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _employmentType = value;
                });
              }
            },
            items: _employmentTypes.map((type) {
              return DropdownMenuItem<String>(
                value: type,
                child: Text(type),
              );
            }).toList(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select an employment type';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
  
  // Page 2: Location
  Widget _buildLocationPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Where would you like to work?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Location
          const Text(
            'Location',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: _location,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter city, state or country',
              prefixIcon: Icon(Icons.location_on),
            ),
            onChanged: (value) {
              setState(() {
                _location = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a location';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Additional text
          const Text(
            'This helps us find jobs that match your preferred location.',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  // Page 3: Experience and Skills
  Widget _buildExperienceAndSkillsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tell us about your experience',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Years of Experience
          const Text(
            'Years of Experience',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Select years of experience',
            ),
            value: _yearsOfExperience,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _yearsOfExperience = value;
                });
              }
            },
            items: List.generate(21, (index) {
              return DropdownMenuItem<int>(
                value: index,
                child: Text(index == 0 
                  ? 'No experience' 
                  : index == 1 
                      ? '1 year' 
                      : '$index years'),
              );
            }),
            validator: (value) {
              if (value == null) {
                return 'Please select years of experience';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          
          // Skills
          const Text(
            'Skills',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _skillController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Add a skill',
                    prefixIcon: Icon(Icons.trending_up),
                  ),
                  onFieldSubmitted: (_) => _addSkill(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _addSkill,
                icon: const Icon(Icons.add),
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Skills list
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _skills.map((skill) {
              return Chip(
                label: Text(skill),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => _removeSkill(skill),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
} 
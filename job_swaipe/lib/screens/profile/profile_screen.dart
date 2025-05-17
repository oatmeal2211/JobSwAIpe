import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:job_swaipe/models/user_profile.dart';
import 'package:job_swaipe/services/auth_service.dart';
import 'package:job_swaipe/services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  
  late TabController _tabController;
  UserProfile? _userProfile;
  Map<String, dynamic>? _resumeAnalysis;
  
  bool _isLoading = true;
  bool _isSaving = false;
  String _errorMessage = '';
  
  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  
  // Files for upload
  File? _newProfilePicture;
  File? _newResume;
  String? _resumeFileName;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserProfile();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final userId = _userService.getCurrentUserId();
      if (userId == null) {
        throw 'User not authenticated';
      }
      
      // Load user profile
      final profile = await _userService.getUserProfile(userId);
      
      // Load resume analysis if available
      final resumeAnalysis = await _userService.getResumeAnalysis(userId);
      
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _resumeAnalysis = resumeAnalysis;
          
          // Set form values
          if (profile != null) {
            _phoneController.text = profile.phone ?? '';
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _pickProfilePicture() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
      );
      
      if (pickedFile != null) {
        setState(() {
          _newProfilePicture = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }
  
  Future<void> _pickResume() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );
      
      if (result != null) {
        setState(() {
          _newResume = File(result.files.single.path!);
          _resumeFileName = result.files.single.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick resume: $e')),
      );
    }
  }
  
  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
        _errorMessage = '';
      });

      try {
        final userId = _userService.getCurrentUserId();
        if (userId == null) {
          throw 'User not authenticated';
        }
        
        await _userService.updateUserProfile(
          userId: userId,
          phone: _phoneController.text.trim(),
          profilePicture: _newProfilePicture,
          resume: _newResume,
        );
        
        // Reload user profile
        await _loadUserProfile();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
        }
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
        });
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }
  
  Future<void> _refreshResumeAnalysis() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final userId = _userService.getCurrentUserId();
      if (userId == null) {
        throw 'User not authenticated';
      }
      
      // Request new analysis
      final analysis = await _userService.requestResumeAnalysis(userId);
      
      if (mounted) {
        setState(() {
          _resumeAnalysis = analysis;
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resume analysis updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userProfile == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Failed to load profile'),
                      if (_errorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            _errorMessage,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ElevatedButton(
                        onPressed: _loadUserProfile,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Profile header
                    _buildProfileHeader(),
                    
                    // Tabs
                    TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(text: 'Personal Info'),
                        Tab(text: 'Resume Analysis'),
                      ],
                    ),
                    
                    // Tab content
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Personal Info Tab
                          SingleChildScrollView(
                            padding: const EdgeInsets.all(16.0),
                            child: _buildPersonalInfoTab(),
                          ),
                          
                          // Resume Analysis Tab
                          SingleChildScrollView(
                            padding: const EdgeInsets.all(16.0),
                            child: _buildResumeAnalysisTab(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
  
  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
      child: Column(
        children: [
          // Profile picture
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: _newProfilePicture != null
                    ? FileImage(_newProfilePicture!)
                    : (_userProfile?.profilePictureUrl != null 
                        ? NetworkImage(_userProfile!.profilePictureUrl!) as ImageProvider
                        : const AssetImage('assets/images/avatar_placeholder.png')),
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: _pickProfilePicture,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // User name
          Text(
            _userProfile?.name ?? 'User',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          // User email
          Text(
            _userProfile?.email ?? '',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPersonalInfoTab() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Personal Information section
          const Text(
            'Personal Information',
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Name (read-only)
          TextFormField(
            initialValue: _userProfile?.name,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person),
              helperText: 'Name cannot be changed',
            ),
          ),
          const SizedBox(height: 16),
          
          // Email (read-only)
          TextFormField(
            initialValue: _userProfile?.email,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
              helperText: 'Email cannot be changed',
            ),
          ),
          const SizedBox(height: 16),
          
          // Phone (editable)
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              prefixIcon: Icon(Icons.phone),
              hintText: 'Enter your phone number',
            ),
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            validator: (value) {
              if (value != null && value.isNotEmpty && value.length < 10) {
                return 'Please enter a valid phone number';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          
          // Resume upload section
          const Text(
            'Resume',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          // Current resume status
          if (_userProfile?.resumeUrl != null)
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Current Resume'),
              subtitle: const Text('Resume uploaded'),
              trailing: IconButton(
                icon: const Icon(Icons.download),
                onPressed: () {
                  // Open resume in browser
                  // For now, just show a snackbar
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Download feature coming soon')),
                  );
                },
              ),
            ),
          
          // Resume upload button
          OutlinedButton.icon(
            onPressed: _pickResume,
            icon: const Icon(Icons.upload_file),
            label: Text(_resumeFileName ?? 'Upload New Resume'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Uploading a new resume will update your profile automatically',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 24),
          
          // Error message
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          
          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save Changes'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumeAnalysisTab() {
    if (_resumeAnalysis == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.description_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No resume analysis available',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Upload a resume to generate an analysis',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _userProfile?.resumeUrl != null ? _refreshResumeAnalysis : null,
              child: const Text('Generate Analysis'),
            ),
          ],
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Actions
        Row(
          children: [
            const Expanded(
              child: Text(
                'Resume Analysis',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshResumeAnalysis,
              tooltip: 'Refresh analysis',
            ),
          ],
        ),
        const Divider(),
        
        // Summary
        if (_resumeAnalysis!.containsKey('summary') && _resumeAnalysis!['summary'] != null)
          ..._buildSection(
            title: 'Professional Summary',
            icon: Icons.person,
            content: _resumeAnalysis!['summary'],
          ),
        
        // Skills
        if (_resumeAnalysis!.containsKey('skills') && 
            _resumeAnalysis!['skills'] is List && 
            (_resumeAnalysis!['skills'] as List).isNotEmpty)
          ..._buildListSection(
            title: 'Skills',
            icon: Icons.engineering,
            items: List<String>.from(_resumeAnalysis!['skills']),
          ),
        
        // Experience
        if (_resumeAnalysis!.containsKey('experience') && 
            _resumeAnalysis!['experience'] is List && 
            (_resumeAnalysis!['experience'] as List).isNotEmpty)
          ..._buildExperienceSection(
            title: 'Work Experience',
            icon: Icons.work,
            experiences: List<Map<String, dynamic>>.from(
              _resumeAnalysis!['experience'].map((e) => Map<String, dynamic>.from(e))
            ),
          ),
        
        // Education
        if (_resumeAnalysis!.containsKey('education') && 
            _resumeAnalysis!['education'] is List && 
            (_resumeAnalysis!['education'] as List).isNotEmpty)
          ..._buildEducationSection(
            title: 'Education',
            icon: Icons.school,
            education: List<Map<String, dynamic>>.from(
              _resumeAnalysis!['education'].map((e) => Map<String, dynamic>.from(e))
            ),
          ),
        
        // Certifications
        if (_resumeAnalysis!.containsKey('certifications') && 
            _resumeAnalysis!['certifications'] is List && 
            (_resumeAnalysis!['certifications'] as List).isNotEmpty)
          ..._buildListSection(
            title: 'Certifications',
            icon: Icons.verified,
            items: List<String>.from(_resumeAnalysis!['certifications']),
          ),
        
        // Languages
        if (_resumeAnalysis!.containsKey('languages') && 
            _resumeAnalysis!['languages'] is List && 
            (_resumeAnalysis!['languages'] as List).isNotEmpty)
          ..._buildListSection(
            title: 'Languages',
            icon: Icons.language,
            items: List<String>.from(_resumeAnalysis!['languages']),
          ),
        
        // Interests
        if (_resumeAnalysis!.containsKey('interests') && 
            _resumeAnalysis!['interests'] is List && 
            (_resumeAnalysis!['interests'] as List).isNotEmpty)
          ..._buildListSection(
            title: 'Interests',
            icon: Icons.interests,
            items: List<String>.from(_resumeAnalysis!['interests']),
          ),
      ],
    );
  }
  
  List<Widget> _buildSection({
    required String title,
    required IconData icon,
    required String content,
  }) {
    return [
      const SizedBox(height: 16),
      Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text(content),
      const SizedBox(height: 8),
      const Divider(),
    ];
  }
  
  List<Widget> _buildListSection({
    required String title,
    required IconData icon,
    required List<String> items,
  }) {
    return [
      const SizedBox(height: 16),
      Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items.map((item) => 
          Chip(
            label: Text(item),
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          )
        ).toList(),
      ),
      const SizedBox(height: 8),
      const Divider(),
    ];
  }
  
  List<Widget> _buildExperienceSection({
    required String title,
    required IconData icon,
    required List<Map<String, dynamic>> experiences,
  }) {
    return [
      const SizedBox(height: 16),
      Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      ...experiences.map((exp) => 
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                exp['title'] ?? 'Role',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      exp['company'] ?? 'Company',
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  Text(
                    exp['duration'] ?? '',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              if (exp['description'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(exp['description']),
                ),
            ],
          ),
        )
      ).toList(),
      const Divider(),
    ];
  }
  
  List<Widget> _buildEducationSection({
    required String title,
    required IconData icon,
    required List<Map<String, dynamic>> education,
  }) {
    return [
      const SizedBox(height: 16),
      Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      ...education.map((edu) => 
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                edu['degree'] ?? 'Degree',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      edu['institution'] ?? 'Institution',
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  Text(
                    edu['year'] ?? '',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
      ).toList(),
      const Divider(),
    ];
  }
} 
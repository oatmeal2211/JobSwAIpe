import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:job_swaipe/models/course.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CourseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _dashscopeApiKey;
  final String _dashscopeBaseUrl = "https://dashscope-intl.aliyuncs.com/compatible-mode/v1";
  
  // Keep track of user's enrolled courses and learning paths
  final List<String> _enrolledCourseIds = [];
  final List<String> _enrolledPathIds = [];
  final Map<String, int> _courseProgress = {};
  
  CourseService() : _dashscopeApiKey = dotenv.env['DASHSCOPE_API_KEY'] ?? 'sk-52e97b66425c429f96a3e5ce21f2e5e7' {
    // Initialize sample data when the service is created
    _initializeSampleData();
    _loadUserEnrollments();
  }

  // Load user enrollments from local storage or Firebase
  Future<void> _loadUserEnrollments() async {
    try {
      // In a real app, this would load from Firebase or local storage
      // For now, we'll use some sample data and store in Firestore for persistence
      final userEnrollmentsDoc = await _firestore.collection('user_enrollments').doc('current_user').get();
      
      if (userEnrollmentsDoc.exists) {
        // Load from Firestore
        final data = userEnrollmentsDoc.data() as Map<String, dynamic>;
        _enrolledCourseIds.clear();
        _enrolledCourseIds.addAll(List<String>.from(data['enrolled_courses'] ?? []));
        
        _enrolledPathIds.clear();
        _enrolledPathIds.addAll(List<String>.from(data['enrolled_paths'] ?? []));
        
        _courseProgress.clear();
        final progressData = data['course_progress'] as Map<String, dynamic>? ?? {};
        progressData.forEach((key, value) {
          _courseProgress[key] = value as int;
        });
        
        print('Loaded enrollments: ${_enrolledCourseIds.length} courses, ${_enrolledPathIds.length} paths');
        print('Loaded course progress: ${_courseProgress.length} entries');
      } else {
        // Create initial sample data if no enrollments exist
        _enrolledCourseIds.addAll(['course_1', 'course_3']);
        _enrolledPathIds.add('path_1');
        
        // Sample progress data
        _courseProgress['course_1'] = 75;
        _courseProgress['course_3'] = 30;
        
        // Save initial data
        await _saveUserEnrollments();
      }
    } catch (e) {
      print('Error loading user enrollments: $e');
      // Fallback to default values if there's an error
      _enrolledCourseIds.addAll(['course_1', 'course_3']);
      _enrolledPathIds.add('path_1');
      _courseProgress['course_1'] = 75;
      _courseProgress['course_3'] = 30;
    }
  }
  
  // Save user enrollments to Firebase
  Future<void> _saveUserEnrollments() async {
    try {
      await _firestore.collection('user_enrollments').doc('current_user').set({
        'enrolled_courses': _enrolledCourseIds,
        'enrolled_paths': _enrolledPathIds,
        'course_progress': _courseProgress,
        'last_updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      print('Saved enrollments: ${_enrolledCourseIds.length} courses, ${_enrolledPathIds.length} paths');
      print('Saved course progress: ${_courseProgress.length} entries');
    } catch (e) {
      print('Error saving user enrollments: $e');
      // Show error in debug console but don't crash the app
    }
  }

  // Check if user is enrolled in a course
  bool isEnrolledInCourse(String courseId) {
    return _enrolledCourseIds.contains(courseId);
  }
  
  // Check if user is enrolled in a learning path
  bool isEnrolledInPath(String pathId) {
    return _enrolledPathIds.contains(pathId);
  }
  
  // Get course progress
  int getCourseProgress(String courseId) {
    return _courseProgress[courseId] ?? 0;
  }
  
  // Enroll in a course
  Future<bool> enrollInCourse(String courseId) async {
    try {
      bool wasNewEnrollment = false;
      
      if (!_enrolledCourseIds.contains(courseId)) {
        _enrolledCourseIds.add(courseId);
        _courseProgress[courseId] = 0;
        wasNewEnrollment = true;
      }
      
      // Save to Firebase
      await _saveUserEnrollments();
      return wasNewEnrollment;
    } catch (e) {
      print('Error enrolling in course: $e');
      return false;
    }
  }
  
  // Enroll in a learning path
  Future<bool> enrollInLearningPath(LearningPath path) async {
    try {
      // Add path ID to enrolled paths if not already enrolled
      if (!_enrolledPathIds.contains(path.id)) {
        _enrolledPathIds.add(path.id);
        
        // Initialize user enrolled courses list for this path
        path.userEnrolledCourses = [];
        
        // Auto-enroll in the first course of the path if not already enrolled
        if (path.courses.isNotEmpty) {
          final firstCourse = path.courses.first;
          if (!_enrolledCourseIds.contains(firstCourse.id)) {
            _enrolledCourseIds.add(firstCourse.id);
            _courseProgress[firstCourse.id] = 0;
          }
          path.userEnrolledCourses.add(firstCourse.id);
        }
        
        // Save to Firebase
        await _saveUserEnrollments();
        return true;
      } else {
        // Already enrolled, make sure path has updated userEnrolledCourses
        path.userEnrolledCourses = path.courses
            .where((course) => _enrolledCourseIds.contains(course.id))
            .map((course) => course.id)
            .toList();
        
        // Update path completion percentage
        path.updateCompletionPercentage();
        return false;
      }
    } catch (e) {
      print('Error enrolling in learning path: $e');
      return false;
    }
  }
  
  // Update course progress
  Future<bool> updateCourseProgress(String courseId, int progress) async {
    try {
      if (_enrolledCourseIds.contains(courseId)) {
        _courseProgress[courseId] = progress;
        
        // Save to Firebase
        await _saveUserEnrollments();
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating course progress: $e');
      return false;
    }
  }
  
  // Get user's enrolled courses
  Future<List<Course>> getEnrolledCourses() async {
    try {
      // Ensure enrollments are loaded
      if (_enrolledCourseIds.isEmpty) {
        await _loadUserEnrollments();
      }
      
      final allCourses = await getCourses();
      return allCourses.where((course) => _enrolledCourseIds.contains(course.id)).map((course) {
        // Set progress for each course
        course.courseProgress = _courseProgress[course.id] ?? 0;
        return course;
      }).toList();
    } catch (e) {
      print('Error getting enrolled courses: $e');
      return [];
    }
  }
  
  // Get user's enrolled learning paths
  Future<List<LearningPath>> getEnrolledLearningPaths() async {
    try {
      // Ensure enrollments are loaded
      if (_enrolledPathIds.isEmpty) {
        await _loadUserEnrollments();
      }
      
      final allPaths = await getLearningPaths();
      final enrolledPaths = allPaths.where((path) => _enrolledPathIds.contains(path.id)).toList();
      
      for (var path in enrolledPaths) {
        // Update enrolled courses in the path
        path.userEnrolledCourses = path.courses
            .where((course) => _enrolledCourseIds.contains(course.id))
            .map((course) => course.id)
            .toList();
        
        // Update course progress in the path
        for (var course in path.courses) {
          course.courseProgress = _courseProgress[course.id] ?? 0;
        }
        
        // Update overall path completion
        path.updateCompletionPercentage();
        
        print('Path ${path.title} has ${path.userEnrolledCourses.length} enrolled courses and ${path.completionPercentage}% completion');
      }
      
      return enrolledPaths;
    } catch (e) {
      print('Error getting enrolled learning paths: $e');
      return [];
    }
  }

  // Initialize sample courses and learning paths if they don't exist
  Future<void> _initializeSampleData() async {
    try {
      // Check if courses collection is empty
      final coursesSnapshot = await _firestore.collection('courses').limit(1).get();
      if (coursesSnapshot.docs.isEmpty) {
        // Add sample courses
        for (var course in _getSampleCourses()) {
          await _firestore.collection('courses').add({
            'title': course.title,
            'provider': course.provider,
            'description': course.description,
            'url': course.url,
            'imageUrl': course.imageUrl,
            'isFree': course.isFree,
            'skills': course.skills,
            'duration': course.duration,
            'rating': course.rating,
            'enrollmentCount': course.enrollmentCount,
            'level': course.level.name,
          });
        }
      }

      // Check if learning_paths collection is empty
      final pathsSnapshot = await _firestore.collection('learning_paths').limit(1).get();
      if (pathsSnapshot.docs.isEmpty) {
        // Get all courses to reference in learning paths
        final courses = await getCourses();
        
        // Add sample learning paths
        for (var path in _getSampleLearningPaths(courses)) {
          await _firestore.collection('learning_paths').add({
            'title': path.title,
            'description': path.description,
            'courseIds': path.courses.map((c) => c.id).toList(),
            'targetRoles': path.targetRoles,
            'targetSkills': path.targetSkills,
            'estimatedTimeToComplete': path.estimatedTimeToComplete,
            'completionPercentage': path.completionPercentage,
          });
        }
      }
    } catch (e) {
      print('Error initializing sample data: $e');
    }
  }

  // Sample courses data
  List<Course> _getSampleCourses() {
    return [
      Course(
        id: 'course_1',
        title: 'Web Development Bootcamp',
        provider: 'Udemy',
        description: 'A comprehensive course covering HTML, CSS, JavaScript, Node.js, and more.',
        url: 'https://www.udemy.com/course/the-web-developer-bootcamp/',
        imageUrl: 'https://img-c.udemycdn.com/course/480x270/625204_436a_3.jpg',
        isFree: false,
        skills: ['HTML', 'CSS', 'JavaScript', 'Node.js', 'Express'],
        duration: '63 hours',
        rating: 4.7,
        enrollmentCount: 700000,
        level: CourseLevel.beginner,
      ),
      Course(
        id: 'course_2',
        title: 'Machine Learning A-Z',
        provider: 'Udemy',
        description: 'Learn to create Machine Learning Algorithms in Python and R.',
        url: 'https://www.udemy.com/course/machinelearning/',
        imageUrl: 'https://img-c.udemycdn.com/course/480x270/950390_270f_3.jpg',
        isFree: false,
        skills: ['Python', 'R', 'Machine Learning', 'Data Science'],
        duration: '44 hours',
        rating: 4.5,
        enrollmentCount: 800000,
        level: CourseLevel.intermediate,
      ),
      Course(
        id: 'course_3',
        title: 'Flutter & Dart - The Complete Guide',
        provider: 'Udemy',
        description: 'A comprehensive guide to building beautiful, fast mobile apps with Flutter.',
        url: 'https://www.udemy.com/course/flutter-bootcamp-with-dart/',
        imageUrl: 'https://img-c.udemycdn.com/course/480x270/1708340_7108_5.jpg',
        isFree: false,
        skills: ['Flutter', 'Dart', 'Mobile Development', 'Firebase'],
        duration: '42 hours',
        rating: 4.6,
        enrollmentCount: 200000,
        level: CourseLevel.beginner,
      ),
      Course(
        id: 'course_4',
        title: 'Python for Everybody Specialization',
        provider: 'Coursera',
        description: 'Learn to Program and Analyze Data with Python.',
        url: 'https://www.coursera.org/specializations/python',
        imageUrl: 'https://s3.amazonaws.com/coursera-course-photos/08/33f720502a11e59e72391aa537f5c9/pythonlearn_thumbnail_1x1.png',
        isFree: true,
        skills: ['Python', 'Data Analysis', 'SQL', 'JSON', 'XML'],
        duration: '8 months',
        rating: 4.8,
        enrollmentCount: 1000000,
        level: CourseLevel.beginner,
      ),
      Course(
        id: 'course_5',
        title: 'CS50: Introduction to Computer Science',
        provider: 'edX',
        description: 'Harvard University\'s introduction to the intellectual enterprises of computer science.',
        url: 'https://www.edx.org/course/introduction-computer-science-harvardx-cs50x',
        imageUrl: 'https://prod-discovery.edx-cdn.org/media/course/image/da1b2400-322b-459b-97b0-0c557f05d017-a3d1899d3fb9.small.jpg',
        isFree: true,
        skills: ['C', 'Python', 'SQL', 'JavaScript', 'Computer Science'],
        duration: '12 weeks',
        rating: 4.9,
        enrollmentCount: 3000000,
        level: CourseLevel.beginner,
      ),
    ];
  }

  // Sample learning paths
  List<LearningPath> _getSampleLearningPaths(List<Course> allCourses) {
    // Find courses by ID (this is just for sample data)
    Course? findCourseById(String id) {
      try {
        return allCourses.firstWhere((c) => c.id == id);
      } catch (_) {
        return null;
      }
    }
    
    // Web Development Path
    final webDevCourses = [
      findCourseById('course_1'),
    ].whereType<Course>().toList();
    
    // Data Science Path
    final dataScienceCourses = [
      findCourseById('course_2'),
      findCourseById('course_4'),
    ].whereType<Course>().toList();
    
    // Mobile Development Path
    final mobileDevCourses = [
      findCourseById('course_3'),
    ].whereType<Course>().toList();
    
    return [
      LearningPath(
        id: 'path_1',
        title: 'Web Developer Career Path',
        description: 'Become a full-stack web developer with this comprehensive learning path.',
        courses: webDevCourses,
        targetRoles: ['Front-end Developer', 'Back-end Developer', 'Full-stack Developer'],
        targetSkills: ['HTML', 'CSS', 'JavaScript', 'Node.js', 'React', 'Express', 'MongoDB'],
        estimatedTimeToComplete: '6 months',
        completionPercentage: 0,
      ),
      LearningPath(
        id: 'path_2',
        title: 'Data Science Career Path',
        description: 'Master data science and machine learning to become a data scientist.',
        courses: dataScienceCourses,
        targetRoles: ['Data Scientist', 'Data Analyst', 'Machine Learning Engineer'],
        targetSkills: ['Python', 'R', 'SQL', 'Machine Learning', 'Data Visualization', 'Statistics'],
        estimatedTimeToComplete: '8 months',
        completionPercentage: 0,
      ),
      LearningPath(
        id: 'path_3',
        title: 'Mobile App Developer Path',
        description: 'Learn to build beautiful, responsive mobile applications for iOS and Android.',
        courses: mobileDevCourses,
        targetRoles: ['Mobile Developer', 'Flutter Developer', 'iOS Developer', 'Android Developer'],
        targetSkills: ['Flutter', 'Dart', 'Mobile UI Design', 'Firebase', 'State Management'],
        estimatedTimeToComplete: '5 months',
        completionPercentage: 0,
      ),
    ];
  }

  // Fetch courses from Firestore
  Future<List<Course>> getCourses() async {
    try {
      final snapshot = await _firestore.collection('courses').get();
      return snapshot.docs.map((doc) => Course.fromMap({
        'id': doc.id,
        ...doc.data(),
      })).toList();
    } catch (e) {
      print('Error fetching courses: $e');
      return [];
    }
  }

  // Fetch learning paths from Firestore
  Future<List<LearningPath>> getLearningPaths() async {
    try {
      final courses = await getCourses();
      final snapshot = await _firestore.collection('learning_paths').get();
      return snapshot.docs.map((doc) => LearningPath.fromMap({
        'id': doc.id,
        ...doc.data(),
      }, courses)).toList();
    } catch (e) {
      print('Error fetching learning paths: $e');
      return [];
    }
  }

  // Get skill gaps based on resume and job matches
  Future<List<SkillGap>> getSkillGaps(String resumeJson, String jobJson) async {
    try {
      final courses = await getCourses();
      final response = await _analyzeSkillGaps(resumeJson, jobJson);
      
      final List<dynamic> skillGapsData = response['skill_gaps'] ?? [];
      return skillGapsData.map((data) => SkillGap.fromMap(data, courses)).toList();
    } catch (e) {
      print('Error analyzing skill gaps: $e');
      return [];
    }
  }

  // Search for courses online based on skill name
  Future<List<Course>> searchOnlineCourses(String skillName) async {
    try {
      final response = await _searchCoursesWithAI(skillName);
      return _parseCourseSearchResults(response);
    } catch (e) {
      print('Error searching online courses: $e');
      return [];
    }
  }

  // Get recommended learning path for a specific career goal
  Future<LearningPath?> getRecommendedLearningPath(String careerGoal, List<String> currentSkills) async {
    try {
      final courses = await getCourses();
      final learningPaths = await getLearningPaths();
      
      // Find the most relevant learning path
      final response = await _getRecommendedPathWithAI(careerGoal, currentSkills, learningPaths);
      
      if (response['recommended_path_id'] != null) {
        final pathId = response['recommended_path_id'];
        return learningPaths.firstWhere(
          (path) => path.id == pathId,
          orElse: () => _createCustomLearningPath(careerGoal, response, courses),
        );
      } else {
        // Create a custom learning path even if no path_id is returned
        return _createCustomLearningPath(careerGoal, response, courses);
      }
    } catch (e) {
      print('Error getting recommended learning path: $e');
      
      // Create a fallback learning path with mock data if API fails
      return _createFallbackLearningPath(careerGoal);
    }
  }

  // Private methods for AI integration
  Future<Map<String, dynamic>> _analyzeSkillGaps(String resumeJson, String jobJson) async {
    final url = Uri.parse('$_dashscopeBaseUrl/chat/completions');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_dashscopeApiKey',
    };

    final body = jsonEncode({
      'model': 'qwen-max',
      'messages': [
        {
          'role': 'system',
          'content': 'You are an AI assistant that analyzes skill gaps between a resume and job requirements. Identify missing skills, their importance, and related job roles.'
        },
        {
          'role': 'user',
          'content': 'Analyze the skill gap between this resume and job. Resume: $resumeJson Job: $jobJson. Return a JSON with skill_gaps array containing objects with skillName, description, importance (1-10), relatedRoles array, and recommendedCourseIds array.'
        }
      ]
    });

    final response = await http.post(url, headers: headers, body: body);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'];
      
      // Extract JSON from the AI response
      return _extractJsonFromAIResponse(content);
    } else {
      throw Exception('Failed to analyze skill gaps: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> _searchCoursesWithAI(String skillName) async {
    final url = Uri.parse('$_dashscopeBaseUrl/chat/completions');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_dashscopeApiKey',
    };

    final body = jsonEncode({
      'model': 'qwen-max',
      'messages': [
        {
          'role': 'system',
          'content': 'You are an AI assistant that helps find online courses for specific skills. Focus on free courses from platforms like Coursera, edX, freeCodeCamp, YouTube, and official documentation.'
        },
        {
          'role': 'user',
          'content': 'Find me the best free online courses to learn $skillName. Return a JSON with courses array containing objects with title, provider, description, url, imageUrl, isFree, skills array, duration, rating, and level.'
        }
      ]
    });

    final response = await http.post(url, headers: headers, body: body);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'];
      
      // Extract JSON from the AI response
      return _extractJsonFromAIResponse(content);
    } else {
      throw Exception('Failed to search courses: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> _getRecommendedPathWithAI(
      String careerGoal, List<String> currentSkills, List<LearningPath> existingPaths) async {
    final url = Uri.parse('$_dashscopeBaseUrl/chat/completions');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_dashscopeApiKey',
    };

    final existingPathsJson = jsonEncode(existingPaths.map((p) => {
      'id': p.id,
      'title': p.title,
      'targetRoles': p.targetRoles,
      'targetSkills': p.targetSkills,
    }).toList());

    final body = jsonEncode({
      'model': 'qwen-max',
      'messages': [
        {
          'role': 'system',
          'content': 'You are an AI assistant that recommends learning paths based on career goals and current skills.'
        },
        {
          'role': 'user',
          'content': 'Recommend a learning path for someone who wants to become a $careerGoal. Their current skills are: ${currentSkills.join(", ")}. Here are the existing learning paths: $existingPathsJson. Return a JSON with recommended_path_id (if an existing path matches), or path_description, target_skills array, estimated_time, and recommended_courses array with course details.'
        }
      ]
    });

    try {
      print('Sending request to DashScope API for career path recommendation...');
      final response = await http.post(url, headers: headers, body: body);
      
      if (response.statusCode == 200) {
        print('Received successful response from DashScope API');
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        
        // Extract JSON from the AI response
        final result = _extractJsonFromAIResponse(content);
        print('Extracted recommendation data: ${result.keys}');
        return result;
      } else {
        print('API error: ${response.statusCode} - ${response.body}');
        if (response.statusCode == 401 || response.statusCode == 403) {
          throw Exception('Authentication error: Please check your API key');
        } else if (response.statusCode == 429) {
          throw Exception('Rate limit exceeded: Please try again later');
        } else {
          throw Exception('API error (${response.statusCode}): ${response.reasonPhrase}');
        }
      }
    } catch (e) {
      print('Error in _getRecommendedPathWithAI: $e');
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }

  // Helper methods
  Map<String, dynamic> _extractJsonFromAIResponse(String content) {
    try {
      // Try to parse the entire content as JSON
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      print('Failed to parse content as JSON directly, trying to extract JSON...');
      // If that fails, try to extract JSON from the content
      final jsonRegExp = RegExp(r'```json\s*([\s\S]*?)\s*```|(\{[\s\S]*\})');
      final match = jsonRegExp.firstMatch(content);
      
      if (match != null) {
        final jsonStr = (match.group(1) ?? match.group(2))?.trim();
        if (jsonStr != null) {
          try {
            print('Found JSON string in content');
            return jsonDecode(jsonStr) as Map<String, dynamic>;
          } catch (e) {
            print('Failed to parse extracted JSON: $e');
            print('JSON string was: $jsonStr');
          }
        }
      }
      
      print('No valid JSON found in response, returning empty map');
      print('Original content: $content');
      // If no JSON found, return empty map
      return {};
    }
  }

  List<Course> _parseCourseSearchResults(Map<String, dynamic> response) {
    final List<dynamic> coursesData = response['courses'] ?? [];
    int id = 1000; // Starting ID for online courses
    
    return coursesData.map((data) {
      return Course.fromMap({
        'id': 'online_${id++}',
        ...data,
      });
    }).toList();
  }

  List<Course> _parseRecommendedCourses(List<dynamic> coursesData, List<Course> existingCourses) {
    final List<Course> recommendedCourses = [];
    int id = 2000; // Starting ID for recommended courses
    
    for (var data in coursesData) {
      if (data['id'] != null) {
        // Try to find in existing courses
        final existingCourse = existingCourses.firstWhere(
          (c) => c.id == data['id'],
          orElse: () => Course.fromMap({
            'id': 'recommended_${id++}',
            ...data,
          }),
        );
        recommendedCourses.add(existingCourse);
      } else {
        // Create new course
        recommendedCourses.add(Course.fromMap({
          'id': 'recommended_${id++}',
          ...data,
        }));
      }
    }
    
    return recommendedCourses;
  }

  // Helper method to create a custom learning path
  LearningPath _createCustomLearningPath(String careerGoal, Map<String, dynamic> response, List<Course> courses) {
    // Extract course data from response or create default courses if none provided
    List<dynamic> courseData = response['recommended_courses'] as List<dynamic>? ?? [];
    if (courseData.isEmpty) {
      // Add some default courses based on the career goal
      courseData = [
        {
          'title': 'Introduction to $careerGoal',
          'provider': 'Coursera',
          'description': 'Learn the fundamentals of $careerGoal with this comprehensive course.',
          'url': 'https://www.coursera.org',
          'imageUrl': '',
          'isFree': true,
          'skills': [careerGoal.toLowerCase()],
          'duration': '4 weeks',
          'rating': 4.5,
          'level': 'beginner',
        },
        {
          'title': 'Advanced $careerGoal Techniques',
          'provider': 'edX',
          'description': 'Take your $careerGoal skills to the next level with advanced concepts and techniques.',
          'url': 'https://www.edx.org',
          'imageUrl': '',
          'isFree': true,
          'skills': [careerGoal.toLowerCase(), 'advanced techniques'],
          'duration': '6 weeks',
          'rating': 4.7,
          'level': 'intermediate',
        }
      ];
    }
    
    // Extract target skills or create default ones
    List<String> targetSkills = List<String>.from(response['target_skills'] ?? []);
    if (targetSkills.isEmpty) {
      targetSkills = ['${careerGoal.toLowerCase()} fundamentals', 'problem solving', 'communication'];
    }
    
    return LearningPath(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      title: response['path_title'] ?? 'Custom Path for $careerGoal',
      description: response['path_description'] ?? 'A personalized learning path to help you become a successful $careerGoal.',
      courses: _parseRecommendedCourses(courseData, courses),
      targetRoles: [careerGoal],
      targetSkills: targetSkills,
      estimatedTimeToComplete: response['estimated_time'] ?? '3-6 months',
      completionPercentage: 0,
    );
  }
  
  // Create a fallback learning path with mock data
  LearningPath _createFallbackLearningPath(String careerGoal) {
    final mockCourses = [
      Course(
        id: 'fallback_1',
        title: 'Getting Started with $careerGoal',
        provider: 'Coursera',
        description: 'A beginner-friendly introduction to $careerGoal fundamentals.',
        url: 'https://www.coursera.org',
        imageUrl: '',
        isFree: true,
        skills: ['${careerGoal.toLowerCase()} basics'],
        duration: '4 weeks',
        rating: 4.5,
        level: CourseLevel.beginner,
      ),
      Course(
        id: 'fallback_2',
        title: '$careerGoal in Practice',
        provider: 'edX',
        description: 'Apply your $careerGoal knowledge with hands-on projects.',
        url: 'https://www.edx.org',
        imageUrl: '',
        isFree: true,
        skills: ['${careerGoal.toLowerCase()} application', 'project management'],
        duration: '6 weeks',
        rating: 4.3,
        level: CourseLevel.intermediate,
      ),
    ];
    
    return LearningPath(
      id: 'fallback_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Learning Path for $careerGoal',
      description: 'Start your journey to becoming a $careerGoal with this curated learning path.',
      courses: mockCourses,
      targetRoles: [careerGoal],
      targetSkills: ['${careerGoal.toLowerCase()} fundamentals', 'problem solving', 'communication'],
      estimatedTimeToComplete: '3-6 months',
      completionPercentage: 0,
    );
  }

  // Unenroll from a learning path
  Future<bool> unenrollFromLearningPath(String pathId) async {
    try {
      if (_enrolledPathIds.contains(pathId)) {
        _enrolledPathIds.remove(pathId);
        
        // Save to Firebase
        await _saveUserEnrollments();
        return true;
      }
      return false;
    } catch (e) {
      print('Error unenrolling from learning path: $e');
      return false;
    }
  }

  // Enroll in the next course of a learning path
  Future<bool> enrollInNextPathCourse(String pathId) async {
    try {
      // Check if path exists and user is enrolled
      if (!_enrolledPathIds.contains(pathId)) {
        return false;
      }
      
      // Get the path details
      final paths = await getLearningPaths();
      final pathIndex = paths.indexWhere((p) => p.id == pathId);
      if (pathIndex < 0) return false;
      
      final path = paths[pathIndex];
      
      // Find the next course that user is not enrolled in
      for (int i = 0; i < path.courses.length; i++) {
        final course = path.courses[i];
        
        // If this is the first course or the previous course is completed
        bool canEnroll = i == 0 || 
            (_enrolledCourseIds.contains(path.courses[i-1].id) && 
             (_courseProgress[path.courses[i-1].id] ?? 0) >= 100);
        
        if (canEnroll && !_enrolledCourseIds.contains(course.id)) {
          // Enroll in this course
          _enrolledCourseIds.add(course.id);
          _courseProgress[course.id] = 0;
          
          // Save to Firebase
          await _saveUserEnrollments();
          return true;
        }
      }
      
      // No new courses to enroll in
      return false;
    } catch (e) {
      print('Error enrolling in next path course: $e');
      return false;
    }
  }
} 
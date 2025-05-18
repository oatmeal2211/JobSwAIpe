import 'package:flutter/material.dart';

class Course {
  final String id;
  final String title;
  final String provider;
  final String description;
  final String url;
  final String imageUrl;
  final bool isFree;
  final List<String> skills;
  final String duration;
  final double rating;
  final int enrollmentCount;
  final CourseLevel level;
  int courseProgress; // Progress percentage (0-100)

  Course({
    required this.id,
    required this.title,
    required this.provider,
    required this.description,
    required this.url,
    required this.imageUrl,
    required this.isFree,
    required this.skills,
    required this.duration,
    required this.rating,
    this.enrollmentCount = 0,
    required this.level,
    this.courseProgress = 0,
  });

  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      provider: map['provider'] ?? '',
      description: map['description'] ?? '',
      url: map['url'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      isFree: map['isFree'] ?? false,
      skills: List<String>.from(map['skills'] ?? []),
      duration: map['duration'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      enrollmentCount: map['enrollmentCount'] ?? 0,
      level: _parseCourseLevel(map['level']),
      courseProgress: map['courseProgress'] ?? 0,
    );
  }

  static CourseLevel _parseCourseLevel(String? level) {
    switch (level?.toLowerCase()) {
      case 'beginner':
        return CourseLevel.beginner;
      case 'intermediate':
        return CourseLevel.intermediate;
      case 'advanced':
        return CourseLevel.advanced;
      default:
        return CourseLevel.beginner;
    }
  }
}

enum CourseLevel {
  beginner,
  intermediate,
  advanced
}

class LearningPath {
  final String id;
  final String title;
  final String description;
  final List<Course> courses;
  final List<String> targetRoles;
  final List<String> targetSkills;
  final String estimatedTimeToComplete;
  int completionPercentage;
  List<String> userEnrolledCourses; // IDs of courses user is enrolled in

  LearningPath({
    required this.id,
    required this.title,
    required this.description,
    required this.courses,
    required this.targetRoles,
    required this.targetSkills,
    required this.estimatedTimeToComplete,
    this.completionPercentage = 0,
    this.userEnrolledCourses = const [],
  });

  factory LearningPath.fromMap(Map<String, dynamic> map, List<Course> allCourses) {
    List<String> courseIds = List<String>.from(map['courseIds'] ?? []);
    List<Course> pathCourses = allCourses.where((course) => courseIds.contains(course.id)).toList();
    
    return LearningPath(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      courses: pathCourses,
      targetRoles: List<String>.from(map['targetRoles'] ?? []),
      targetSkills: List<String>.from(map['targetSkills'] ?? []),
      estimatedTimeToComplete: map['estimatedTimeToComplete'] ?? '',
      completionPercentage: map['completionPercentage'] ?? 0,
      userEnrolledCourses: List<String>.from(map['userEnrolledCourses'] ?? []),
    );
  }

  // Calculate overall path completion percentage based on enrolled courses and their progress
  void updateCompletionPercentage() {
    if (courses.isEmpty || userEnrolledCourses.isEmpty) {
      completionPercentage = 0;
      return;
    }
    
    int totalProgress = 0;
    int enrolledCoursesCount = 0;
    
    for (var course in courses) {
      if (userEnrolledCourses.contains(course.id)) {
        totalProgress += course.courseProgress;
        enrolledCoursesCount++;
      }
    }
    
    if (enrolledCoursesCount > 0) {
      completionPercentage = (totalProgress / enrolledCoursesCount).round();
    } else {
      completionPercentage = 0;
    }
  }
}

class SkillGap {
  final String skillName;
  final String description;
  final int importance; // 1-10 scale
  final List<String> relatedRoles;
  final List<Course> recommendedCourses;

  SkillGap({
    required this.skillName,
    required this.description,
    required this.importance,
    required this.relatedRoles,
    required this.recommendedCourses,
  });

  factory SkillGap.fromMap(Map<String, dynamic> map, List<Course> allCourses) {
    List<String> courseIds = List<String>.from(map['recommendedCourseIds'] ?? []);
    List<Course> courses = allCourses.where((course) => courseIds.contains(course.id)).toList();
    
    return SkillGap(
      skillName: map['skillName'] ?? '',
      description: map['description'] ?? '',
      importance: map['importance'] ?? 5,
      relatedRoles: List<String>.from(map['relatedRoles'] ?? []),
      recommendedCourses: courses,
    );
  }
} 
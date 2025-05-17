import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? profilePictureUrl;
  final String? resumeUrl;
  final bool onboardingCompleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final JobPreferences? jobPreferences;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.profilePictureUrl,
    this.resumeUrl,
    this.onboardingCompleted = false,
    this.createdAt,
    this.updatedAt,
    this.jobPreferences,
  });

  // Create UserProfile from Firestore data
  factory UserProfile.fromMap(Map<String, dynamic> map, String id) {
    return UserProfile(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'],
      profilePictureUrl: map['profilePictureUrl'],
      resumeUrl: map['resumeUrl'],
      onboardingCompleted: map['onboardingCompleted'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      jobPreferences: map['jobPreferences'] != null
          ? JobPreferences.fromMap(map['jobPreferences'])
          : null,
    );
  }

  // Convert UserProfile to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'profilePictureUrl': profilePictureUrl,
      'resumeUrl': resumeUrl,
      'onboardingCompleted': onboardingCompleted,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'jobPreferences': jobPreferences?.toMap(),
    };
  }
}

class JobPreferences {
  final String jobCategory;
  final String employmentType;
  final String location;
  final int yearsOfExperience;
  final List<String> skills;

  JobPreferences({
    required this.jobCategory,
    required this.employmentType,
    required this.location,
    required this.yearsOfExperience,
    this.skills = const [],
  });

  // Create JobPreferences from map
  factory JobPreferences.fromMap(Map<String, dynamic> map) {
    return JobPreferences(
      jobCategory: map['jobCategory'] ?? '',
      employmentType: map['employmentType'] ?? '',
      location: map['location'] ?? '',
      yearsOfExperience: map['yearsOfExperience'] ?? 0,
      skills: List<String>.from(map['skills'] ?? []),
    );
  }

  // Convert JobPreferences to map
  Map<String, dynamic> toMap() {
    return {
      'jobCategory': jobCategory,
      'employmentType': employmentType,
      'location': location,
      'yearsOfExperience': yearsOfExperience,
      'skills': skills,
    };
  }
} 
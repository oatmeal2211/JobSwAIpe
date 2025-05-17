import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:job_swaipe/models/user_profile.dart';
import 'package:job_swaipe/services/ai_service.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AIService _aiService = AIService();

  // Collection references
  final CollectionReference _usersCollection = 
      FirebaseFirestore.instance.collection('users');

  // Create user in Firestore after registration
  Future<void> createUserProfile({
    required String userId,
    required String name,
    required String email,
    String? phone,
    File? profilePicture,
    File? resume,
  }) async {
    String? profilePictureUrl;
    String? resumeUrl;
    
    // Upload profile picture if provided
    if (profilePicture != null) {
      profilePictureUrl = await _uploadFile(
        file: profilePicture, 
        path: 'profile_pictures/$userId'
      );
    }
    
    // Upload resume if provided
    if (resume != null) {
      resumeUrl = await _uploadFile(
        file: resume, 
        path: 'resumes/$userId'
      );
    }
    
    // Create user document
    await _usersCollection.doc(userId).set({
      'name': name,
      'email': email,
      'phone': phone,
      'profilePictureUrl': profilePictureUrl,
      'resumeUrl': resumeUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'onboardingCompleted': false,
    });
    
    // If resume was uploaded, analyze it
    if (resumeUrl != null) {
      await analyzeAndUpdateResume(userId, resumeUrl);
    }
  }

  // Upload file to Firebase Storage
  Future<String> _uploadFile({required File file, required String path}) async {
    try {
      final ref = _storage.ref().child(path);
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      throw 'Failed to upload file: $e';
    }
  }
  
  // Update user onboarding data
  Future<void> updateOnboardingData({
    required String userId,
    required String jobCategory,
    required String employmentType,
    required String location,
    required int yearsOfExperience,
    List<String>? skills,
  }) async {
    try {
      // Use set with merge option instead of update to handle documents that don't exist
      await _usersCollection.doc(userId).set({
        'jobPreferences': {
          'jobCategory': jobCategory,
          'employmentType': employmentType,
          'location': location,
          'yearsOfExperience': yearsOfExperience,
          'skills': skills ?? [],
        },
        'onboardingCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // This will merge with existing data or create new document
    } catch (e) {
      throw 'Failed to update onboarding data: $e';
    }
  }
  
  // Update user profile
  Future<void> updateUserProfile({
    required String userId,
    String? phone,
    File? profilePicture,
    File? resume,
  }) async {
    try {
      final Map<String, dynamic> updateData = {
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      // Update phone if provided
      if (phone != null) {
        updateData['phone'] = phone;
      }
      
      // Upload new profile picture if provided
      if (profilePicture != null) {
        final String profilePictureUrl = await _uploadFile(
          file: profilePicture,
          path: 'profile_pictures/$userId',
        );
        updateData['profilePictureUrl'] = profilePictureUrl;
      }
      
      // Upload new resume if provided
      if (resume != null) {
        final String resumeUrl = await _uploadFile(
          file: resume,
          path: 'resumes/$userId',
        );
        updateData['resumeUrl'] = resumeUrl;
        
        // Analyze the new resume
        await analyzeAndUpdateResume(userId, resumeUrl);
      }
      
      // Update user document
      await _usersCollection.doc(userId).update(updateData);
    } catch (e) {
      throw 'Failed to update user profile: $e';
    }
  }
  
  // Analyze resume and update user profile with the results
  Future<void> analyzeAndUpdateResume(String userId, String resumeUrl) async {
    try {
      // Extract text from resume
      final String resumeText = await _aiService.extractTextFromResumeUrl(resumeUrl);
      
      // Analyze resume with AI
      final Map<String, dynamic> resumeAnalysis = await _aiService.analyzeResume(resumeText);
      
      // Update user document with resume analysis
      await _usersCollection.doc(userId).set({
        'resumeAnalysis': resumeAnalysis,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error analyzing resume: $e');
      // Don't throw error to prevent blocking the user registration/update process
    }
  }
  
  // Get user profile
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (doc.exists) {
        return UserProfile.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw 'Failed to get user profile: $e';
    }
  }
  
  // Get resume analysis
  Future<Map<String, dynamic>?> getResumeAnalysis(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['resumeAnalysis'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      throw 'Failed to get resume analysis: $e';
    }
  }
  
  // Check if current user has completed onboarding
  Future<bool> hasCompletedOnboarding() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      final doc = await _usersCollection.doc(user.uid).get();
      if (doc.exists) {
        return doc.get('onboardingCompleted') ?? false;
      }
      return false;
    } catch (e) {
      print('Error checking onboarding status: $e');
      return false;
    }
  }
  
  // Get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }
  
  // Request resume analysis
  Future<Map<String, dynamic>> requestResumeAnalysis(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (!doc.exists) {
        throw 'User not found';
      }
      
      final data = doc.data() as Map<String, dynamic>;
      final String? resumeUrl = data['resumeUrl'] as String?;
      
      if (resumeUrl == null) {
        throw 'No resume found';
      }
      
      // Analyze resume
      await analyzeAndUpdateResume(userId, resumeUrl);
      
      // Fetch updated analysis
      final updatedDoc = await _usersCollection.doc(userId).get();
      final updatedData = updatedDoc.data() as Map<String, dynamic>;
      final analysis = updatedData['resumeAnalysis'] as Map<String, dynamic>?;
      
      if (analysis == null) {
        throw 'Failed to analyze resume';
      }
      
      return analysis;
    } catch (e) {
      throw 'Failed to analyze resume: $e';
    }
  }
} 
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:job_swaipe/services/storage_service.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = StorageService();

  // Check if user is logged in
  Future<bool> isUserLoggedIn() async {
    return _auth.currentUser != null;
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'An error occurred during sign in';
    }
  }

  // Register with email and password and store user data
  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    File? profilePicture,
    File? resume,
  }) async {
    try {
      // Create user with email and password
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Get the user ID
      final uid = userCredential.user!.uid;
      
      // Upload profile picture if provided
      String? profilePictureUrl;
      if (profilePicture != null) {
        try {
          profilePictureUrl = await _uploadFile(
            file: profilePicture,
            path: 'profile_pictures/$uid',
          );
        } catch (e) {
          debugPrint('Error uploading profile picture: $e');
        }
      }
      
      // Upload resume if provided
      String? resumeUrl;
      if (resume != null) {
        try {
          resumeUrl = await _uploadFile(
            file: resume,
            path: 'resumes/$uid',
          );
        } catch (e) {
          debugPrint('Error uploading resume: $e');
        }
      }
      
      // Create user document in Firestore
      await _firestore.collection('users').doc(uid).set({
        'fullName': fullName,
        'email': email,
        'profilePictureUrl': profilePictureUrl,
        'resumeUrl': resumeUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'onboardingCompleted': false,
      });
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'An error occurred during registration';
    }
  }

  // Save onboarding data
  Future<void> saveOnboardingData({
    required String jobType,
    required String employmentType,
    required String location,
    required int yearsOfExperience,
    List<String>? skills,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw 'User is not authenticated';
    }
    
    await _firestore.collection('users').doc(user.uid).update({
      'jobPreferences': {
        'jobType': jobType,
        'employmentType': employmentType,
        'location': location,
        'yearsOfExperience': yearsOfExperience,
        'skills': skills ?? [],
      },
      'onboardingCompleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Get user data
  Future<Map<String, dynamic>?> getUserData() async {
    final user = _auth.currentUser;
    if (user == null) {
      return null;
    }
    
    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.data();
  }

  // Check if onboarding is completed
  Future<bool> isOnboardingCompleted() async {
    final userData = await getUserData();
    return userData != null && userData['onboardingCompleted'] == true;
  }

  // Upload file to Alibaba Cloud OSS
  Future<String> _uploadFile({required File file, required String path}) async {
    try {
      return await _storageService.uploadFile(file: file, path: path);
    } catch (e) {
      debugPrint('Error in _uploadFile: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }
} 
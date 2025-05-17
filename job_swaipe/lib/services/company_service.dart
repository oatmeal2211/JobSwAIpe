import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/company_review.dart';
import '../models/company.dart';

class CompanyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();
  List<Map<String, dynamic>> _companies = [];
  List<Map<String, dynamic>> _jobs = [];
  bool _isDataLoaded = false;

  // Load company data from JSON files
  Future<void> loadCompanyData() async {
    if (_isDataLoaded) return;

    try {
      // Load job_data.json
      final String jobDataJson = await rootBundle.loadString('job_data.json');
      final jobData = json.decode(jobDataJson);
      
      // Extract companies from job_data.json
      final Map<String, dynamic> companies = jobData['company'] as Map<String, dynamic>;
      
      final Set<String> uniqueCompanies = {};
      for (var entry in companies.entries) {
        if (entry.value != null && entry.value.toString().isNotEmpty) {
          uniqueCompanies.add(entry.value.toString());
        }
      }
      
      // Convert to list of company objects
      _companies = uniqueCompanies.map((name) => {
        'name': name,
        'id': _generateCompanyId(name),
      }).toList();
      
      // Load jobstreet_all_jobs.json
      final String jobStreetJson = await rootBundle.loadString('jobstreet_all_jobs.json');
      _jobs = List<Map<String, dynamic>>.from(json.decode(jobStreetJson));
      
      _isDataLoaded = true;
    } catch (e) {
      print('Error loading company data: $e');
      throw Exception('Failed to load company data');
    }
  }
  
  // Generate company ID from name
  String _generateCompanyId(String companyName) {
    return companyName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
  }
  
  // Get all companies
  Future<List<Map<String, dynamic>>> getCompanies() async {
    await loadCompanyData();
    return _companies;
  }
  
  // Search companies
  Future<List<Map<String, dynamic>>> searchCompanies(String query) async {
    await loadCompanyData();
    query = query.toLowerCase();
    
    return _companies.where((company) => 
      company['name'].toString().toLowerCase().contains(query)
    ).toList();
  }
  
  // Get jobs by company name
  Future<List<Map<String, dynamic>>> getJobsByCompany(String companyName) async {
    await loadCompanyData();
    return _jobs.where((job) => 
      job['company'] != null && 
      job['company'].toString().toLowerCase() == companyName.toLowerCase()
    ).toList();
  }
  
  // Search jobs
  Future<List<Map<String, dynamic>>> searchJobs(String query) async {
    await loadCompanyData();
    query = query.toLowerCase();
    
    return _jobs.where((job) => 
      (job['title'] != null && job['title'].toString().toLowerCase().contains(query)) ||
      (job['company'] != null && job['company'].toString().toLowerCase().contains(query))
    ).toList();
  }
  
  // REVIEWS METHODS
  
  // Add a company review
  Future<void> addCompanyReview(CompanyReview review) async {
    try {
      // Create review data with robust error handling for new fields
      final reviewData = review.toMap();
      
      // Add the review first, with better error handling
      await _firestore.collection('company_reviews').add(reviewData)
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw Exception('Network timeout. Please check your connection.')
        );
      
      // Update company stats in the background without awaiting
      _updateCompanyStats(review.companyId, review.companyName).catchError((error) {
        print('Error updating company stats: $error');
        // Errors here don't affect the main review submission
      });
    } on FirebaseException catch (e) {
      print('Firebase error adding company review: $e');
      throw Exception('Connection error: ${e.message ?? "Could not connect to our servers"}');
    } catch (e) {
      print('Error adding company review: $e');
      throw Exception('Failed to add company review: ${e.toString()}');
    }
  }
  
  // Get reviews for a company
  Future<List<CompanyReview>> getCompanyReviews(String companyId) async {
    try {
      // First, check if the company exists in the companies collection
      final companyDoc = await _firestore
          .collection('companies')
          .doc(companyId)
          .get();
      
      if (!companyDoc.exists) {
        print('No company found with ID: $companyId');
        return []; // Return empty list if company doesn't exist
      }

      try {
        // Try with ordering first (requires index)
        final querySnapshot = await _firestore
            .collection('company_reviews')
            .where('companyId', isEqualTo: companyId)
            .orderBy('createdAt', descending: true)
            .limit(50) // Limit to prevent excessive data retrieval
            .get();
        
        // Map documents to CompanyReview objects
        final reviews = querySnapshot.docs
            .map((doc) => CompanyReview.fromMap(doc.id, doc.data()))
            .toList();
        
        print('Loaded ${reviews.length} reviews for company $companyId with ordering');
        return reviews;
      } catch (e) {
        if (e is FirebaseException && e.code == 'failed-precondition') {
          print('Index required, falling back to unordered query');
          
          // Fallback to unordered query if index doesn't exist
          final querySnapshot = await _firestore
              .collection('company_reviews')
              .where('companyId', isEqualTo: companyId)
              .limit(50)
              .get();
          
          final reviews = querySnapshot.docs
              .map((doc) => CompanyReview.fromMap(doc.id, doc.data()))
              .toList();
          
          // Sort manually
          reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          print('Loaded ${reviews.length} reviews for company $companyId without ordering');
          return reviews;
        } else {
          rethrow;
        }
      }
    } on FirebaseException catch (e) {
      print('Firestore error getting company reviews: ${e.code} - ${e.message}');
      
      // For Firestore errors, return an empty list
      return [];
    } catch (e) {
      print('Unexpected error getting company reviews: $e');
      return []; // Return empty list for any other unexpected errors
    }
  }
  
  // Get recent reviews (across all companies)
  Future<List<CompanyReview>> getRecentReviews({int limit = 10, int? page}) async {
    try {
      Query query = _firestore
          .collection('company_reviews')
          .orderBy('createdAt', descending: true);
          
      // Apply pagination if page is provided
      if (page != null && page > 1) {
        try {
          // Get the last document from the previous page
          final lastVisible = await _firestore
              .collection('company_reviews')
              .orderBy('createdAt', descending: true)
              .limit((page - 1) * limit)
              .get()
              .then((snapshot) {
                if (snapshot.docs.isEmpty) {
                  return null;
                }
                return snapshot.docs.last;
              });
              
          // Start after the last document if it exists
          if (lastVisible != null) {
            query = query.startAfterDocument(lastVisible);
          }
        } catch (e) {
          print('Error getting pagination reference: $e');
          // Continue without pagination
        }
      }
      
      // Apply limit
      query = query.limit(limit);
      
      final querySnapshot = await query.get();
      
      return querySnapshot.docs
          .map((doc) => CompanyReview.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } on FirebaseException catch (e) {
      print('Firestore error getting recent reviews: $e');
      // Add a small delay before returning empty to prevent rapid retries
      await Future.delayed(const Duration(seconds: 1));
      return [];
    } catch (e) {
      print('Error getting recent reviews: $e');
      return []; // Return empty list instead of throwing
    }
  }
  
  // Update company stats based on reviews
  Future<void> _updateCompanyStats(String companyId, String companyName) async {
    try {
      // Get all reviews for this company
      final reviewsSnapshot = await _firestore
          .collection('company_reviews')
          .where('companyId', isEqualTo: companyId)
          .get()
          .timeout(const Duration(seconds: 5)); // Add timeout to prevent hanging
      
      final reviews = reviewsSnapshot.docs
          .map((doc) => CompanyReview.fromMap(doc.id, doc.data()))
          .toList();
          
      // Calculate average rating
      double averageRating = 0;
      int reviewCount = reviews.length;
      if (reviews.isNotEmpty) {
        double total = reviews.fold(0, (sum, review) => sum + review.rating);
        averageRating = total / reviewCount;
      }
      
      print('Updating company stats for $companyName: $reviewCount reviews, avg rating: $averageRating');
      
      // Aggregate tags
      Map<String, int> tagCounts = {};
      for (var review in reviews) {
        for (var tag in review.tags) {
          tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
        }
      }
      
      // Aggregate salary ranges by job title
      Map<String, List<String>> salaryRanges = {};
      for (var review in reviews) {
        if (!salaryRanges.containsKey(review.jobTitle)) {
          salaryRanges[review.jobTitle] = [];
        }
        if (review.salary.isNotEmpty) {
          salaryRanges[review.jobTitle]!.add(review.salary);
        }
      }
      
      // Always create or update company document
      await _firestore.collection('companies').doc(companyId).set({
        'name': companyName,
        'averageRating': averageRating,
        'reviewCount': reviewCount,
        'tagCounts': tagCounts,
        'salaryRanges': salaryRanges,
        'lastUpdated': Timestamp.now(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating company stats: $e');
      
      // Fallback: Create a minimal company document if stats update fails
      try {
        await _firestore.collection('companies').doc(companyId).set({
          'name': companyName,
          'averageRating': 0,
          'reviewCount': 0,
          'tagCounts': {},
          'salaryRanges': {},
          'lastUpdated': Timestamp.now(),
        }, SetOptions(merge: true));
      } catch (fallbackError) {
        print('Fallback company document creation failed: $fallbackError');
      }
    }
  }
  
  // QUESTIONS METHODS
  
  // Add a company question
  Future<void> addCompanyQuestion(CompanyQuestion question) async {
    try {
      await _firestore.collection('company_questions').add(question.toMap());
    } catch (e) {
      print('Error adding company question: $e');
      throw Exception('Failed to add company question');
    }
  }
  
  // Get questions for a company
  Future<List<CompanyQuestion>> getCompanyQuestions(String companyId) async {
    try {
      // Check if company exists first
      final companyDoc = await _firestore
          .collection('companies')
          .doc(companyId)
          .get();
      
      if (!companyDoc.exists) {
        print('No company found with ID: $companyId for questions');
        return []; // Return empty list if company doesn't exist
      }
      
      try {
        // Try with ordering first (requires index)
        final querySnapshot = await _firestore
            .collection('company_questions')
            .where('companyId', isEqualTo: companyId)
            .orderBy('createdAt', descending: true)
            .limit(50) // Limit to prevent excessive data retrieval
            .get();
        
        final questions = querySnapshot.docs
            .map((doc) => CompanyQuestion.fromMap(doc.id, doc.data()))
            .toList();
            
        print('Loaded ${questions.length} questions for company $companyId with ordering');
        return questions;
      } catch (e) {
        if (e is FirebaseException && e.code == 'failed-precondition') {
          print('Index required for questions, falling back to unordered query');
          
          // Fallback to unordered query if index doesn't exist
          final querySnapshot = await _firestore
              .collection('company_questions')
              .where('companyId', isEqualTo: companyId)
              .limit(50)
              .get();
          
          final questions = querySnapshot.docs
              .map((doc) => CompanyQuestion.fromMap(doc.id, doc.data()))
              .toList();
          
          // Sort manually
          questions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          print('Loaded ${questions.length} questions for company $companyId without ordering');
          return questions;
        } else {
          rethrow;
        }
      }
    } on FirebaseException catch (e) {
      print('Firestore error getting company questions: ${e.code} - ${e.message}');
      
      // For Firestore errors, return an empty list
      return [];
    } catch (e) {
      print('Unexpected error getting company questions: $e');
      return []; // Return empty list instead of throwing
    }
  }
  
  // Add answer to a question
  Future<void> addAnswerToQuestion(String questionId, CompanyAnswer answer) async {
    try {
      // Get the current question
      final docRef = _firestore.collection('company_questions').doc(questionId);
      final docSnapshot = await docRef.get();
      
      if (!docSnapshot.exists) {
        throw Exception('Question not found');
      }
      
      // Add the answer
      await docRef.update({
        'answers': FieldValue.arrayUnion([answer.toMap()]),
      });
    } catch (e) {
      print('Error adding answer to question: $e');
      throw Exception('Failed to add answer');
    }
  }
  
  // Get trending companies (most reviewed in the last 7 days)
  Future<List<Map<String, dynamic>>> getTrendingCompanies({int limit = 5}) async {
    try {
      final DateTime sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      
      // Get reviews from the past week
      final recentReviewsSnapshot = await _firestore
          .collection('company_reviews')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
          .get();
      
      // Count reviews per company
      Map<String, Map<String, dynamic>> companyReviewCounts = {};
      for (var doc in recentReviewsSnapshot.docs) {
        final data = doc.data();
        final companyId = data['companyId'];
        final companyName = data['companyName'];
        
        if (!companyReviewCounts.containsKey(companyId)) {
          companyReviewCounts[companyId] = {
            'id': companyId,
            'name': companyName,
            'count': 0
          };
        }
        
        companyReviewCounts[companyId]!['count'] = companyReviewCounts[companyId]!['count'] + 1;
      }
      
      // Sort by count and return top companies
      final trendingCompanies = companyReviewCounts.values.toList()
        ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
      
      return trendingCompanies.take(limit).toList();
    } catch (e) {
      print('Error getting trending companies: $e');
      return [];
    }
  }

  // Delete a company review
  Future<void> deleteCompanyReview(String reviewId) async {
    try {
      // Get the review document first to confirm it exists
      DocumentSnapshot reviewDoc = await _firestore
          .collection('company_reviews')
          .doc(reviewId)
          .get();
          
      if (!reviewDoc.exists) {
        throw Exception('Review not found');
      }
      
      // Delete the review
      await _firestore.collection('company_reviews').doc(reviewId).delete();
      
      // Update company stats
      Map<String, dynamic> data = reviewDoc.data() as Map<String, dynamic>;
      await _updateCompanyStats(data['companyId'], data['companyName']);
      
    } catch (e) {
      print('Error deleting company review: $e');
      throw Exception('Failed to delete company review: ${e.toString()}');
    }
  }
} 
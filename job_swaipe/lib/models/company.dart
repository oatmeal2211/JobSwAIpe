import 'package:cloud_firestore/cloud_firestore.dart';

class Company {
  final String id;
  final String name;
  final double averageRating;
  final int reviewCount;
  final Map<String, List<String>> salaryRanges; // e.g., {"Software Engineer": ["5000-7000", "7000-10000"]}
  final Map<String, int> tagCounts; // e.g., {"toxic": 5, "fun": 10, "work-life balance": 8}

  Company({
    required this.id,
    required this.name,
    required this.averageRating,
    required this.reviewCount,
    required this.salaryRanges,
    required this.tagCounts,
  });

  factory Company.fromMap(String id, Map<String, dynamic> data) {
    // Handle potential null or invalid data
    Map<String, List<String>> salaryRanges = {};
    try {
      if (data['salaryRanges'] != null) {
        final rawRanges = data['salaryRanges'] as Map<String, dynamic>;
        rawRanges.forEach((key, value) {
          if (value is List) {
            salaryRanges[key] = List<String>.from(value);
          } else {
            salaryRanges[key] = [];
          }
        });
      }
    } catch (e) {
      print('Error parsing salary ranges: $e');
    }

    Map<String, int> tagCounts = {};
    try {
      if (data['tagCounts'] != null) {
        final rawCounts = data['tagCounts'] as Map<String, dynamic>;
        rawCounts.forEach((key, value) {
          if (value is int) {
            tagCounts[key] = value;
          } else if (value is num) {
            tagCounts[key] = value.toInt();
          }
        });
      }
    } catch (e) {
      print('Error parsing tag counts: $e');
    }

    return Company(
      id: id,
      name: data['name'] ?? '',
      averageRating: _parseRating(data['averageRating']),
      reviewCount: _parseCount(data['reviewCount']),
      salaryRanges: salaryRanges,
      tagCounts: tagCounts,
    );
  }

  // Helper method to safely parse rating
  static double _parseRating(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (_) {
        return 0.0;
      }
    }
    return 0.0;
  }

  // Helper method to safely parse count
  static int _parseCount(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (_) {
        return 0;
      }
    }
    return 0;
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'averageRating': averageRating,
      'reviewCount': reviewCount,
      'salaryRanges': salaryRanges,
      'tagCounts': tagCounts,
    };
  }
} 
import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyReview {
  final String id;
  final String companyId;
  final String companyName;
  final String jobTitle;
  final double rating; // Overall rating (1-5)
  final String reviewText;
  final String pros;
  final String cons;
  final bool wouldRecommend;
  final bool? ceoApproval;
  final String salary;
  final List<String> tags; // e.g., "toxic", "fun", "work-life balance"
  final Map<String, int> emojiRatings; // e.g., {"culture": 4, "benefits": 3, "management": 2}
  final DateTime createdAt;
  final bool isAnonymous;
  final String? userId; // Nullable if anonymous
  final String? userDisplayName; // Nullable if anonymous
  final String? deviceId; // Add device ID for anonymous reviews

  CompanyReview({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.jobTitle,
    required this.rating,
    required this.reviewText,
    required this.pros,
    required this.cons,
    required this.wouldRecommend,
    this.ceoApproval,
    required this.salary,
    required this.tags,
    required this.emojiRatings,
    required this.createdAt,
    required this.isAnonymous,
    this.userId,
    this.userDisplayName,
    this.deviceId, // Add device ID parameter
  });

  factory CompanyReview.fromMap(String id, Map<String, dynamic> data) {
    return CompanyReview(
      id: id,
      companyId: data['companyId'] ?? '',
      companyName: data['companyName'] ?? '',
      jobTitle: data['jobTitle'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewText: data['reviewText'] ?? '',
      pros: data['pros'] ?? '',
      cons: data['cons'] ?? '',
      wouldRecommend: data['wouldRecommend'] ?? false,
      ceoApproval: data['ceoApproval'],
      salary: data['salary'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      emojiRatings: Map<String, int>.from(data['emojiRatings'] ?? {}),
      createdAt: data['createdAt'] != null ? 
          (data['createdAt'] as Timestamp).toDate() : 
          DateTime.now(),
      isAnonymous: data['isAnonymous'] ?? false,
      userId: data['userId'],
      userDisplayName: data['userDisplayName'],
      deviceId: data['deviceId'], // Preserve device ID
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
      'companyName': companyName,
      'jobTitle': jobTitle,
      'rating': rating,
      'reviewText': reviewText,
      'pros': pros,
      'cons': cons,
      'wouldRecommend': wouldRecommend,
      'ceoApproval': ceoApproval,
      'salary': salary,
      'tags': tags,
      'emojiRatings': emojiRatings,
      'createdAt': Timestamp.fromDate(createdAt),
      'isAnonymous': isAnonymous,
      'userId': isAnonymous ? null : userId,
      'userDisplayName': isAnonymous ? null : userDisplayName,
      'deviceId': deviceId, // Include device ID regardless of anonymity
    };
  }
}

class CompanyQuestion {
  final String id;
  final String companyId;
  final String companyName;
  final String question;
  final List<CompanyAnswer> answers;
  final DateTime createdAt;
  final String userId;
  final String userDisplayName;
  int answerCount; // Added answerCount field

  CompanyQuestion({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.question,
    required this.answers,
    required this.createdAt,
    required this.userId,
    required this.userDisplayName,
    this.answerCount = 0, // Default to 0
  });

  factory CompanyQuestion.fromMap(String id, Map<String, dynamic> data) {
    List<CompanyAnswer> answers = [];
    if (data['answers'] != null) {
      answers = List<Map<String, dynamic>>.from(data['answers']).map(
        (answer) => CompanyAnswer.fromMap(answer),
      ).toList();
    }

    return CompanyQuestion(
      id: id,
      companyId: data['companyId'] ?? '',
      companyName: data['companyName'] ?? '',
      question: data['question'] ?? '',
      answers: answers,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      userId: data['userId'] ?? '',
      userDisplayName: data['userDisplayName'] ?? '',
      answerCount: data['answerCount'] ?? 0, // Parse answerCount from data
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
      'companyName': companyName,
      'question': question,
      'answers': answers.map((answer) => answer.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'userId': userId,
      'userDisplayName': userDisplayName,
      'answerCount': answerCount, // Include answerCount in map
    };
  }
}

class CompanyAnswer {
  final String id;
  final String questionId; // Added questionId field
  final String answer;
  final DateTime createdAt;
  final String? userId; // Made nullable for anonymous answers
  final String userDisplayName;
  final bool isAnonymous;
  final int upvotes; // Added upvotes field
  final int downvotes; // Added downvotes field

  CompanyAnswer({
    required this.id,
    required this.questionId, // Added to constructor
    required this.answer,
    required this.createdAt,
    this.userId, // Made nullable
    required this.userDisplayName,
    required this.isAnonymous,
    this.upvotes = 0, // Default to 0
    this.downvotes = 0, // Default to 0
  });

  factory CompanyAnswer.fromMap(Map<String, dynamic> data) {
    return CompanyAnswer(
      id: data['id'] ?? '',
      questionId: data['questionId'] ?? '', // Parse questionId
      answer: data['answer'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      userId: data['userId'], // Keep nullable
      userDisplayName: data['userDisplayName'] ?? '',
      isAnonymous: data['isAnonymous'] ?? false,
      upvotes: data['upvotes'] ?? 0, // Parse upvotes
      downvotes: data['downvotes'] ?? 0, // Parse downvotes
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'questionId': questionId, // Include questionId in map
      'answer': answer,
      'createdAt': Timestamp.fromDate(createdAt),
      'userId': userId,
      'userDisplayName': userDisplayName,
      'isAnonymous': isAnonymous,
      'upvotes': upvotes, // Include upvotes
      'downvotes': downvotes, // Include downvotes
    };
  }
  
  // Add copyWith method for creating a new instance with modified fields
  CompanyAnswer copyWith({
    String? id,
    String? questionId,
    String? answer,
    DateTime? createdAt,
    String? userId,
    String? userDisplayName,
    bool? isAnonymous,
    int? upvotes,
    int? downvotes,
  }) {
    return CompanyAnswer(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      answer: answer ?? this.answer,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      userDisplayName: userDisplayName ?? this.userDisplayName,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
    );
  }
} 
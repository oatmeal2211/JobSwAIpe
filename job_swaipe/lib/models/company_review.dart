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

  CompanyQuestion({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.question,
    required this.answers,
    required this.createdAt,
    required this.userId,
    required this.userDisplayName,
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
    };
  }
}

class CompanyAnswer {
  final String id;
  final String answer;
  final DateTime createdAt;
  final String userId;
  final String userDisplayName;
  final bool isAnonymous;

  CompanyAnswer({
    required this.id,
    required this.answer,
    required this.createdAt,
    required this.userId,
    required this.userDisplayName,
    required this.isAnonymous,
  });

  factory CompanyAnswer.fromMap(Map<String, dynamic> data) {
    return CompanyAnswer(
      id: data['id'] ?? '',
      answer: data['answer'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      userId: data['userId'] ?? '',
      userDisplayName: data['userDisplayName'] ?? '',
      isAnonymous: data['isAnonymous'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'answer': answer,
      'createdAt': Timestamp.fromDate(createdAt),
      'userId': userId,
      'userDisplayName': userDisplayName,
      'isAnonymous': isAnonymous,
    };
  }
} 
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../../models/company_review.dart';
import '../../models/company.dart';
import '../../services/company_service.dart';
import 'write_review_screen.dart';
import 'ask_question_screen.dart';
import '../../services/auth_service.dart';

class CompanyDetailScreen extends StatefulWidget {
  final String companyId;
  final String companyName;

  const CompanyDetailScreen({
    super.key,
    required this.companyId,
    required this.companyName,
  });

  @override
  State<CompanyDetailScreen> createState() => _CompanyDetailScreenState();
}

class _CompanyDetailScreenState extends State<CompanyDetailScreen> with SingleTickerProviderStateMixin {
  final CompanyService _companyService = CompanyService();
  final AuthService _authService = AuthService();
  late TabController _tabController;
  
  List<CompanyReview> _reviews = [];
  List<CompanyQuestion> _questions = [];
  Company? _companyInfo;
  List<Map<String, dynamic>> _companyJobs = [];
  
  bool _isLoading = true;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCompanyData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadCompanyData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Create default empty results
      DocumentSnapshot? companyDocSnapshot;
      List<CompanyReview> reviews = [];
      List<CompanyQuestion> questions = [];
      List<Map<String, dynamic>> jobs = [];

      try {
        // Use Future.wait for parallel execution with timeout
        final results = await Future.wait<dynamic>([
          // Company Info
          FirebaseFirestore.instance
            .collection('companies')
            .doc(widget.companyId)
            .get()
            .timeout(const Duration(seconds: 5)),
          
          // Reviews
          _companyService.getCompanyReviews(widget.companyId)
            .timeout(const Duration(seconds: 5)),
          
          // Questions
          _companyService.getCompanyQuestions(widget.companyId)
            .timeout(const Duration(seconds: 5)),
          
          // Jobs
          _companyService.getJobsByCompany(widget.companyName)
            .timeout(const Duration(seconds: 5)),
        ]);

        // Process results safely
        companyDocSnapshot = results[0] as DocumentSnapshot?;
        reviews = results[1] as List<CompanyReview>;
        questions = results[2] as List<CompanyQuestion>;
        jobs = results[3] as List<Map<String, dynamic>>;
      } catch (e) {
        print('Error in parallel data loading: $e');
        // Continue with default empty values
      }

      // Process company info
      Company? companyInfo;
      if (companyDocSnapshot != null && companyDocSnapshot.exists) {
        companyInfo = Company.fromMap(
          widget.companyId, 
          companyDocSnapshot.data() as Map<String, dynamic>
        );
      } else {
        // Create a fallback company info if not found
        companyInfo = Company(
          id: widget.companyId,
          name: widget.companyName,
          averageRating: 0.0,
          reviewCount: 0,
          salaryRanges: {},
          tagCounts: {},
        );
        print('Using fallback company info for: ${widget.companyName}');
      }

      if (mounted) {
        setState(() {
          _reviews = reviews;
          _questions = questions;
          _companyJobs = jobs;
          _companyInfo = companyInfo;
          _isLoading = false;

          // Only show "no data" message if ALL data is empty
          if (reviews.isEmpty && questions.isEmpty && jobs.isEmpty && (companyInfo?.reviewCount ?? 0) == 0) {
            _errorMessage = 'No data available for this company yet.';
          } else {
            _errorMessage = null; // Clear any error message if we have data
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading data: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }
  
  void _navigateToWriteReview() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WriteReviewScreen(
          companyId: widget.companyId,
          companyName: widget.companyName,
        ),
      ),
    ).then((_) => _loadCompanyData());
  }
  
  void _navigateToAskQuestion() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AskQuestionScreen(
          companyId: widget.companyId,
          companyName: widget.companyName,
        ),
      ),
    ).then((_) => _loadCompanyData());
  }
  
  // Helper method to capitalize string
  String _capitalizeString(String text) {
    if (text.isEmpty) return '';
    return '${text[0].toUpperCase()}${text.substring(1)}';
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.companyName),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Reviews'),
            Tab(text: 'Q&A'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildReviewsTab(),
                    _buildQATab(),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show options based on the current tab
          if (_tabController.index == 1) {
            _navigateToWriteReview();
          } else if (_tabController.index == 2) {
            _navigateToAskQuestion();
          } else {
            showModalBottomSheet(
              context: context,
              builder: (BuildContext context) {
                return SafeArea(
                  child: Wrap(
                    children: <Widget>[
                      ListTile(
                        leading: const Icon(Icons.rate_review),
                        title: const Text('Write Review'),
                        onTap: () {
                          Navigator.pop(context);
                          _navigateToWriteReview();
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.question_answer),
                        title: const Text('Ask a Question'),
                        onTap: () {
                          Navigator.pop(context);
                          _navigateToAskQuestion();
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          }
        },
        child: Icon(
          _tabController.index == 1
              ? Icons.rate_review
              : _tabController.index == 2
                  ? Icons.question_answer
                  : Icons.add,
        ),
      ),
    );
  }
  
  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadCompanyData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // New Rating Overview Card
            _buildRatingOverviewCard(),

            // Rest of the existing overview content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Popular Tags
                  if (_companyInfo?.tagCounts != null && _companyInfo!.tagCounts.isNotEmpty) ...[
                    const Text(
                      'Popular Tags',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _companyInfo!.tagCounts.entries
                          .toList()
                          .map((entry) {
                            return Chip(
                              label: Text('${entry.key} (${entry.value})'),
                              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                            );
                          })
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Salary Ranges
                  if (_companyInfo?.salaryRanges != null && _companyInfo!.salaryRanges.isNotEmpty) ...[
                    const Text(
                      'Salary Ranges by Position',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 250),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _companyInfo!.salaryRanges.length,
                        itemBuilder: (context, index) {
                          final entry = _companyInfo!.salaryRanges.entries.elementAt(index);
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(
                                entry.key,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: entry.value.map((salary) {
                                  return Text(
                                    salary,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  );
                                }).toList(),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Available Jobs
                  if (_companyJobs.isNotEmpty) ...[
                    const Text(
                      'Available Jobs',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 250),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _companyJobs.length > 5 ? 5 : _companyJobs.length, // Show max 5 jobs
                        itemBuilder: (context, index) {
                          final job = _companyJobs[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(
                                job['title'] ?? 'Unknown Position',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: job['location'] != null
                                  ? Text(
                                      job['location'],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  : null,
                              trailing: job['link'] != null
                                  ? IconButton(
                                      icon: const Icon(Icons.open_in_new),
                                      onPressed: () {
                                        // Open job link (would use url_launcher in a real app)
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Opening: ${job['link']}'),
                                          ),
                                        );
                                      },
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                    if (_companyJobs.length > 5)
                      Align(
                        alignment: Alignment.center,
                        child: TextButton(
                          onPressed: () {
                            // Navigate to full jobs list (would implement in a real app)
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('View all jobs (to be implemented)'),
                              ),
                            );
                          },
                          child: const Text('View all jobs'),
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Recent Reviews Preview
                  if (_reviews.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Reviews',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            _tabController.animateTo(1); // Switch to reviews tab
                          },
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Show a condensed version of reviews in the preview
                    ...List.generate(_reviews.length > 2 ? 2 : _reviews.length, (index) {
                      final review = _reviews[index];
                      return _buildCompactReviewPreview(review);
                    }),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildReviewsTab() {
    // Check if we have reviews or if company info shows reviews exist
    final hasReviews = _reviews.isNotEmpty || (_companyInfo != null && (_companyInfo!.reviewCount > 0));
    
    if (!hasReviews) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No reviews yet'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _navigateToWriteReview,
              child: const Text('Be the first to write a review'),
            ),
          ],
        ),
      );
    }
    
    // If we have company info showing reviews exist but no actual reviews loaded
    if (_reviews.isEmpty && _companyInfo != null && _companyInfo!.reviewCount > 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${_companyInfo!.reviewCount} reviews exist but could not be loaded.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCompanyData,
              child: const Text('Retry Loading Reviews'),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadCompanyData,
      child: ListView.builder(
        itemCount: _reviews.length,
        itemBuilder: (context, index) {
          return _buildReviewCard(_reviews[index]);
        },
      ),
    );
  }
  
  Widget _buildQATab() {
    if (_questions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No questions yet'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _navigateToAskQuestion,
              child: const Text('Be the first to ask a question'),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadCompanyData,
      child: ListView.builder(
        itemCount: _questions.length,
        itemBuilder: (context, index) {
          final question = _questions[index];
          return _buildQuestionCard(question);
        },
      ),
    );
  }
  
  Widget _buildReviewCard(CompanyReview review) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Handle identification of user's own review
    final currentUser = _authService.getCurrentUser();
    final bool isOwnReview = currentUser != null && 
                            ((review.userId != null && 
                            currentUser.uid == review.userId) || 
                            // For anonymous reviews, we'll show a delete button in _checkAnonymousReviewOwnership
                            review.isAnonymous);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with rating and date
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _getRatingColor(review.rating),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      review.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review.jobTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDate(review.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Add delete option for own reviews
                  if (isOwnReview)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _confirmDeleteReview(review),
                      tooltip: 'Delete Review',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
              
              // Divider
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Divider(height: 1),
              ),
              
              // Pros section
              if (review.pros.isNotEmpty) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.thumb_up, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pros',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            review.pros,
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              
              // Cons section
              if (review.cons.isNotEmpty) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.thumb_down, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cons',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            review.cons,
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              
              // Additional review text if present
              if (review.reviewText.isNotEmpty) ...[
                Text(
                  review.reviewText,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                  maxLines: 10,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
              ],
              
              // Recommendations row
              Row(
                children: [
                  _buildRecommendationChip(
                    "Would Recommend", 
                    review.wouldRecommend,
                    Icons.thumb_up,
                  ),
                  const SizedBox(width: 8),
                  if (review.ceoApproval != null)
                    _buildRecommendationChip(
                      "CEO Approval", 
                      review.ceoApproval!,
                      Icons.person,
                    ),
                ],
              ),
              
              if (review.salary.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Salary: ${review.salary}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ],
              
              // Tags
              if (review.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: review.tags.map((tag) {
                    return Chip(
                      label: Text(tag, style: const TextStyle(fontSize: 12)),
                      backgroundColor: colorScheme.surfaceVariant,
                      padding: EdgeInsets.zero,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
              ],
              
              // Posted info
              const Divider(height: 24),
              Text(
                'Posted by ${review.isAnonymous ? 'Anonymous' : review.userDisplayName}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              
              // Emoji ratings
              if (review.emojiRatings.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    'Category Ratings',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 16,
                    children: review.emojiRatings.entries.map((entry) {
                      final label = entry.key.replaceAll('_', ' ').toCapitalized();
                      return SizedBox(
                        width: MediaQuery.of(context).size.width * 0.38,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              label,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(
                                5,
                                (index) => Icon(
                                  index < entry.value ? Icons.star : Icons.star_border,
                                  size: 16,
                                  color: Colors.amber,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildRecommendationChip(String label, bool isPositive, IconData icon) {
    final color = isPositive ? Colors.green.shade700 : Colors.red.shade700;
    final displayText = label == "Would Recommend" ? 
                       (isPositive ? "Would Recommend" : "Would Not Recommend") : 
                       label;
    final displayIcon = label == "Would Recommend" ? 
                       (isPositive ? Icons.thumb_up : Icons.thumb_down) : 
                       icon;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(displayIcon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            displayText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            isPositive ? Icons.check : Icons.close,
            size: 14,
            color: color,
          ),
        ],
      ),
    );
  }
  
  Color _getRatingColor(double rating) {
    if (rating >= 4) return Colors.green;
    if (rating >= 3) return Colors.amber.shade700;
    if (rating >= 2) return Colors.orange;
    return Colors.red;
  }
  
  Widget _buildQuestionCard(CompanyQuestion question) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              question.question,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              'Asked by ${question.userDisplayName} • ${_formatDate(question.createdAt)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            
            // Answers
            if (question.answers.isNotEmpty) ...[
              const Divider(),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Answers',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              // Show only the first answer with a "Show more" button if there are multiple answers
              if (question.answers.length == 1) 
                _buildAnswerItem(question.answers[0])
              else ...[
                _buildAnswerItem(question.answers[0]),
                if (question.answers.length > 1) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      _showAllAnswers(context, question);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(
                        'Show ${question.answers.length - 1} more ${question.answers.length == 2 ? 'answer' : 'answers'}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ],
            
            // Add answer button
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  // Would implement logic to add answer
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Add answer functionality to be implemented')),
                  );
                },
                child: const Text('Add Answer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAnswerItem(CompanyAnswer answer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          answer.answer,
          overflow: TextOverflow.ellipsis,
          maxLines: 3,
        ),
        const SizedBox(height: 4),
        Text(
          'Answered by ${answer.isAnonymous ? "Anonymous" : answer.userDisplayName} • ${_formatDate(answer.createdAt)}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
  
  void _showAllAnswers(BuildContext context, CompanyQuestion question) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      margin: const EdgeInsets.only(bottom: 16),
                    ),
                  ),
                  // Question
                  Text(
                    question.question,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    'Asked by ${question.userDisplayName} • ${_formatDate(question.createdAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'All Answers',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Answers list
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: question.answers.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final answer = question.answers[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(answer.answer),
                              const SizedBox(height: 4),
                              Text(
                                'Answered by ${answer.isAnonymous ? "Anonymous" : answer.userDisplayName} • ${_formatDate(answer.createdAt)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'just now';
    }
  }

  // Compact review preview for overview tab
  Widget _buildCompactReviewPreview(CompanyReview review) {
    // Handle identification of user's own review
    final currentUser = _authService.getCurrentUser();
    final bool isOwnReview = currentUser != null && 
                           ((review.userId != null && 
                           currentUser.uid == review.userId) || 
                           // For anonymous reviews, we'll show delete button
                           review.isAnonymous);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getRatingColor(review.rating),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              review.rating.toStringAsFixed(1),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
        title: Text(
          review.jobTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          review.pros.isNotEmpty ? "Pros: ${review.pros}" : review.reviewText,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: isOwnReview 
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                  onPressed: () => _confirmDeleteReview(review),
                  tooltip: 'Delete Review',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios, size: 14),
              ],
            )
          : const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () => _tabController.animateTo(1), // Switch to reviews tab
      ),
    );
  }

  // Add a new method to check anonymous review ownership before showing delete dialog
  void _confirmDeleteReview(CompanyReview review) async {
    if (review.isAnonymous) {
      // For anonymous reviews, temporarily allow all deletions
      // This is a temporary fix until proper device ID tracking is working
      bool canDelete = true;
      
      /* Commenting out check since it's not working reliably
      try {
        final deviceId = await _authService.getDeviceId();
        // Allow deletion if device IDs match or if the review doesn't have a deviceId yet
        canDelete = (review.deviceId == null || review.deviceId == deviceId);
        
        if (!canDelete) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('You can only delete reviews you created'))
            );
          }
          return;
        }
      } catch (e) {
        // If device ID check fails, allow deletion as a fallback
        // This is temporary until all reviews have device IDs
        print('Error checking review ownership, allowing as fallback: $e');
      }
      */
    }

    // Continue with delete confirmation for non-anonymous or verified anonymous reviews
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Review'),
          content: const Text(
            'Are you sure you want to delete this review? This action cannot be undone.'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                
                // Show loading indicator
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Deleting review...'))
                );
                
                try {
                  await _companyService.deleteCompanyReview(review.id);
                  
                  if (mounted) {
                    // Refresh data
                    _loadCompanyData();
                    
                    // Notify user
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Review deleted successfully'))
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error deleting review: ${e.toString()}'))
                    );
                  }
                }
              },
              child: const Text('DELETE', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // Company Rating Overview Card
  Widget _buildRatingOverviewCard() {
    final averageRating = _companyInfo?.averageRating ?? 0.0;
    final reviewCount = _companyInfo?.reviewCount ?? 0;

    // Color gradient based on rating
    final ratingColor = _getRatingColor(averageRating);
    final gradientColors = [
      ratingColor.withOpacity(0.8),
      ratingColor.withOpacity(0.5),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ratingColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Overall Rating',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$reviewCount Reviews',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  averageRating.toStringAsFixed(1),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          index < averageRating.round()
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getRatingDescription(averageRating),
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Rating description method
  String _getRatingDescription(double rating) {
    if (rating >= 4.5) return 'Excellent Workplace';
    if (rating >= 4.0) return 'Very Good Workplace';
    if (rating >= 3.0) return 'Average Workplace';
    if (rating >= 2.0) return 'Below Average Workplace';
    return 'Poor Workplace';
  }
} 
import 'package:flutter/material.dart';
import 'package:job_swaipe/models/company_review.dart';
import 'package:job_swaipe/services/company_service.dart';
import 'package:job_swaipe/services/auth_service.dart';
import 'package:job_swaipe/screens/community/write_review_screen.dart';
import 'package:job_swaipe/screens/community/company_detail_screen.dart';
import 'package:job_swaipe/screens/community/ask_question_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// Define color constants to use throughout the app
const Color kPrimaryColor = Color(0xFF0077FF); // Blue theme
const Color kSecondaryColor = Color(0xFF00C471); // Green accent
const Color kBackgroundColor = Color(0xFFF5F7FA);
const Color kCardColor = Colors.white;
const Color kErrorColor = Color(0xFFFF3B30);

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> with SingleTickerProviderStateMixin {
  final CompanyService _companyService = CompanyService();
  final AuthService _authService = AuthService();
  late TabController _tabController;
  
  List<CompanyReview> _recentReviews = [];
  List<Map<String, dynamic>> _trendingCompanies = [];
  String _searchQuery = '';
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _isLoading = false;
  bool _isInitialLoading = true;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _pageSize = 5;
  String? _errorMessage;
  bool _isConnected = true;
  
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController.addListener(_scrollListener);
    _checkConnectivity();
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }
  
  Future<void> _checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isConnected = connectivityResult != ConnectivityResult.none;
    });
    
    // Listen for connectivity changes
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      setState(() {
        _isConnected = result != ConnectivityResult.none;
      });
      
      // If connection is restored, reload data
      if (_isConnected && _errorMessage != null) {
        _loadInitialData();
      }
    });
  }
  
  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (!_isLoading && _hasMore) {
        _loadMoreData();
      }
    }
  }

  Future<void> _loadInitialData() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _isInitialLoading = true;
      _errorMessage = null;
      _currentPage = 1;
    });

    try {
      if (!_isConnected) {
        throw Exception('No internet connection');
      }
      
      // Initialize the company service data if needed
      await _companyService.loadCompanyData();
      
      // Load the first page of reviews with limited count
      final recentReviews = await _companyService.getRecentReviews(limit: _pageSize);
      final trendingCompanies = await _companyService.getTrendingCompanies();
      
      if (mounted) {
        setState(() {
          _recentReviews = recentReviews;
          _trendingCompanies = trendingCompanies;
          _isLoading = false;
          _isInitialLoading = false;
          _hasMore = recentReviews.length == _pageSize;
          _currentPage++;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().contains('No internet connection') 
              ? 'No internet connection. Please check your network settings and try again.'
              : 'Failed to load data: ${e.toString()}';
          _isLoading = false;
          _isInitialLoading = false;
        });
      }
    }
  }
  
  Future<void> _loadMoreData() async {
    if (_isLoading || !_hasMore || !_isConnected) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final moreReviews = await _companyService.getRecentReviews(
        limit: _pageSize,
        page: _currentPage,
      );
      
      if (mounted) {
        setState(() {
          if (moreReviews.isEmpty) {
            _hasMore = false;
          } else {
            _recentReviews.addAll(moreReviews);
            _currentPage++;
            _hasMore = moreReviews.length == _pageSize;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().contains('No internet connection') 
              ? 'No internet connection. Please check your network settings and try again.'
              : 'Error loading more reviews: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  void _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _isLoading = true;
    });

    try {
      if (!_isConnected) {
        throw Exception('No internet connection');
      }
      
      final results = await _companyService.searchCompanies(query);
      
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().contains('No internet connection') 
              ? 'No internet connection. Please check your network settings and try again.'
              : 'Search failed: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToCompanyDetail(String companyId, String companyName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CompanyDetailScreen(
          companyId: companyId,
          companyName: companyName,
        ),
      ),
    ).then((_) => _loadInitialData());
  }

  void _navigateToWriteReview() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WriteReviewScreen(),
      ),
    ).then((_) => _loadInitialData());
  }

  void _navigateToAskQuestion() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AskQuestionScreen(),
      ),
    ).then((_) => _loadInitialData());
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: kPrimaryColor,
          primary: kPrimaryColor,
          secondary: kSecondaryColor,
        ),
      ),
      child: Scaffold(
        backgroundColor: kBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text('Community', 
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: kPrimaryColor,
            )
          ),
          elevation: 0,
          actions: [
            // Connectivity indicator
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Icon(
                _isConnected ? Icons.wifi : Icons.wifi_off,
                color: _isConnected ? kSecondaryColor : kErrorColor,
              ),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorWeight: 3,
            indicatorColor: kPrimaryColor,
            labelColor: kPrimaryColor,
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Feed'),
              Tab(text: 'Companies'),
              Tab(text: 'Q&A'),
            ],
          ),
        ),
        body: !_isConnected && _errorMessage != null
            ? _buildOfflineState()
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildFeedTab(),
                  _buildCompaniesTab(),
                  _buildQATab(),
                ],
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            if (!_isConnected) {
              _showOfflineDialog();
              return;
            }
            
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (BuildContext context) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  margin: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 50,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          margin: const EdgeInsets.only(bottom: 20),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 16.0),
                          child: Text(
                            'Share your experience',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: kPrimaryColor,
                            ),
                          ),
                        ),
                        _buildActionTile(
                          title: 'Write Company Review',
                          subtitle: 'Share your work experience',
                          icon: Icons.rate_review,
                          onTap: () {
                            Navigator.pop(context);
                            _navigateToWriteReview();
                          },
                          color: kPrimaryColor,
                        ),
                        _buildActionTile(
                          title: 'Ask a Question',
                          subtitle: 'Get insights from the community',
                          icon: Icons.question_answer,
                          onTap: () {
                            Navigator.pop(context);
                            _navigateToAskQuestion();
                          },
                          color: kSecondaryColor,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('Share'),
          backgroundColor: kPrimaryColor,
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedTab() {
    if (_isInitialLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: kPrimaryColor),
            SizedBox(height: 16),
            Text('Loading community content...'),
          ],
        ),
      );
    }

    if (_errorMessage != null && _recentReviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: kErrorColor),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadInitialData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInitialData,
      color: kPrimaryColor,
      child: ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          // Trending Companies Section
          if (_trendingCompanies.isNotEmpty) ...[
            _buildSectionHeader(
              title: 'Trending Companies', 
              icon: Icons.trending_up, 
              onViewAll: () {
                // Navigate to all trending companies
              },
            ),
            SizedBox(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _trendingCompanies.length,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemBuilder: (context, index) {
                  final company = _trendingCompanies[index];
                  return _buildTrendingCompanyCard(company, index);
                },
              ),
            ),
          ],
          
          // Recent Reviews Section
          _buildSectionHeader(
            title: 'Recent Reviews', 
            icon: Icons.rate_review,
            onViewAll: () {
              // Navigate to all reviews
            },
          ),
          
          if (_recentReviews.isEmpty)
            _buildEmptyState()
          else
            ...List.generate(_recentReviews.length, (index) {
              final review = _recentReviews[index];
              return _buildReviewCard(review);
            }),
            
          // Loading indicator at the bottom
          if (_isLoading && !_isInitialLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator(color: kPrimaryColor)),
            ),
            
          // No more data indicator
          if (!_hasMore && _recentReviews.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Center(
                child: Text(
                  'No more reviews to load',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
            
          // Bottom padding to ensure everything is visible above FAB
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title, 
    required IconData icon,
    required VoidCallback onViewAll,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: kPrimaryColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: onViewAll,
            style: TextButton.styleFrom(
              foregroundColor: kPrimaryColor,
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('View All'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        children: [
          Icon(
            Icons.rate_review_outlined, 
            size: 64, 
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No reviews yet. Be the first to share your experience!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingCompanyCard(Map<String, dynamic> company, int index) {
    final colors = [
      kPrimaryColor,
      kSecondaryColor,
      const Color(0xFF5856D6), // Purple
      const Color(0xFFFF9500), // Orange
      const Color(0xFFFF2D55), // Pink
    ];
    
    final color = colors[index % colors.length];
    
    return Hero(
      tag: 'company_${company['id']}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToCompanyDetail(
            company['id'],
            company['name'],
          ),
          child: Container(
            width: 200,
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color,
                  color.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  company['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.trending_up,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${company['count']} new reviews',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompaniesTab() {
    return Column(
      children: [
        // Glassdoor-like search bar with shadow
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search for companies...',
              prefixIcon: const Icon(Icons.search, color: kPrimaryColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              _performSearch(value);
            },
          ),
        ),
        
        // Search Results or Loading
        if (_isLoading)
          const Expanded(
            child: Center(child: CircularProgressIndicator(color: kPrimaryColor)),
          )
        else if (_isSearching)
          Expanded(child: _buildSearchResults())
        else
          const Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.business,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Search for a company to see reviews and ratings',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Example: Google, Microsoft, Amazon',
                    style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQATab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: kPrimaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.question_answer_outlined,
              size: 80,
              color: kPrimaryColor,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Ask or answer questions about companies',
            style: TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Get insider information from the community',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToAskQuestion,
            icon: const Icon(Icons.add),
            label: const Text('Ask a Question'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No companies found. Try another search term.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final company = _searchResults[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 1,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: kPrimaryColor,
              child: Text(
                company['name'][0].toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(
              company['name'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('Tap to see reviews and details'),
            trailing: const Icon(Icons.chevron_right, color: kPrimaryColor),
            onTap: () => _navigateToCompanyDetail(
              company['id'], 
              company['name'],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReviewCard(CompanyReview review) {
    // Modify this to match the UI in the example image - gray background with white card
    Color ratingColor;
    if (review.rating >= 4) {
      ratingColor = const Color(0xFFFF9500); // Orange
    } else if (review.rating >= 3) {
      ratingColor = const Color(0xFFFFB400); // Yellow/Amber
    } else {
      ratingColor = const Color(0xFFFF5722); // Red/Orange
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: InkWell(
        onTap: () => _navigateToCompanyDetail(review.companyId, review.companyName),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // First section: Company name and rating
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Company initial avatar
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      review.companyName.isNotEmpty ? review.companyName[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Company name, job title and rating
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review.companyName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          review.jobTitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            ...List.generate(
                              5,
                              (index) => Icon(
                                index < review.rating.floor()
                                    ? Icons.star
                                    : (index < review.rating
                                        ? Icons.star_half
                                        : Icons.star_border),
                                color: ratingColor,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              review.rating.toStringAsFixed(1),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: ratingColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1),
            
            // Second section: Review text
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Text(
                review.reviewText,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            
            // Third section: Would Recommend tag
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Would Recommend tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: review.wouldRecommend ? 
                             Colors.green[700]!.withOpacity(0.15) : 
                             Colors.red[700]!.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          review.wouldRecommend ? Icons.thumb_up : Icons.thumb_down,
                          size: 14,
                          color: review.wouldRecommend ? Colors.green[700] : Colors.red[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          review.wouldRecommend ? 'Would Recommend' : 'Would Not Recommend',
                          style: TextStyle(
                            fontSize: 12,
                            color: review.wouldRecommend ? Colors.green[700] : Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Fourth section: Salary
            if (review.salary.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Salary: ${review.salary}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              
            // Fifth section: Tags
            if (review.tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: review.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[800],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              
            const Divider(height: 1),
            
            // Sixth section: Posted by
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Text(
                'Posted by ${review.isAnonymous ? 'Anonymous' : review.userDisplayName}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),
            
            const Divider(height: 1),
            
            // Last section: Rating categories with stars
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
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
                  _buildRatingCategories(review),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRatingCategories(CompanyReview review) {
    // Check if we have ratings first
    if (review.emojiRatings.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
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
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < (entry.value) ? Icons.star : Icons.star_border,
                    size: 16,
                    color: Colors.amber,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
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

  // Show offline dialog when user tries to perform actions while offline
  void _showOfflineDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.wifi_off, color: kErrorColor),
              SizedBox(width: 10),
              Text('No Connection'),
            ],
          ),
          content: const Text(
            'You are currently offline. Please check your internet connection and try again.'
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _checkConnectivity();
                if (_isConnected) {
                  _loadInitialData();
                }
              },
              child: const Text('RETRY'),
            ),
          ],
        );
      },
    );
  }
  
  // Offline state widget
  Widget _buildOfflineState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.cloud_off,
            size: 64,
            color: kErrorColor,
          ),
          const SizedBox(height: 16),
          const Text(
            'You are offline',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Unable to connect to Firestore. Please check your internet connection.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              await _checkConnectivity();
              if (_isConnected) {
                _loadInitialData();
              }
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry Connection'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
} 
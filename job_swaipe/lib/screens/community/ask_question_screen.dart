import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/company_review.dart';
import '../../services/company_service.dart';
import '../../services/auth_service.dart';

class AskQuestionScreen extends StatefulWidget {
  final String? companyId;
  final String? companyName;
  
  const AskQuestionScreen({
    super.key, 
    this.companyId,
    this.companyName,
  });

  @override
  State<AskQuestionScreen> createState() => _AskQuestionScreenState();
}

class _AskQuestionScreenState extends State<AskQuestionScreen> {
  final CompanyService _companyService = CompanyService();
  final AuthService _authService = AuthService();
  final Uuid _uuid = const Uuid();
  final _formKey = GlobalKey<FormState>();
  
  // Search related
  final _searchController = TextEditingController();
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];
  
  // Form fields
  String _selectedCompanyId = '';
  String _selectedCompanyName = '';
  final _questionController = TextEditingController();
  
  bool _isSubmitting = false;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    
    // If company information was passed to the screen
    if (widget.companyId != null && widget.companyName != null) {
      _selectedCompanyId = widget.companyId!;
      _selectedCompanyName = widget.companyName!;
    }
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _questionController.dispose();
    super.dispose();
  }
  
  // Search for companies
  void _searchCompany(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }
    
    setState(() {
      _isSearching = true;
    });
    
    try {
      final results = await _companyService.searchCompanies(query);
      
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Search failed: ${e.toString()}';
          _isSearching = false;
        });
      }
    }
  }
  
  // Select a company from search results
  void _selectCompany(String id, String name) {
    setState(() {
      _selectedCompanyId = id;
      _selectedCompanyName = name;
      _searchController.text = name;
      _isSearching = false;
      _searchResults = [];
    });
  }
  
  // Submit the question
  Future<void> _submitQuestion() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_selectedCompanyId.isEmpty || _selectedCompanyName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a company')),
      );
      return;
    }
    
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    
    try {
      final user = _authService.getCurrentUser();
      if (user == null) {
        throw Exception('You must be logged in to ask a question');
      }
      
      final question = CompanyQuestion(
        id: _uuid.v4(),
        companyId: _selectedCompanyId,
        companyName: _selectedCompanyName,
        question: _questionController.text.trim(),
        answers: [],
        createdAt: DateTime.now(),
        userId: user.uid,
        userDisplayName: user.email?.split('@').first ?? 'Unknown User',
      );
      
      await _companyService.addCompanyQuestion(question);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Question submitted successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to submit question: ${e.toString()}';
          _isSubmitting = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ask a Question'),
      ),
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Company selection
                    if (_selectedCompanyId.isEmpty) ...[
                      const Text(
                        'Search for a company',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Company name',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: _searchCompany,
                        validator: (value) {
                          if (_selectedCompanyId.isEmpty) {
                            return 'Please select a company';
                          }
                          return null;
                        },
                      ),
                      if (_isSearching)
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_searchResults.isNotEmpty)
                        SizedBox(
                          height: 200,
                          child: ListView.builder(
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final company = _searchResults[index];
                              return ListTile(
                                title: Text(company['name']),
                                onTap: () => _selectCompany(
                                  company['id'],
                                  company['name'],
                                ),
                              );
                            },
                          ),
                        ),
                    ] else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Company',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(_selectedCompanyName),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedCompanyId = '';
                                _selectedCompanyName = '';
                                _searchController.text = '';
                              });
                            },
                            child: const Text('Change'),
                          ),
                        ],
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    // Question Field
                    const Text(
                      'Your Question',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _questionController,
                      decoration: const InputDecoration(
                        hintText: 'e.g., What\'s the interview process like at this company?',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your question';
                        }
                        return null;
                      },
                    ),
                    
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 24),
                    
                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitQuestion,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Submit Question'),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Note about anonymous questions
                    const Center(
                      child: Text(
                        'Note: Your username will be visible with your question.',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 
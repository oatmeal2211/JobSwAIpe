import 'package:flutter/material.dart';
import 'dart:convert'; // For jsonDecode
import './resume_editor_page.dart'; // Import ResumeEditorPage

class JobMatchResultPage extends StatelessWidget {
  final String jsonResult; // Changed from markdownResult
  final String originalResumeJson; // Added to hold the original OCR resume data

  const JobMatchResultPage({
    super.key, 
    required this.jsonResult, 
    required this.originalResumeJson // Added to constructor
  }); // Updated constructor

  Widget _buildSectionTitle(BuildContext context, String title, {bool isConclusion = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isConclusion ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  Widget _buildOverallScore(BuildContext context, int? score) {
    if (score == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        children: [
          Text(
            'Overall Match Score', 
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 8),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 8,
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(score > 75 ? Colors.green : score > 50 ? Colors.orange : Colors.red),
                ),
              ),
              Text('$score%', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionAnalysisCard(BuildContext context, Map<String, dynamic> sectionData) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sectionData['section_name']?.toString() ?? 'Unnamed Section',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF4E342E)),
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 15),
                children: [
                  const TextSpan(text: 'Relevance: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: '${sectionData['relevance_score']?.toString() ?? 'N/A'}%'),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text('Justification:', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            Text(sectionData['justification']?.toString() ?? 'N/A', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 15)),
            if (sectionData['strengths'] != null && (sectionData['strengths'] as List).isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Strengths:', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    ...(sectionData['strengths'] as List).map((s) => Text('- $s', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 15))),
                  ],
                ),
              ),
            if (sectionData['areas_for_improvement'] != null && (sectionData['areas_for_improvement'] as List).isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Areas for Improvement:', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    ...(sectionData['areas_for_improvement'] as List).map((s) => Text('- $s', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 15))),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> analysisData = {};
    String errorMessage = '';
    try {
      analysisData = jsonDecode(jsonResult) as Map<String, dynamic>;
    } catch (e) {
      errorMessage = 'Failed to parse analysis JSON. Raw data: \n$jsonResult';
    }

    List<dynamic> sectionAnalysis = analysisData['section_analysis'] as List<dynamic>? ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resume Job Match Analysis'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_document),
            tooltip: 'Edit Resume',
            onPressed: () {
              // Extract the original resume JSON from the analysisData if it's nested
              // Assuming the original resume OCR output is available or can be passed
              // For now, let's assume jsonResult IS the resume JSON for simplicity in this step.
              // If it's nested, we'll need to adjust how it's passed.
              // The user's summary implies `jsonResult` from the previous step is the resume data.
              final resumeJsonForEditor = originalResumeJson; // Use the original resume JSON

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ResumeEditorPage(resumeJson: resumeJsonForEditor),
                ),
              );
            },
          ),
        ],
      ),
      body: errorMessage.isNotEmpty
          ? Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(errorMessage, style: const TextStyle(color: Colors.red))))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _buildOverallScore(context, analysisData['overall_match_score'] as int?),
                  const SizedBox(height: 16),
                  _buildSectionTitle(context, 'Conclusion', isConclusion: true),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                    child: Text(
                      analysisData['conclusion']?.toString() ?? 'No conclusion provided.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 16, fontStyle: FontStyle.italic),
                    ),
                  ),
                  const Divider(height: 32, thickness: 1),
                  _buildSectionTitle(context, 'Detailed Section Analysis'),
                  if (sectionAnalysis.isNotEmpty)
                    ...sectionAnalysis.map((section) => _buildSectionAnalysisCard(context, section as Map<String, dynamic>))
                  else
                    const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('No detailed section analysis available.'))),
                  
                  // Display General Resume Suggestions
                  if (analysisData.containsKey('general_resume_suggestions')) ...[
                    const Divider(height: 32, thickness: 1),
                    _buildSectionTitle(context, 'General Resume Suggestions'),
                    _buildGeneralSuggestionsCard(context, analysisData['general_resume_suggestions'] as Map<String, dynamic>?),
                  ]
                ],
              ),
            ),
    );
  }

  Widget _buildGeneralSuggestionsList(BuildContext context, String title, List<dynamic>? suggestions) {
    if (suggestions == null || suggestions.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          ...suggestions.map((s) => Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 2.0),
            child: Text('• $s', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 15)),
          )),
        ],
      ),
    );
  }

  Widget _buildGeneralSuggestionsCard(BuildContext context, Map<String, dynamic>? suggestionsData) {
    if (suggestionsData == null || suggestionsData.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('No general resume suggestions available.')));
    }
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGeneralSuggestionsList(context, 'Grammar and Phrasing', suggestionsData['grammar_and_phrasing'] as List<dynamic>?),
            _buildGeneralSuggestionsList(context, 'Formatting', suggestionsData['formatting'] as List<dynamic>?),
            _buildGeneralSuggestionsList(context, 'Missing Information', suggestionsData['missing_information'] as List<dynamic>?),
            _buildGeneralSuggestionsList(context, 'Other Suggestions', suggestionsData['other_suggestions'] as List<dynamic>?),
          ],
        ),
      ),
    );
  }
} 
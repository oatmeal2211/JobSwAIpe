import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import './job_match_result_page.dart'; // Will be created next
import 'package:flutter/foundation.dart'; // For kDebugMode

class JobDescriptionPage extends StatefulWidget {
  final String resumeJson;

  const JobDescriptionPage({super.key, required this.resumeJson});

  @override
  State<JobDescriptionPage> createState() => _JobDescriptionPageState();
}

class _JobDescriptionPageState extends State<JobDescriptionPage> {
  final _jobDescriptionController = TextEditingController();
  bool _isLoading = false;

  Future<void> _analyzeWithJobDescription() async {
    if (_jobDescriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a job description.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate API call for now
    // In a real app, this would call the qwen-plus model
    try {
      final String apiKey = dotenv.env['DASHSCOPE_API_KEY'] ?? '';
      if (apiKey.isEmpty) {
        throw Exception('DASHSCOPE_API_KEY not found in .env file');
      }

      final url = Uri.parse('https://dashscope-intl.aliyuncs.com/compatible-mode/v1/chat/completions');

      final String prompt = """Analyze the provided resume (in JSON format) against the given job description.
Return the analysis as a structured JSON object.

Resume JSON:
```json
${widget.resumeJson}
```

Job Description:
```
${_jobDescriptionController.text}
```

Important notes:
1. The resume data may be in either legacy format with predefined sections OR a new flexible format where sections are in an array
2. If the resume uses the new format, it will have a "sections" array where each section has "name" and "content" properties
3. Analyze each section of the resume against the job requirements regardless of the format
4. If there are job requirements that are not present in the resume, make sure to mention them in the "missing_information" section and suggest how to add them

Please structure your JSON output as follows:
{
  "overall_match_score": <percentage_0_to_100>,
  "conclusion": "<brief_summary_of_resume_suitability_for_the_job>",
  "section_analysis": [
    {
      "section_name": "<actual_section_name_as_it_appears_in_resume>",
      "relevance_score": <percentage_0_to_100>,
      "justification": "<brief_justification_for_the_score_for_this_section>",
      "strengths": [
         "<specific_strength_from_this_section_relevant_to_job>"
      ],
      "areas_for_improvement": [
         "<specific_area_where_this_section_could_better_match_job>"
      ]
    }
    // ... more sections ...
  ],
  "general_resume_suggestions": {
    "grammar_and_phrasing": [
      "<suggestion_for_grammar_or_phrasing_improvement_1>",
      "<suggestion_2>"
    ],
    "formatting": [
      "<suggestion_for_formatting_improvement_1>",
      "<suggestion_2>"
    ],
    "missing_information": [
      "<suggestion_for_potentially_missing_information_or_section_1>",
      "<suggestion_2>"
    ],
    "other_suggestions": [
      "<any_other_general_suggestion_to_improve_the_resume_1>"
    ]
  }
}

Ensure the final output is ONLY the JSON object itself, without any surrounding text, explanations, or markdown formatting.
""";
      if (kDebugMode) {
        print("Sending prompt to qwen-plus (or compatible model):");
        print(prompt);
      }

      final Map<String, dynamic> payload = {
        'model': 'qwen-plus', // Use qwen-plus model as requested
        'messages': [
          {
            'role': 'user',
            'content': prompt
          }
        ],
        // 'max_tokens': 1500, // Optional: Adjust as needed
        // 'temperature': 0.7, // Optional: Adjust for creativity vs. factuality
      };

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json; charset=utf-8',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final result = jsonDecode(decodedBody);
        
        if (kDebugMode) {
          print("API Response Body: $decodedBody");
        }

        if (result['choices'] != null && result['choices'].isNotEmpty) {
          final message = result['choices'][0]['message'];
          if (message != null && message['content'] != null) {
            final markdownResult = message['content'].toString();
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => JobMatchResultPage(
                    jsonResult: markdownResult,
                    originalResumeJson: widget.resumeJson,
                  ),
                ),
              );
            }
            return;
          }
        }
        throw Exception('Failed to parse AI model response structure.');
      } else {
        final errorBody = utf8.decode(response.bodyBytes);
        if (kDebugMode) {
          print('API Error Response Body: $errorBody');
        }
        throw Exception('API error ${response.statusCode}: $errorBody');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during analysis: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error analyzing job description: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _jobDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Job Description'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'Paste the job description below to see how well your resume matches.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _jobDescriptionController,
                maxLines: null, // Allows for multi-line input
                expands: true, // Fills available space
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(
                  hintText: 'Enter job description here...',
                  border: OutlineInputBorder(),
                ),
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _analyzeWithJobDescription,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Analyze Resume Fit', style: TextStyle(fontSize: 16)),
                  ),
          ],
        ),
      ),
    );
  }
} 
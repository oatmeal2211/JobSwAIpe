import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIService {
  // Base URL for Dashscope API
  final String baseUrl = "https://dashscope-intl.aliyuncs.com/compatible-mode/v1";
  
  // Get API key from environment
  String? get apiKey => dotenv.env['DASHSCOPE_API_KEY'];
  
  // Create chat completion with Qwen model
  Future<Map<String, dynamic>> analyzeResume(String resumeText) async {
    if (apiKey == null) {
      throw Exception('API key not found. Please set DASHSCOPE_API_KEY in .env file.');
    }
    
    final url = Uri.parse('$baseUrl/chat/completions');
    
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'qwen-plus',
          'messages': [
            {
              'role': 'system', 
              'content': 'You are a professional resume analyzer. Extract key information from resumes and organize them into meaningful sections.'
            },
            {
              'role': 'user',
              'content': '''
                Please analyze the following resume and extract the key information into the following JSON structure:
                {
                  "summary": "Brief professional summary",
                  "skills": ["skill1", "skill2", ...],
                  "experience": [
                    {
                      "title": "Job title",
                      "company": "Company name",
                      "duration": "Duration",
                      "description": "Brief description"
                    }
                  ],
                  "education": [
                    {
                      "degree": "Degree name",
                      "institution": "Institution name",
                      "year": "Graduation year"
                    }
                  ],
                  "certifications": ["certification1", "certification2", ...],
                  "languages": ["language1", "language2", ...],
                  "interests": ["interest1", "interest2", ...]
                }
                
                Resume text:
                $resumeText
              '''
            }
          ],
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        try {
          // Extract the JSON string from the model's response and parse it
          String content = data['choices'][0]['message']['content'];
          
          // Find JSON content - look for opening and closing braces
          final startIndex = content.indexOf('{');
          final endIndex = content.lastIndexOf('}') + 1;
          
          if (startIndex >= 0 && endIndex > startIndex) {
            final jsonString = content.substring(startIndex, endIndex);
            return jsonDecode(jsonString);
          } else {
            throw Exception('Could not extract JSON from response');
          }
        } catch (e) {
          throw Exception('Failed to parse AI response: $e');
        }
      } else {
        throw Exception('Failed to analyze resume: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Error communicating with AI service: $e');
    }
  }
  
  // Extract text from PDF URL
  Future<String> extractTextFromResumeUrl(String resumeUrl) async {
    // This is a simplified version - in a real application,
    // you would need to download the PDF and use a PDF text extraction library
    // For now, we'll assume the text is available or can be fetched elsewhere
    
    // Mock implementation
    try {
      final response = await http.get(Uri.parse(resumeUrl));
      
      if (response.statusCode == 200) {
        // In a real implementation, you would extract text from PDF here
        // For now, return a placeholder message
        return "This is placeholder text for resume extraction. In a real application, you would extract the actual text from the PDF.";
      } else {
        throw Exception('Failed to download resume: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error downloading resume: $e');
    }
  }
} 
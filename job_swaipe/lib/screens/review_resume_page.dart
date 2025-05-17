import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import '../services/file_picker_service.dart'; // Import your service
import 'package:flutter_dotenv/flutter_dotenv.dart';
import './resume_result_page.dart'; // Import the new result page
import 'package:pdfx/pdfx.dart'; // Import pdfx


class ReviewResumePage extends StatelessWidget {
  const ReviewResumePage({super.key});

  Future<void> _uploadPdf(BuildContext context) async {
    final filePickerService = FilePickerService();
    final result = await filePickerService.pickFile();

    if (result != null && result.files.isNotEmpty) {
      final filePath = result.files.single.path!;
      _showLoadingDialog(context); // Show loading dialog early

      try {
        // Load PDF document
        final pdfDocument = await PdfDocument.openFile(filePath);
        // Get the first page
        final page = await pdfDocument.getPage(1);
        // Render the page to an image (PNG format by default, good quality)
        // You can adjust width/height for resolution, here using a fixed width.
        final pageImage = await page.render(width: page.width * 2, height: page.height * 2, format: PdfPageImageFormat.png);
        await page.close();
        await pdfDocument.close();

        if (pageImage == null || pageImage.bytes.isEmpty) {
          Navigator.pop(context); // Close loading dialog
          _showErrorDialog(context, 'Failed to render PDF page to image.');
          return;
        }

        final base64String = base64Encode(pageImage.bytes);
        
        // Send as image (not PDF)
        final apiResult = await _sendToQwenOCR(base64String, isPdf: false); // Indicate it's an image now
        Navigator.pop(context); // Close loading dialog
        _showResult(context, apiResult);
      } catch (e) {
        Navigator.pop(context); // Close loading dialog
        _showErrorDialog(context, 'Failed to process PDF: ${e.toString()}');
      }
    }
  }

  Future<void> _takePhoto(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final uint8list = await file.readAsBytes();
      final base64String = base64Encode(uint8list);
      
      // Show loading indicator
      _showLoadingDialog(context);
      
      try {
        final result = await _sendToQwenOCR(base64String, isPdf: false);
        Navigator.pop(context);
        _showResult(context, result);
      } catch (e) {
        Navigator.pop(context);
        _showErrorDialog(context, 'Failed to process image: $e');
      }
    }
  }

  Future<String> _sendToQwenOCR(String base64Image, {required bool isPdf}) async {
    final url = Uri.parse('https://dashscope-intl.aliyuncs.com/compatible-mode/v1/chat/completions');
    final apiKey = dotenv.env['DASHSCOPE_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('DASHSCOPE_API_KEY not found in .env file');
    }
    final String mimeType = "image/png";
    
    final String promptText = """Perform OCR on the provided resume document (which is an image).
Extract all relevant information and structure it into a valid JSON object.

Important instructions:
1. Identify ALL sections present in the resume (don't limit to predefined categories)
2. Only include sections that are actually present in the resume
3. Maintain the original section names from the resume when possible
4. Structure data within each section based on how it appears in the resume
5. DO NOT force data into predefined categories or use null values

Your output should be a flexible JSON structure that mirrors the actual content and organization of the resume. A minimal example might look like:

{
  "sections": [
    {
      "name": "Contact Information",
      "content": {
        "name": "John Doe",
        "email": "john@example.com",
        "phone": "123-456-7890"
      }
    },
    {
      "name": "Work Experience",
      "content": [
        {
          "company": "Company XYZ",
          "role": "Software Engineer",
          "duration": "Jan 2020 - Present",
          "responsibilities": [
            "Developed feature X",
            "Managed system Y"
          ]
        }
      ]
    }
  ]
}

However, the actual structure should be determined by the resume's content. If the resume has unique sections like "Publications", "Research", "Patents", etc., include them with appropriate structure.

IMPORTANT: Each section's internal structure should reflect how that data is organized in the resume. Don't force standard structures if they don't fit.

Ensure the final output is ONLY the JSON object itself, without any surrounding text, explanations, or markdown formatting."""
    ;

    final Map<String, dynamic> payload = {
      'model': 'qwen-vl-max-latest', 
      'messages': [
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': promptText},
            {
              'type': 'image_url',
              'image_url': {'url': 'data:$mimeType;base64,$base64Image'}
            }
          ]
        }
      ],
      // It's good practice to control token usage if the API supports it,
      // though not strictly required by the user's example.
      // 'max_tokens': 2000 // Example: adjust as needed
    };

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json; charset=utf-8', // Specify UTF-8
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      // The response body might be UTF-8 encoded, ensure proper decoding
      final decodedBody = utf8.decode(response.bodyBytes);
      final result = jsonDecode(decodedBody);
      
      if (result['choices'] != null && result['choices'].isNotEmpty) {
        final message = result['choices'][0]['message'];
        if (message != null && message['content'] != null) {
          return message['content'].toString(); // This should be the JSON string
        }
      }
      throw Exception('Failed to parse AI model response structure.');
    } else {
      final errorBody = utf8.decode(response.bodyBytes);
      print('API Error Response Body: $errorBody'); // Log error for debugging
      throw Exception('API error ${response.statusCode}: $errorBody');
    }
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Processing document...'),
          ],
        ),
      ),
    );
  }

  void _showResult(BuildContext context, String result) {
    // Navigate to the new ResumeResultPage
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResumeResultPage(jsonResult: result),
        fullscreenDialog: true, // Present as a modal page
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: Text('OK'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Your Resume'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'Choose how to submit your resume:',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.picture_as_pdf, size: 28),
                label: const Text('Upload PDF Resume'),
                onPressed: () => _uploadPdf(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 24),
              const Row(
                children: <Widget>[
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text('OR', style: TextStyle(fontSize: 16)),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt, size: 28),
                label: const Text('Take Photo of Resume'),
                onPressed: () => _takePhoto(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
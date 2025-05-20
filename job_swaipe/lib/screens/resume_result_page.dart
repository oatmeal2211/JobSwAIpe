import 'package:flutter/material.dart';
import 'dart:convert'; // For jsonDecode
import './job_description_page.dart';

class ResumeResultPage extends StatelessWidget {
  final String jsonResult;

  const ResumeResultPage({super.key, required this.jsonResult});

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        title.replaceAll('_', ' ').toUpperCase(),
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  Widget _buildKeyValue(BuildContext context, String key, String? value, {bool isLink = false}) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 15),
          children: [
            TextSpan(text: '${key.replaceAll('_', ' ').capitalizeFirstofEach}: ', style: const TextStyle(fontWeight: FontWeight.w600)),
            TextSpan(
              text: value,
              style: isLink ? TextStyle(color: Theme.of(context).colorScheme.secondary, decoration: TextDecoration.underline) : null,
              // TODO: Add onTap for isLink to launch URL
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildList(BuildContext context, List<dynamic>? items, Widget Function(dynamic item) itemBuilder) {
    if (items == null || items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) => Padding(
        padding: const EdgeInsets.only(left: 16.0, top: 4.0, bottom: 4.0),
        child: itemBuilder(item),
      )).toList(),
    );
  }

  Widget _buildContactInfo(BuildContext context, Map<String, dynamic>? data) {
    if (data == null) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(context, 'Contact Information'),
            _buildKeyValue(context, 'Name', data['name']?.toString()),
            _buildKeyValue(context, 'Email', data['email']?.toString(), isLink: true),
            _buildKeyValue(context, 'Phone', data['phone']?.toString()),
            _buildKeyValue(context, 'Address', data['address']?.toString()),
            _buildKeyValue(context, 'LinkedIn', data['linkedin_url']?.toString(), isLink: true),
            _buildKeyValue(context, 'GitHub', data['github_url']?.toString(), isLink: true),
            if (data['other_links'] != null && (data['other_links'] as List).isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('Other Links:', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              ),
            _buildList(context, data['other_links'] as List<dynamic>?, (item) {
              final link = item as Map<String, dynamic>; 
              return _buildKeyValue(context, link['label']?.toString() ?? 'Link', link['url']?.toString(), isLink: true);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildExperienceEntry(BuildContext context, Map<String, dynamic> entry) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry['job_title']?.toString() ?? 'N/A',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              '${entry['company_name']?.toString() ?? 'N/A'}${entry['location'] != null ? ', ${entry['location']}' : ''}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontStyle: FontStyle.italic),
            ),
            Text(
              '${entry['start_date']?.toString() ?? 'N/A'} - ${entry['end_date']?.toString() ?? 'N/A'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            if (entry['responsibilities'] != null && (entry['responsibilities'] as List).isNotEmpty)
              Text('Responsibilities:', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
            _buildList(context, entry['responsibilities'] as List<dynamic>?, 
              (item) => Text('- ${item.toString()}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 15))), 
          ],
        ),
      ),
    );
  }

  // ... Implement similar _buildEducationEntry, _buildSkillsSection, _buildProjectsEntry, etc. ...
  // For brevity, I'll show a simplified structure for other sections. 
  // You'd expand these similarly to _buildExperienceEntry and _buildContactInfo.

  Widget _buildGenericSection(BuildContext context, String title, dynamic content) {
    if (content == null) return const SizedBox.shrink();
    if (content is String && content.isEmpty) return const SizedBox.shrink();
    if (content is List && content.isEmpty) return const SizedBox.shrink();
    if (content is Map && content.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, title),
          if (content is String)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0), child: Text(content, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 15)))
          else if (content is List)
            _buildList(context, content, (item) {
              if (item is Map<String, dynamic>) {
                // Basic map rendering, you might want specific widgets for known structures like skills languages
                return Card(child: Padding(padding: const EdgeInsets.all(8.0), child: Column(children: item.entries.map((e) => _buildKeyValue(context, e.key, e.value.toString())).toList())));
              }
              return Text('- ${item.toString()}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 15));
            })
          else if (content is Map<String, dynamic>)
            // Example for skills map, can be made more specific
            ...content.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                     child: Text(entry.key.replaceAll('_', ' ').capitalizeFirstofEach, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600))
                  ),
                  _buildList(context, entry.value as List<dynamic>?, (skill) => Text('- ${skill.toString()}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 15)))
                ],
              );
            }).toList(),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> parsedJson = {};
    String errorMessage = '';
    try {
      parsedJson = jsonDecode(jsonResult) as Map<String, dynamic>;
    } catch (e) {
      errorMessage = 'Failed to parse resume JSON. Raw data: \n$jsonResult';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analyzed Resume'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      ),
      body: errorMessage.isNotEmpty
          ? Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(errorMessage, style: const TextStyle(color: Colors.red))))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Dynamically build all sections from the resume JSON
                  if (parsedJson.containsKey('sections'))
                    ...buildDynamicSections(context, parsedJson['sections'] as List<dynamic>)
                  // Handle legacy format if needed
                  else ...[
                    _buildContactInfo(context, parsedJson['contact_information'] as Map<String, dynamic>?),
                    _buildGenericSection(context, 'Summary', parsedJson['summary']?.toString()),
                    _buildSectionTitle(context, 'Work Experience'),
                    _buildList(context, parsedJson['work_experience'] as List<dynamic>?, 
                      (item) => _buildExperienceEntry(context, item as Map<String, dynamic>)),
                    _buildGenericSection(context, 'Education', parsedJson['education'] as List<dynamic>?),
                    _buildGenericSection(context, 'Skills', parsedJson['skills'] as Map<String, dynamic>?),
                    _buildGenericSection(context, 'Projects', parsedJson['projects'] as List<dynamic>?),
                    _buildGenericSection(context, 'Certifications', parsedJson['certifications'] as List<dynamic>?),
                    _buildGenericSection(context, 'Awards and Honors', parsedJson['awards_and_honors'] as List<dynamic>?),
                    _buildGenericSection(context, 'Other Sections', parsedJson['other_sections'] as List<dynamic>?),
                  ],

                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => JobDescriptionPage(resumeJson: jsonResult), // Pass jsonResult
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6D4C41),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    child: const Text('Analyze with Job Description'),
                  ),
                ],
              ),
            ),
    );
  }

  // New method to handle the dynamic sections from the AI model
  List<Widget> buildDynamicSections(BuildContext context, List<dynamic> sections) {
    final List<Widget> sectionWidgets = [];
    
    for (final section in sections) {
      if (section is Map<String, dynamic> && 
          section.containsKey('name') && 
          section.containsKey('content')) {
        
        String sectionName = section['name'].toString();
        dynamic content = section['content'];
        
        sectionWidgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(context, sectionName),
                    _buildDynamicContent(context, content),
                  ],
                ),
              ),
            ),
          )
        );
      }
    }
    
    return sectionWidgets;
  }

  // Helper method to render different types of content
  Widget _buildDynamicContent(BuildContext context, dynamic content) {
    if (content == null) {
      return const SizedBox.shrink();
    }
    
    // Handle string content
    if (content is String) {
      return Padding(
        padding: const EdgeInsets.only(left: 8.0, top: 8.0),
        child: Text(content, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 15)),
      );
    } 
    
    // Handle list content
    else if (content is List) {
      return _buildList(context, content, (item) {
        // If the list item is a map (like an object)
        if (item is Map<String, dynamic>) {
          return Card(
            elevation: 1,
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: item.entries.map((entry) {
                  // Handle nested objects or lists
                  if (entry.value is Map || entry.value is List) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4.0, top: 8.0),
                          child: Text(
                            entry.key.replaceAll('_', ' ').capitalizeFirstofEach,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        _buildDynamicContent(context, entry.value),
                      ],
                    );
                  } else {
                    return _buildKeyValue(context, entry.key, entry.value?.toString());
                  }
                }).toList(),
              ),
            ),
          );
        } 
        // If the list item is a simple value (string, number, etc.)
        else {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Text('• ${item.toString()}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 15)),
          );
        }
      });
    } 
    
    // Handle map content
    else if (content is Map<String, dynamic>) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: content.entries.map((entry) {
          // If the entry value is a complex type (map or list)
          if (entry.value is Map || entry.value is List) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                  child: Text(
                    entry.key.replaceAll('_', ' ').capitalizeFirstofEach,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                _buildDynamicContent(context, entry.value),
              ],
            );
          } else {
            return _buildKeyValue(context, entry.key, entry.value?.toString());
          }
        }).toList(),
      );
    } 
    
    // Fallback for any other content type
    else {
      return Text(content.toString(), style: Theme.of(context).textTheme.bodyMedium);
    }
  }
}

// Helper extension
extension StringExtension on String {
  String get capitalizeFirstofEach => split(" ").map((str) => str.isNotEmpty ? '${str[0].toUpperCase()}${str.substring(1)}' : '').join(" ");
} 
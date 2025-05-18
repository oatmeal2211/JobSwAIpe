import 'package:flutter/material.dart';
import 'dart:convert'; // For jsonDecode
import 'dart:io'; // For File operations
import 'package:path_provider/path_provider.dart'; // For temporary directory
import 'package:pdf/widgets.dart' as pw; // For PDF generation
import 'package:pdf/pdf.dart'; // For PdfColors, PdfPageFormat
import 'package:open_file/open_file.dart'; // For opening the PDF file
import 'package:printing/printing.dart'; // For PdfGoogleFonts
// We will add pdf and path_provider/share_plus imports later

// Helper extension for string capitalization
extension StringExtension on String {
  String capitalizeFirstofEach() {
    if (isEmpty) return this;
    return split(' ').map((str) => str.isEmpty ? '' : '${str[0].toUpperCase()}${str.substring(1)}').join(' ');
  }
}

class ResumeEditorPage extends StatefulWidget {
  final String resumeJson;

  const ResumeEditorPage({super.key, required this.resumeJson});

  @override
  State<ResumeEditorPage> createState() => _ResumeEditorPageState();
}

class _ResumeEditorPageState extends State<ResumeEditorPage> {
  Map<String, dynamic> _resumeData = {};
  final _formKey = GlobalKey<FormState>();

  // Controllers for each field will be dynamically created
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, List<TextEditingController>> _listControllers = {};
  final Map<String, List<Map<String, TextEditingController>>> _listOfMapsControllers = {};

  @override
  void initState() {
    super.initState();
    _parseResumeJson();
  }

  @override
  void dispose() {
    _controllers.values.forEach((controller) => controller.dispose());
    _listControllers.values.forEach((list) => list.forEach((controller) => controller.dispose()));
    _listOfMapsControllers.values.forEach((list) {
      for (var mapCtrl in list) {
        mapCtrl.values.forEach((controller) => controller.dispose());
      }
    });
    super.dispose();
  }

  void _parseResumeJson() {
    try {
      final decodedJson = jsonDecode(widget.resumeJson);
      if (decodedJson is Map<String, dynamic>) {
        _resumeData = Map<String, dynamic>.from(decodedJson);
        _clearAndInitializeControllers();
      } else {
        _resumeData = {'error': 'Invalid resume JSON format', 'raw': widget.resumeJson};
      }
    } catch (e) {
      _resumeData = {
        'error': 'Failed to parse resume JSON',
        'details': e.toString(),
        'raw': widget.resumeJson
      };
    }
  }

  void _clearAndInitializeControllers() {
    _controllers.clear();
    _listControllers.clear();
    _listOfMapsControllers.clear();
    _initializeControllers(_resumeData, "");
  }

  void _initializeControllers(dynamic data, String prefix) {
    if (data == null) return;

    if (data is Map<String, dynamic>) {
      data.forEach((key, value) {
        String currentKey = prefix.isEmpty ? key : '$prefix.$key';
        if (value is String) {
          _controllers[currentKey] = TextEditingController(text: value);
        } else if (value is List) {
          if (value.isNotEmpty && value.first is Map<String, dynamic>) {
            _listOfMapsControllers[currentKey] = [];
            for (var item in value) {
              if (item is Map<String, dynamic>) {
                Map<String, TextEditingController> itemControllers = {};
                item.forEach((itemKey, itemValue) {
                  itemControllers[itemKey] = TextEditingController(
                    text: itemValue?.toString() ?? '',
                  );
                });
                _listOfMapsControllers[currentKey]!.add(itemControllers);
              }
            }
          } else {
            _listControllers[currentKey] = value
                .map((item) => TextEditingController(text: item?.toString() ?? ''))
                .toList();
          }
        } else if (value is Map<String, dynamic>) {
          _initializeControllers(value, currentKey);
        } else if (value != null) {
          _controllers[currentKey] = TextEditingController(text: value.toString());
        }
      });
    } else if (data is String) {
      _controllers[prefix] = TextEditingController(text: data);
    } else if (data is List) {
      if (data.isNotEmpty && data.first is Map<String, dynamic>) {
        _listOfMapsControllers[prefix] = [];
        for (var item in data) {
          if (item is Map<String, dynamic>) {
            Map<String, TextEditingController> itemControllers = {};
            item.forEach((key, value) {
              itemControllers[key] = TextEditingController(
                text: value?.toString() ?? '',
              );
            });
            _listOfMapsControllers[prefix]!.add(itemControllers);
          }
        }
      } else {
        _listControllers[prefix] = data
            .map((item) => TextEditingController(text: item?.toString() ?? ''))
            .toList();
      }
    }
  }

  void _updateResumeDataFromControllers() {
    Map<String, dynamic> newResumeData = jsonDecode(jsonEncode(_resumeData));
    _recursiveUpdateFromControllers(newResumeData, "");
    setState(() {
      _resumeData = newResumeData;
    });
  }

  void _recursiveUpdateFromControllers(dynamic currentData, String prefix) {
    if (currentData is Map<String, dynamic>) {
      List<String> keys = currentData.keys.toList();
      for (String key in keys) {
        String currentKeyPath = prefix.isEmpty ? key : '$prefix.$key';
        if (_controllers.containsKey(currentKeyPath)) {
          currentData[key] = _controllers[currentKeyPath]!.text;
        } else if (_listOfMapsControllers.containsKey(currentKeyPath) &&
            currentData[key] is List) {
          List<Map<String, dynamic>> updatedList = [];
          for (var controllerMap in _listOfMapsControllers[currentKeyPath]!) {
            Map<String, dynamic> updatedItem = {};
            controllerMap.forEach((fieldKey, controller) {
              updatedItem[fieldKey] = controller.text;
            });
            updatedList.add(updatedItem);
          }
          currentData[key] = updatedList;
        } else if (_listControllers.containsKey(currentKeyPath) &&
            currentData[key] is List) {
          currentData[key] =
              _listControllers[currentKeyPath]!.map((c) => c.text).toList();
        } else if (currentData[key] is Map<String, dynamic>) {
          _recursiveUpdateFromControllers(currentData[key], currentKeyPath);
        } else if (currentData[key] is List) {
          _recursiveUpdateFromControllers(currentData[key], currentKeyPath);
        }
      }
    } else if (currentData is List) {
      for (int i = 0; i < currentData.length; i++) {
        String currentItemPath = '$prefix[$i]';
        if (currentData[i] is Map<String, dynamic> || currentData[i] is List) {
          _recursiveUpdateFromControllers(currentData[i], currentItemPath);
        } else if (_controllers.containsKey(currentItemPath)) {
          currentData[i] = _controllers[currentItemPath]!.text;
        }
      }
    }
  }
  
  dynamic _getNestedDynamic(dynamic data, List<String> pathParts) {
    dynamic current = data;
    for (String part in pathParts) {
      if (part.endsWith(']')) {
        String listKey = part.substring(0, part.indexOf('['));
        int index = int.parse(part.substring(part.indexOf('[') + 1, part.length - 1));
        if (current is Map<String, dynamic> && current.containsKey(listKey) && current[listKey] is List) {
          current = current[listKey];
          if (index < (current as List).length) {
            current = current[index];
          } else {
            return null;
          }
        } else if (current is List && index < current.length) {
          current = current[index];
        } else {
          return null;
        }
      } else {
        if (current is Map<String, dynamic> && current.containsKey(part)) {
          current = current[part];
        } else {
          return null;
        }
      }
    }
    return current;
  }

  void _deleteSection(int index) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
            return AlertDialog(
                title: const Text('Confirm Delete'),
                content: const Text('Are you sure you want to delete this section and all its content?'),
                actions: <Widget>[
                    TextButton(
                        child: const Text('Cancel'),
                        onPressed: () {
                            Navigator.of(context).pop();
                        },
                    ),
                    TextButton(
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                        onPressed: () {
                            setState(() {
                                if (_resumeData['sections'] is List &&
                                    index >= 0 &&
                                    index < (_resumeData['sections'] as List).length) {
                                    (_resumeData['sections'] as List).removeAt(index);
                                    _clearAndInitializeControllers(); // Re-initialize controllers
                                }
                            });
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Section deleted successfully.')),
                            );
                        },
                    ),
                ],
            );
        },
    );
  }

  void _addNewSection() {
    showDialog(
        context: context,
        builder: (context) {
            String newSectionName = "";
            return AlertDialog(
                title: const Text("Add New Section"),
                content: TextField(
                    onChanged: (value) {
                        newSectionName = value;
                    },
                    decoration: const InputDecoration(hintText: "Section Name"),
                ),
                actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                    TextButton(
                        onPressed: () {
                            if (newSectionName.isNotEmpty) {
                                setState(() {
                                    if (_resumeData['sections'] == null || !(_resumeData['sections'] is List)) {
                                        _resumeData['sections'] = [];
                                    }
                                    // Add new section with a default map content to allow adding fields
                                    (_resumeData['sections'] as List).add({
                                        "name": newSectionName,
                                        "content": <String, dynamic>{ "new_field": "Edit this value"} // Default content as a map
                                    });
                                    _clearAndInitializeControllers(); // Re-initialize
                                });
                                Navigator.pop(context);
                            }
                        },
                        child: const Text("Add")
                    ),
                ],
            );
        }
    );
  }

  Future<void> _exportToPdf() async {
    _updateResumeDataFromControllers();

    final pdf = pw.Document();
    final font = await PdfGoogleFonts.nunitoRegular();
    final boldFont = await PdfGoogleFonts.nunitoBold();
    final italicFont = await PdfGoogleFonts.nunitoItalic();

    // Create a single page with all sections
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          List<pw.Widget> allSectionWidgets = [];

          // Get sections from the resume data
          List<dynamic> sections = (_resumeData['sections'] as List<dynamic>?) ?? [];

          // Add each section to the page
          for (var sectionData in sections) {
            if (sectionData is Map<String, dynamic>) {
              final sectionName = sectionData['name']?.toString() ?? 'Unnamed Section';
              final sectionContent = sectionData['content'];

              // Add section header
              allSectionWidgets.add(
                pw.Header(
                  level: 1,
                  child: pw.Text(
                    sectionName.toUpperCase(),
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 14,
                      color: PdfColors.blueGrey800,
                    ),
                  ),
                ),
              );

              // Add section divider
              allSectionWidgets.add(
                pw.Divider(
                  thickness: 0.5,
                  color: PdfColors.blueGrey300,
                  height: 8,
                ),
              );

              // Format content based on section type
              if (sectionName.toUpperCase() == 'CONTACT INFORMATION') {
                _formatContactInfo(allSectionWidgets, sectionContent, font);
              } else if (sectionName.toUpperCase() == 'SUMMARY') {
                _formatSummary(allSectionWidgets, sectionContent, font);
              } else if (sectionName.toUpperCase() == 'INDUSTRIAL EXPERIENCE' || 
                        sectionName.toUpperCase() == 'WORK EXPERIENCE') {
                _formatExperience(allSectionWidgets, sectionContent, font, boldFont);
              } else if (sectionName.toUpperCase() == 'TECHNICAL PROJECTS' || 
                        sectionName.toUpperCase() == 'PROJECTS') {
                _formatProjects(allSectionWidgets, sectionContent, font, boldFont);
              } else if (sectionName.toUpperCase() == 'EDUCATION') {
                _formatEducation(allSectionWidgets, sectionContent, font, boldFont);
              } else if (sectionName.toUpperCase() == 'SKILLS') {
                _formatSkills(allSectionWidgets, sectionContent, font);
              } else {
                // Generic section formatting
                _formatGenericSection(allSectionWidgets, sectionContent, font, boldFont);
              }

              // Add space between sections
              allSectionWidgets.add(pw.SizedBox(height: 16));
            }
          }

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: allSectionWidgets,
          );
        },
      ),
    );

    try {
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/resume_export.pdf");
      await file.writeAsBytes(await pdf.save());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF exported to: ${file.path}')),
        );
        await OpenFile.open(file.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting PDF: $e')),
        );
      }
    }
  }

  void _formatContactInfo(List<pw.Widget> widgets, dynamic content, pw.Font font) {
    if (content is Map<String, dynamic>) {
      List<String> contactDetails = [];
      if (content['name'] != null) contactDetails.add(content['name'].toString());
      if (content['email'] != null) contactDetails.add(content['email'].toString());
      if (content['phone'] != null) contactDetails.add(content['phone'].toString());
      if (content['LinkedIn'] != null) contactDetails.add('LinkedIn: ${content['LinkedIn']}');
      if (content['GitHub'] != null) contactDetails.add('GitHub: ${content['GitHub']}');

      widgets.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 8),
          child: pw.Text(
            contactDetails.join(' | '),
            style: pw.TextStyle(font: font, fontSize: 10, lineSpacing: 1.5),
            textAlign: pw.TextAlign.center,
          ),
        ),
      );
    }
  }

  void _formatSummary(List<pw.Widget> widgets, dynamic content, pw.Font font) {
    String summaryText = '';
    if (content is String) {
      summaryText = content;
    } else if (content is Map<String, dynamic>) {
      summaryText = content.values.first.toString();
    }

    widgets.add(
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 8),
        child: pw.Text(
          summaryText,
          style: pw.TextStyle(font: font, fontSize: 10, lineSpacing: 1.5),
        ),
      ),
    );
  }

  void _formatExperience(List<pw.Widget> widgets, dynamic content, pw.Font font, pw.Font boldFont) {
    if (content is List) {
      for (var exp in content) {
        if (exp is Map<String, dynamic>) {
          // Company and Role
          widgets.add(
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 8),
              child: pw.Text(
                '${exp['company'] ?? ''} - ${exp['role'] ?? ''}',
                style: pw.TextStyle(font: boldFont, fontSize: 11),
              ),
            ),
          );

          // Duration
          if (exp['duration'] != null) {
            widgets.add(
              pw.Text(
                exp['duration'].toString(),
                style: pw.TextStyle(font: font, fontSize: 10, fontStyle: pw.FontStyle.italic),
              ),
            );
          }

          // Responsibilities
          if (exp['responsibilities'] != null) {
            var resp = exp['responsibilities'];
            if (resp is List) {
              for (var item in resp) {
                widgets.add(
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 12, top: 4),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('• ', style: pw.TextStyle(font: font, fontSize: 10)),
                        pw.Expanded(
                          child: pw.Text(
                            item.toString(),
                            style: pw.TextStyle(font: font, fontSize: 10, lineSpacing: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            }
          }
        }
      }
    }
  }

  void _formatProjects(List<pw.Widget> widgets, dynamic content, pw.Font font, pw.Font boldFont) {
    if (content is List) {
      for (var project in content) {
        if (project is Map<String, dynamic>) {
          // Project Title
          widgets.add(
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 8),
              child: pw.Text(
                project['name'] ?? '',
                style: pw.TextStyle(font: boldFont, fontSize: 11),
              ),
            ),
          );

          // Technologies/Tools
          if (project['technologies'] != null) {
            widgets.add(
              pw.Text(
                project['technologies'].toString(),
                style: pw.TextStyle(font: font, fontSize: 10, fontStyle: pw.FontStyle.italic),
              ),
            );
          }

          // Description
          if (project['description'] != null) {
            widgets.add(
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 12, top: 4),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('• ', style: pw.TextStyle(font: font, fontSize: 10)),
                    pw.Expanded(
                      child: pw.Text(
                        project['description'].toString(),
                        style: pw.TextStyle(font: font, fontSize: 10, lineSpacing: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        }
      }
    }
  }

  void _formatEducation(List<pw.Widget> widgets, dynamic content, pw.Font font, pw.Font boldFont) {
    if (content is List) {
      for (var edu in content) {
        if (edu is Map<String, dynamic>) {
          // Institution
          widgets.add(
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 8),
              child: pw.Text(
                edu['institution'] ?? '',
                style: pw.TextStyle(font: boldFont, fontSize: 11),
              ),
            ),
          );

          // Degree
          if (edu['degree'] != null) {
            widgets.add(
              pw.Text(
                edu['degree'].toString(),
                style: pw.TextStyle(font: font, fontSize: 10, fontStyle: pw.FontStyle.italic),
              ),
            );
          }

          // Duration
          if (edu['duration'] != null) {
            widgets.add(
              pw.Text(
                edu['duration'].toString(),
                style: pw.TextStyle(font: font, fontSize: 10),
              ),
            );
          }
        }
      }
    }
  }

  void _formatSkills(List<pw.Widget> widgets, dynamic content, pw.Font font) {
    if (content is Map<String, dynamic>) {
      content.forEach((category, skills) {
        if (skills is List) {
          widgets.add(
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4),
              child: pw.Text(
                '$category: ${skills.join(', ')}',
                style: pw.TextStyle(font: font, fontSize: 10, lineSpacing: 1.5),
              ),
            ),
          );
        }
      });
    } else if (content is List) {
      widgets.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 4),
          child: pw.Text(
            content.join(', '),
            style: pw.TextStyle(font: font, fontSize: 10, lineSpacing: 1.5),
          ),
        ),
      );
    }
  }

  void _formatGenericSection(List<pw.Widget> widgets, dynamic content, pw.Font font, pw.Font boldFont) {
    if (content is List) {
      for (var item in content) {
        if (item is Map<String, dynamic>) {
          item.forEach((key, value) {
            widgets.add(
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 4),
                child: pw.Text(
                  '$key: ${value.toString()}',
                  style: pw.TextStyle(font: font, fontSize: 10, lineSpacing: 1.5),
                ),
              ),
            );
          });
        } else {
          widgets.add(
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4),
              child: pw.Text(
                item.toString(),
                style: pw.TextStyle(font: font, fontSize: 10, lineSpacing: 1.5),
              ),
            ),
          );
        }
      }
    } else if (content is Map<String, dynamic>) {
      content.forEach((key, value) {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 4),
            child: pw.Text(
              '$key: ${value.toString()}',
              style: pw.TextStyle(font: font, fontSize: 10, lineSpacing: 1.5),
            ),
          ),
        );
      });
    } else {
      widgets.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 4),
          child: pw.Text(
            content.toString(),
            style: pw.TextStyle(font: font, fontSize: 10, lineSpacing: 1.5),
          ),
        ),
      );
    }
  }

  Widget _buildEditableField(String fieldKey, TextEditingController controller,
      {String? label}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label ?? fieldKey.split('.').last.capitalizeFirstofEach(),
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        maxLines: null,
      ),
    );
  }

  Widget _buildEditableListItem(String listKey, int index,
      TextEditingController controller, String itemPrefix) {
    // Parse the content to remove JSON syntax
    String content = controller.text;

    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Item ${index + 1}',
                border: const OutlineInputBorder(),
              ),
              maxLines: null,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
          onPressed: () {
            setState(() {
              _listControllers[listKey]?.removeAt(index);
              List<String> pathParts =
                  listKey.split(RegExp(r'[.\[\]]+')).where((s) => s.isNotEmpty).toList();
              dynamic targetList = _getNestedDynamic(_resumeData, pathParts);
              if (targetList is List && index < targetList.length) {
                targetList.removeAt(index);
              }
            });
          },
        )
      ],
    );
  }

  Widget _buildEditableMapListItem(String listKey, int index,
      Map<String, TextEditingController> itemControllers, String itemPrefix) {
    List<Widget> fieldWidgets = [];
    itemControllers.forEach((field, controller) {
      fieldWidgets.add(_buildEditableField('$itemPrefix.$field', controller,
          label: field.capitalizeFirstofEach()));
    });

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...fieldWidgets,
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                tooltip: 'Remove this item',
                onPressed: () {
                  setState(() {
                    _listOfMapsControllers[listKey]?.removeAt(index);
                    List<String> pathParts = listKey
                        .split(RegExp(r'[.\[\]]+')).where((s) => s.isNotEmpty).toList();
                    dynamic targetList = _getNestedDynamic(_resumeData, pathParts);
                    if (targetList is List && index < targetList.length) {
                      targetList.removeAt(index);
                    }
                  });
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAddListItemButton(
      String listKey, dynamic sectionContentListOrMap, String listOrMapPropertyKey) {
    return TextButton.icon(
      icon: const Icon(Icons.add_circle_outline),
      label: const Text('Add Item'),
      onPressed: () {
        setState(() {
          List<String> pathParts =
              listKey.split(RegExp(r'[.\[\]]+')).where((s) => s.isNotEmpty).toList();
          dynamic targetList = _getNestedDynamic(_resumeData, pathParts);

          if (targetList is List) {
            dynamic newItem;
            if (_listOfMapsControllers.containsKey(listKey)) {
              newItem = <String, String>{};
              if (targetList.isNotEmpty && targetList.first is Map) {
                (targetList.first as Map).keys.forEach((key) {
                  (newItem as Map<String, String>)[key.toString()] = "";
                });
              } else if (_listOfMapsControllers[listKey]!.isNotEmpty) {
                _listOfMapsControllers[listKey]!.first.keys.forEach((key) {
                  (newItem as Map<String, String>)[key.toString()] = "";
                });
              }
              if ((newItem as Map).isEmpty) {
                newItem['new_field'] = '';
              }
            } else {
              newItem = '';
            }
            targetList.add(newItem);
            _clearAndInitializeControllers();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text("Could not add item: target is not a list at path $listKey")),
            );
          }
        });
      },
    );
  }

  List<Widget> _buildFormWidgets(dynamic data, String prefix) {
    List<Widget> widgets = [];

    if (data is String) {
      if (!_controllers.containsKey(prefix)) {
        _controllers[prefix] = TextEditingController(text: data);
      }
      String label = prefix.split('.').last;
      if (label == 'content' && prefix.contains('.')) {
        label = prefix.split('.')[prefix.split('.').length - 2] + " " + label;
      }
      widgets.add(_buildEditableField(prefix, _controllers[prefix]!,
          label: label.capitalizeFirstofEach()));
    } else if (data is List) {
      String listKey = prefix;

      if (_listOfMapsControllers.containsKey(listKey)) {
        for (int i = 0; i < (_listOfMapsControllers[listKey]?.length ?? 0); i++) {
          widgets.add(_buildEditableMapListItem(
              listKey, i, _listOfMapsControllers[listKey]![i], '$listKey[$i]'));
        }
      } else {
        if (!_listControllers.containsKey(listKey) && data.isNotEmpty) {
          _listControllers[listKey] = data
              .map((item) => TextEditingController(text: item?.toString() ?? ''))
              .toList();
        }
        for (int i = 0; i < (_listControllers[listKey]?.length ?? 0); i++) {
          widgets.add(_buildEditableListItem(
              listKey, i, _listControllers[listKey]![i], '$listKey[$i]'));
        }
      }
      widgets.add(_buildAddListItemButton(listKey, data, ""));
    } else if (data is Map<String, dynamic>) {
      data.forEach((key, value) {
        String currentKey = prefix.isEmpty ? key : '$prefix.$key';
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 12.0, bottom: 4.0),
            child: Text(
              key.replaceAll('_', ' ').capitalizeFirstofEach(),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        );

        if (value is String) {
          if (!_controllers.containsKey(currentKey)) {
            _controllers[currentKey] = TextEditingController(text: value);
          }
          widgets.add(_buildEditableField(currentKey, _controllers[currentKey]!));
        } else if (value is List) {
          if (value.isNotEmpty && value.first is Map<String, dynamic>) {
            if (!_listOfMapsControllers.containsKey(currentKey)) {
              _listOfMapsControllers[currentKey] = [];
              for (var itemMap in value) {
                if (itemMap is Map<String, dynamic>) {
                  Map<String, TextEditingController> itemCtrlMap = {};
                  itemMap.forEach((k, v) {
                    itemCtrlMap[k] =
                        TextEditingController(text: v?.toString() ?? "");
                  });
                  _listOfMapsControllers[currentKey]!.add(itemCtrlMap);
                }
              }
            }
            for (int i = 0;
                i < (_listOfMapsControllers[currentKey]?.length ?? 0);
                i++) {
              widgets.add(_buildEditableMapListItem(currentKey, i,
                  _listOfMapsControllers[currentKey]![i], '$currentKey[$i]'));
            }
          } else {
            if (!_listControllers.containsKey(currentKey)) {
              _listControllers[currentKey] = value
                  .map((item) => TextEditingController(text: item.toString()))
                  .toList();
            }
            for (int i = 0; i < (_listControllers[currentKey]?.length ?? 0); i++) {
              widgets.add(_buildEditableListItem(currentKey, i,
                  _listControllers[currentKey]![i], '$currentKey[$i]'));
            }
          }
          widgets.add(_buildAddListItemButton(currentKey, value, key));
        } else if (value is Map<String, dynamic>) {
          widgets.addAll(_buildFormWidgets(value, currentKey));
        } else if (value != null) {
          if (!_controllers.containsKey(currentKey)) {
            _controllers[currentKey] =
                TextEditingController(text: value.toString());
          }
          widgets.add(_buildEditableField(currentKey, _controllers[currentKey]!));
        }
      });
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    if (_resumeData.containsKey('error')) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
                'Could not load resume data: ${_resumeData['error']}\n${_resumeData['details'] ?? ''}\nRaw: ${_resumeData['raw'] ?? ''}'),
          ),
        ),
      );
    }
    
    List<dynamic> sections = [];
    if (_resumeData.containsKey('sections') && _resumeData['sections'] is List) {
      sections = _resumeData['sections'] as List<dynamic>;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Resume'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save Changes (Locally)',
            onPressed: () {
              _updateResumeDataFromControllers();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Changes applied locally. Export to save to PDF.'),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export to PDF',
            onPressed: _exportToPdf,
          ),
        ],
      ),
      body: sections.isEmpty && !_resumeData.containsKey('error')
          ? Center(child: Text('No sections found in the resume data or data is empty. '
          'Raw: ${widget.resumeJson}'))
          : Form(
              key: _formKey,
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: sections.length,
                itemBuilder: (context, index) {
                  final section = sections[index];
                  if (section is Map<String, dynamic>) {
                    final sectionName = section['name']?.toString() ?? 'Unnamed Section';
                    final sectionContent = section['content'];
                    final contentPrefix = 'sections[$index].content';

                    return Card(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                            Expanded(
                                              child: Text(
                                                  sectionName,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .headlineSmall
                                                      ?.copyWith(fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            IconButton(
                                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                                tooltip: 'Delete Section',
                                                onPressed: () => _deleteSection(index),
                                            )
                                        ],
                                    ),
                                    const Divider(thickness: 1, height: 20),
                                    ...?_buildFormWidgets(sectionContent, contentPrefix),
                                ],
                            ),
                        ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            floatingActionButton: FloatingActionButton.extended(
                onPressed: _addNewSection,
                label: const Text('Add Section'),
                icon: const Icon(Icons.add),
            ),
    );
  }
}
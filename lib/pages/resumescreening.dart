import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ResumeScreeningPage extends StatefulWidget {
  const ResumeScreeningPage({super.key});

  @override
  State<ResumeScreeningPage> createState() => _ResumeScreeningPageState();
}

class _ResumeScreeningPageState extends State<ResumeScreeningPage> {
  PlatformFile? jobDescriptionFile;
  List<PlatformFile> resumeFiles = [];
  List<Map<String, dynamic>> results = [];
  bool isLoading = false; // Loading state
  String jobRequirementsOverview = "";
  List<bool> expandedStates = []; // Track expansion state per resume

  Future<void> pickJobDescription() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        jobDescriptionFile = result.files.single;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job description file selected')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No job description file selected')),
      );
    }
  }

  Future<void> pickResumes() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx'],
      allowMultiple: true,
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        resumeFiles = result.files;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${resumeFiles.length} resume(s) selected')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No resumes selected')),
      );
    }
  }

  Future<void> uploadFiles() async {
    if (jobDescriptionFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a job description file first')),
      );
      return;
    }
    if (resumeFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one resume')),
      );
      return;
    }

    setState(() {
      isLoading = true;
      results = [];
      jobRequirementsOverview = "";
      expandedStates = [];
    });

    var uri = Uri.parse('http://192.168.100.120:8000/match-resumes/');

    var request = http.MultipartRequest('POST', uri);

    request.files.add(http.MultipartFile.fromBytes(
      'job_file',
      jobDescriptionFile!.bytes!,
      filename: jobDescriptionFile!.name,
      contentType: MediaType('text', 'plain'),
    ));

    for (var file in resumeFiles) {
      String mimeType = 'application/octet-stream';
      if (file.extension == 'pdf') {
        mimeType = 'application/pdf';
      } else if (file.extension == 'docx') {
        mimeType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      }
      request.files.add(http.MultipartFile.fromBytes(
        'resumes',
        file.bytes!,
        filename: file.name,
        contentType: MediaType.parse(mimeType),
      ));
    }

    try {
      var response = await request.send();
      final respStr = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(respStr);

        setState(() {
          jobRequirementsOverview = (data['job_requirements'] ?? '').toString().replaceAll('*', '').trim();
          results = List<Map<String, dynamic>>.from(data['results'] ?? []);
          expandedStates = List.generate(results.length, (_) => false);
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Files uploaded and processed successfully')),
        );
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: ${response.statusCode}')),
        );
        print('Error response: $respStr');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload error: $e')),
      );
      print('Exception: $e');
    }
  }

  Widget _buildResultCard(Map<String, dynamic> r, int index) {
    String feedback = (r['feedback'] ?? '').toString().replaceAll('*', '').trim();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: expandedStates[index],
          onExpansionChanged: (bool expanded) {
            setState(() {
              expandedStates[index] = expanded;
            });
          },
          leading: AnimatedRotation(
            turns: expandedStates[index] ? 0.5 : 0.0, // rotate 180 degrees when expanded
            duration: const Duration(milliseconds: 300),
            child: const Icon(
              Icons.keyboard_double_arrow_down,
              color: Colors.green,
            ),
          ),
          title: Text(r['resume_name'] ?? 'Unknown'),
          subtitle: Text('Score: ${r['match_score']?.toStringAsFixed(2) ?? 'N/A'}'),
          trailing: Text('Rank: ${r['rank'] ?? '-'}'),
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Feedback Summary",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    feedback,
                    style: const TextStyle(fontSize: 14),
                  ),
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
    return Scaffold(
      appBar: AppBar(title: const Text("Resume Screening")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text('Select Job Description (txt)'),
              onPressed: pickJobDescription,
            ),
            if (jobDescriptionFile != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        'Selected: ${jobDescriptionFile!.name}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    // Arrow icon to expand/collapse Job Requirements Overview
                    IconButton(
                      icon: Icon(
                        jobRequirementsOverview.isNotEmpty
                            ? Icons.keyboard_double_arrow_down
                            : Icons.info_outline,
                        color: Colors.blue,
                      ),
                      onPressed: () {
                        // Toggle visibility or scroll to job requirements
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Job Requirements Overview'),
                            content: SingleChildScrollView(
                              child: Text(
                                jobRequirementsOverview.isNotEmpty
                                    ? jobRequirementsOverview
                                    : 'No job requirements available yet.',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Close'))
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text('Select Resumes (pdf, docx)'),
              onPressed: pickResumes,
            ),
            if (resumeFiles.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('${resumeFiles.length} resume(s) selected'),
              ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Upload and Match Resumes'),
              onPressed: isLoading ? null : uploadFiles,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: isLoading
                  ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Processing, please wait...'),
                  ],
                ),
              )
                  : results.isEmpty
                  ? const Center(child: Text('No results yet'))
                  : ListView.builder(
                itemCount: results.length,
                itemBuilder: (context, index) {
                  return _buildResultCard(results[index], index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

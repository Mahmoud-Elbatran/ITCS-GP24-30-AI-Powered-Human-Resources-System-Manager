import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class ResumeScreeningPage extends StatefulWidget {
  const ResumeScreeningPage({super.key});

  @override
  State<ResumeScreeningPage> createState() => _ResumeScreeningPageState();
}

class _ResumeScreeningPageState extends State<ResumeScreeningPage> {
  final TextEditingController _jobDescController = TextEditingController();
  List<Map<String, dynamic>> resumes = [];

  Future<void> uploadResume() async {
    if (_jobDescController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a job description.')),
      );
      return;
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: kIsWeb,
    );

    if (result != null) {
      String fileName = result.files.single.name;
      Uint8List? fileBytes = result.files.single.bytes;

      if (fileBytes == null && !kIsWeb) {
        final filePath = result.files.single.path!;
        final file = io.File(filePath);
        fileBytes = await file.readAsBytes();
      }

      if (fileBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to read file.')),
        );
        return;
      }

      var uri = Uri.parse('http://10.2.146.52:8000/match-resumes/'); // use your actual IP
      var request = http.MultipartRequest('POST', uri);

      request.files.add(http.MultipartFile.fromBytes('file', fileBytes, filename: fileName));
      request.fields['job_description'] = _jobDescController.text;

      var response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final parsed = json.decode(responseData);

        setState(() {
          resumes.add({
            'name': parsed['filename'] ?? 'Unknown',
            'score': parsed['score'] ?? 0.0,
            'status': 'Pending',
            'role': 'Candidate',
          });

          // Sort resumes by score descending
          resumes.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload successful. Score: ${parsed['score']}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload failed.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No file selected')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Resume Screening")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Enter Job Description:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _jobDescController,
              maxLines: 4,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: "E.g. Looking for a Flutter Developer with API experience...",
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: uploadResume,
              icon: const Icon(Icons.upload),
              label: const Text("Upload Resume & Rank"),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: resumes.isEmpty
                  ? const Center(child: Text("No resumes uploaded yet."))
                  : ListView.builder(
                itemCount: resumes.length,
                itemBuilder: (context, index) {
                  var resume = resumes[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      title: Text(resume['name']),
                      subtitle: Text('Score: ${resume['score']}%'),
                      trailing: Text(resume['status']),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
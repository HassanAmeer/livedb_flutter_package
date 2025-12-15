import 'dart:io';
import 'package:flutter/material.dart';
import 'package:livedb/livedb.dart';

void main() {
  // Initialize with debug logging and local storage
  LiveDB(const LiveDBConfig(enableLogging: true, enableLocalStorage: true));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LiveDB Example',
      theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: true),
      home: const LiveDBExample(),
    );
  }
}

class LiveDBExample extends StatefulWidget {
  const LiveDBExample({super.key});

  @override
  State<LiveDBExample> createState() => _LiveDBExampleState();
}

class _LiveDBExampleState extends State<LiveDBExample> {
  // Main Instance
  final livedb = LiveDB();

  String _status = 'Ready';
  String? _lastLink;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LiveDB Examples')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Status Display
          Card(
            color: Colors.grey.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Status:\n$_status',
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ),
          const SizedBox(height: 30),

          // --- Authentication ---
          const _SectionHeader('1. Authentication'),
          _ActionButton(
            label: 'Generate Token',
            onPressed: generateToken,
            color: Colors.blue,
          ),

          const SizedBox(height: 30),

          // --- Storage Examples ---
          const _SectionHeader('2. Cloud Storage'),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _ActionButton(label: 'Upload File', onPressed: uploadFile),
              _ActionButton(label: 'Upload Base64', onPressed: uploadBase64),
              _ActionButton(
                label: 'Delete Last File',
                onPressed: deleteFile,
                color: Colors.red,
                isOutline: true,
              ),
            ],
          ),

          const SizedBox(height: 30),

          // --- Database Examples ---
          const _SectionHeader('3. Cloud Database'),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _ActionButton(label: 'Create Project', onPressed: createProject),
              _ActionButton(label: 'Add Document', onPressed: addDocument),
              _ActionButton(
                label: 'Query Documents',
                onPressed: queryDocuments,
              ),
              _ActionButton(
                label: 'Update Document',
                onPressed: updateDocument,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ====================================================
  //               API IMPLEMENTATION EXAMPLES
  // ====================================================

  /// 1. Generate Token
  Future<void> generateToken() async {
    setStatus('Generating token...');

    // Generates and internally sets the token for future requests
    // Using a fake email for demo
    final success = await livedb.generateAndSetToken('demo_user@example.com');

    if (success) {
      setStatus('Success! Token set automatically.\nToken: ${livedb.token}');
    } else {
      setStatus('Failed to generate token.');
    }
  }

  /// 2. LiveStorage: Upload File
  Future<void> uploadFile() async {
    setStatus('Uploading file...');

    // Create a dummy file
    final file = File('${Directory.systemTemp.path}/demo.txt');
    await file.writeAsString('Hello LiveStorage! Timestamp: ${DateTime.now()}');

    // API Call
    // Use the smart upload wrapper which handles small/large files automatically
    final response = await livedb.upload(
      file,
      folderName: 'demo_uploads',
      onProgress: (progress, sent, total) {
        debugPrint('Progress: ${(progress * 100).toInt()}%');
      },
    );

    if (response.success) {
      _lastLink = response.link;
      setStatus('Uploaded Successfully!\nLink: ${response.link}');
    } else {
      setStatus('Error: ${response.message}');
    }
  }

  /// 3. LiveStorage: Upload Base64
  Future<void> uploadBase64() async {
    setStatus('Uploading Base64...');

    final file = File('${Directory.systemTemp.path}/demo_base64.txt');
    await file.writeAsString('Base64 Content Test');
    final bytes = await file.readAsBytes();

    // API Call
    final response = await livedb.uploadByBase64(
      bytes,
      fileName: 'demo_base64.txt',
      folderName: 'demo_uploads',
    );

    if (response.success) {
      _lastLink = response.link;
      setStatus('Uploaded (Base64)!\nLink: ${response.link}');
    } else {
      setStatus('Error: ${response.message}');
    }
  }

  /// 4. LiveStorage: Delete File
  Future<void> deleteFile() async {
    if (_lastLink == null) {
      setStatus('No link to delete. Please upload a file first.');
      return;
    }

    setStatus('Deleting file...');

    // API Call
    final success = await livedb.storage.deleteFile(_lastLink!);

    if (success) {
      setStatus('File deleted successfully.');
      _lastLink = null;
    } else {
      setStatus('Delete failed.');
    }
  }

  /// 5. LiveDB: Create Project
  Future<void> createProject() async {
    setStatus('Creating project...');

    try {
      // API Call (Fluent API)
      await livedb.db
          .project('my_flutter_app')
          .create(description: 'Created via Flutter Example');

      setStatus('Project "my_flutter_app" created!');
    } catch (e) {
      setStatus('Note: Project likely already exists.\nResponse: $e');
    }
  }

  /// 6. LiveDB: Add Document
  Future<void> addDocument() async {
    setStatus('Adding document...');

    try {
      final docData = {
        'username': 'flutter_dev',
        'score': 100,
        'active': true,
        'created_at': DateTime.now().toIso8601String(),
      };

      // API Call (Fluent API)
      final result = await livedb.db
          .collection('my_flutter_app', 'users')
          .add(docData);

      setStatus('Document Added!\nID: ${result['data']['id']}');
    } catch (e) {
      setStatus('Error adding doc: $e');
    }
  }

  /// 7. LiveDB: Query Documents
  Future<void> queryDocuments() async {
    setStatus('Querying documents...');

    try {
      // API Call (Fluent API)
      final result = await livedb.db
          .collection('my_flutter_app', 'users')
          .get(filters: {'_limit': 5, '_sort': '-created_at'});

      final list = result['data'] as List;
      setStatus('Found ${list.length} documents:\n$list');
    } catch (e) {
      setStatus('Error querying: $e');
    }
  }

  /// 8. LiveDB: Update Document
  Future<void> updateDocument() async {
    setStatus('Updating document...');
    // Note: In a real app, you'd get the ID from the query result.
    // For this example, we'll try to update a hypothetical '1' or you should insert one first.
    // Let's just try to update the "last" one if we can query it first?
    // Or just show the syntax.

    try {
      // Query one first to get an ID
      final query = await livedb.db
          .collection('my_flutter_app', 'users')
          .get(filters: {'_limit': 1});
      final list = query['data'] as List;
      if (list.isEmpty) {
        setStatus('No documents found to update. Add one first.');
        return;
      }

      final id = list.first['id'].toString();

      // API Call (Fluent API)
      await livedb.db.collection('my_flutter_app', 'users').doc(id).update({
        'score': 500,
        'updated': true,
      });

      setStatus('Document $id updated!');
    } catch (e) {
      setStatus('Update failed: $e');
    }
  }

  // UI Helper
  void setStatus(String msg) {
    setState(() => _status = msg);
    debugPrint(msg);
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color? color;
  final bool isOutline;

  const _ActionButton({
    required this.label,
    required this.onPressed,
    this.color,
    this.isOutline = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutline) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: color != null ? BorderSide(color: color!) : null,
        ),
        child: Text(label),
      );
    }
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: color != null ? Colors.white : null,
      ),
      child: Text(label),
    );
  }
}

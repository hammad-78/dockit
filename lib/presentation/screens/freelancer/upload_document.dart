import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UploadDocumentScreen extends StatefulWidget {
  const UploadDocumentScreen({required this.project, super.key});

  final Map<String, dynamic> project;

  @override
  State<UploadDocumentScreen> createState() => _UploadDocumentScreenState();
}

class _UploadDocumentScreenState extends State<UploadDocumentScreen> {
  static const _maxFileSize = 10 * 1024 * 1024;
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  PlatformFile? _selectedFile;
  String? _type;
  bool _isUploading = false;
  bool _isPickingFile = false;

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _chooseFile() async {
    if (_isPickingFile || _isUploading) return;
    setState(() => _isPickingFile = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'png', 'jpg', 'jpeg'],
        withData: true,
      );
      if (!mounted || result == null || result.files.isEmpty) return;

      final file = result.files.single;
      if (file.size > _maxFileSize) {
        _showMessage('Files must be 10 MB or smaller.');
        return;
      }
      if (file.bytes == null) {
        _showMessage('Could not read the selected file. Try again.');
        return;
      }
      setState(() {
        _selectedFile = file;
        _titleController.text = _titleController.text.trim().isEmpty
            ? _withoutExtension(file.name)
            : _titleController.text;
        _type ??= _typeFromName(file.name);
      });
    } on PlatformException catch (error) {
      if (mounted) {
        _showMessage(
          error.message ?? 'The file picker could not be opened. Try again.',
        );
      }
    } catch (_) {
      if (mounted) {
        _showMessage(
          'The file picker is not available in this app build. '
          'Stop the app and run it again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isPickingFile = false);
    }
  }

  Future<void> _upload() async {
    final path = widget.project['path'] as String?;
    final file = _selectedFile;
    final title = _titleController.text.trim();
    if (_isUploading) return;
    if (path == null || path.isEmpty) {
      _showMessage('This project cannot accept documents yet.');
      return;
    }
    if (file == null || file.bytes == null) {
      _showMessage('Choose a file to upload.');
      return;
    }
    if (file.size > _maxFileSize) {
      _showMessage('Files must be 10 MB or smaller.');
      return;
    }
    if (title.isEmpty || _type == null) {
      _showMessage('Add a title and choose a document type.');
      return;
    }

    setState(() => _isUploading = true);
    try {
      final documents = FirebaseFirestore.instance
          .doc(path)
          .collection('documents');
      final documentKey = _normaliseTitle(title);
      final existing = await documents
          .where('documentKey', isEqualTo: documentKey)
          .get();
      final version =
          existing.docs.fold<int>(0, (highest, document) {
            final current = (document.data()['version'] as num?)?.toInt() ?? 0;
            return current > highest ? current : highest;
          }) +
          1;
      final documentReference = documents.doc();
      final storagePath =
          '$path/documents/${documentReference.id}/${file.name}';
      final storageReference = FirebaseStorage.instance.ref(storagePath);
      final uploadTask = await storageReference.putData(
        file.bytes!,
        SettableMetadata(contentType: _contentType(file.name)),
      );
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      final user = FirebaseAuth.instance.currentUser;

      await documentReference.set({
        'title': title,
        'documentKey': documentKey,
        'type': _type,
        'note': _noteController.text.trim(),
        'version': version,
        'fileName': file.name,
        'sizeBytes': file.size,
        'storagePath': storagePath,
        'downloadUrl': downloadUrl,
        'ownerId': user?.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.of(context).pop();
    } on FirebaseException catch (error) {
      if (!mounted) return;
      _showMessage(
        error.code == 'permission-denied'
            ? 'You do not have permission to upload here.'
            : 'Could not upload the document. Try again.',
      );
    } catch (_) {
      if (mounted) _showMessage('Could not upload the document. Try again.');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFAF9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCFAF9),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Upload Document',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(30, 32, 30, 24),
          children: [
            const Text(
              'Upload document',
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 38),
            _filePicker(),
            const SizedBox(height: 30),
            _label('Title'),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: _inputDecoration('e.g. Service contract v2'),
            ),
            const SizedBox(height: 28),
            _label('Type'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: _inputDecoration('Select document type'),
              items: const [
                DropdownMenuItem(value: 'Contract', child: Text('Contract')),
                DropdownMenuItem(value: 'Design', child: Text('Design')),
                DropdownMenuItem(value: 'Invoice', child: Text('Invoice')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: (value) => setState(() => _type = value),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _label('Note for client'),
                const Text(
                  '(optional)',
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 4,
              decoration: _inputDecoration(
                'Add context or instructions for review...',
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              height: 58,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _upload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF24446F),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(
                    0xFF24446F,
                  ).withAlpha(150),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isUploading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Send to client',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filePicker() {
    return InkWell(
      onTap: _isPickingFile ? null : _chooseFile,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 274,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: const Color(0xFFE4E1DF),
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_upload_outlined,
              color: Color(0xFF24446F),
              size: 42,
            ),
            const SizedBox(height: 18),
            Text(
              _isPickingFile
                  ? 'Opening file picker...'
                  : _selectedFile?.name ?? 'Choose a file',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _selectedFile == null
                  ? 'PDF, DOCX, PNG, or JPG up to 10 MB'
                  : _formatSize(_selectedFile!.size),
              style: const TextStyle(color: Colors.black54, fontSize: 17),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.black54,
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black87, fontSize: 19),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE4E1DF)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE4E1DF)),
      ),
    );
  }

  String _withoutExtension(String name) {
    final dot = name.lastIndexOf('.');
    return dot <= 0 ? name : name.substring(0, dot);
  }

  String _typeFromName(String name) {
    final extension = name.split('.').last.toLowerCase();
    if (extension == 'pdf' || extension == 'doc' || extension == 'docx') {
      return 'Contract';
    }
    if (extension == 'png' || extension == 'jpg' || extension == 'jpeg') {
      return 'Design';
    }
    return 'Other';
  }

  String _normaliseTitle(String title) => title
      .trim()
      .toLowerCase()
      .replaceFirst(RegExp(r'\s+v\d+$'), '')
      .replaceAll(RegExp(r'\s+'), ' ');

  String _contentType(String name) {
    final extension = name.split('.').last.toLowerCase();
    return switch (extension) {
      'pdf' => 'application/pdf',
      'doc' => 'application/msword',
      'docx' =>
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      _ => 'application/octet-stream',
    };
  }

  String _formatSize(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).ceil()} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

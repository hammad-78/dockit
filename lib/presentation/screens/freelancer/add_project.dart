import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

final _db = FirebaseFirestore.instance;
final _auth = FirebaseAuth.instance;

/// Creates projects/{email}/userProjects/{autoId}. Returns the project path.
Future<String> createProject({
  required String name,
  String? description,
}) async {
  final user = _auth.currentUser;
  final email = user?.email?.toLowerCase();
  if (user == null || email == null) {
    throw StateError('Signed-in user has no email');
  }
  final cleanName = name.trim();
  if (cleanName.isEmpty) throw ArgumentError('Project name is required');

  final userRef = _db.collection('projects').doc(email);
  final projectRef = userRef.collection('userProjects').doc();

  final batch = _db.batch();
  // Real parent doc, so the email shows up when listing `projects`
  batch.set(
    userRef,
    {'email': email, 'uid': user.uid, 'updatedAt': FieldValue.serverTimestamp()},
    SetOptions(merge: true),
  );
  batch.set(projectRef, {
    'ownerId': user.uid,
    'ownerEmail': email,
    'name': cleanName,
    'description': (description ?? '').trim(),
    'status': 'active',
    'projectID': projectRef.id,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });
  await batch.commit();
  return projectRef.path; // projects/a@b.com/userProjects/{id}
}

class NewProjectScreen extends StatefulWidget {
  const NewProjectScreen({super.key});

  @override
  State<NewProjectScreen> createState() => _NewProjectScreenState();
}

class _NewProjectScreenState extends State<NewProjectScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _isSaving = false;

Future<void> _submit() async {
  final name = _nameController.text.trim();
  if (name.isEmpty || _isSaving) return;

  setState(() => _isSaving = true);
  try {
    final id = await createProject(
      name: name,
      description: _descriptionController.text,
    );
    if (!mounted) return;
    Navigator.of(context).pop(id);
  } on StateError catch (e) {
    _fail(e.message);
  } on ArgumentError catch (e) {
    _fail(e.message?.toString() ?? 'Invalid project name');
  } on FirebaseException catch (e) {
    _fail(e.code == 'permission-denied'
        ? 'Permission denied. Check your Firestore rules.'
        : 'Could not create project. Try again.');
  } catch (_) {
    _fail('Could not create project. Try again.');
  }
}

void _fail(String message) {
  if (!mounted) return;
  setState(() => _isSaving = false);
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));
}

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Screen Title
              const Text(
                'New project',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 32),
              
              // Project Name Section
              const Text(
                'Project name',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'e.g. Brand Identity',
                  hintStyle: TextStyle(color: Colors.black.withAlpha(153)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.black, width: 1),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Description Section
              const Text(
                'Description (optional)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Add a brief overview of deliverables and goals',
                  hintStyle: TextStyle(color: Colors.black.withAlpha(153)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.black, width: 1),
                  ),
                ),
              ),
              
              const Spacer(), // Pushes the button to the bottom
              
              // Create Project Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
  onPressed: _isSaving ? null : _submit,
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFF1D3557),
    disabledBackgroundColor: const Color(0xFF1D3557).withAlpha(153),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    elevation: 0,
  ),
  child: _isSaving
      ? const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        )
      : const Text(
          'Create project',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
),
              ),
              const SizedBox(height: 16), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }
}

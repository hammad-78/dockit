import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dockit/presentation/screens/profile.dart';
import 'package:dockit/presentation/screens/freelancer/upload_document.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProjectDetailsScreen extends StatefulWidget {
  const ProjectDetailsScreen({required this.project, super.key});

  final Map<String, dynamic> project;

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  late Map<String, dynamic> _project;
  bool _isGeneratingKey = false;

  Map<String, dynamic> get project => _project;
  String get _title => project['title'] as String? ?? 'Untitled project';
  String get _client => project['client'] as String? ?? 'No client yet';
  String get _description => project['description'] as String? ?? '';
  String get _status => project['status'] as String? ?? 'active';
  String get _formattedStatus => _status.isEmpty
      ? 'Unknown'
      : '${_status[0].toUpperCase()}${_status.substring(1)}';
  String? get _clientKey => project['clientKey'] as String?;

  @override
  void initState() {
    super.initState();
    _project = Map<String, dynamic>.from(widget.project);
  }

  String get _updatedLabel {
    final updatedAt = project['updatedAt'];
    if (updatedAt is Timestamp) {
      final difference = DateTime.now().difference(updatedAt.toDate());
      if (difference.inMinutes < 1) return 'Updated just now';
      if (difference.inHours < 1) {
        return 'Updated ${difference.inMinutes}m ago';
      }
      if (difference.inDays < 1) return 'Updated ${difference.inHours}h ago';
      return 'Updated ${difference.inDays}d ago';
    }
    return 'Updated recently';
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
          'Project Details',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF0A2C50),
              child: IconButton(
                icon: const Icon(Icons.person_outline, color: Colors.white),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(30, 20, 30, 24),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ACTIVE PROJECT',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.1,
                  ),
                ),
                Text(
                  _updatedLabel,
                  style: const TextStyle(color: Colors.black54, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _title,
              style: const TextStyle(
                fontSize: 34,
                height: 1.1,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _description.isEmpty
                  ? (_status == 'active'
                        ? 'This project is currently active.'
                        : 'Project status: $_status')
                  : _description,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 18,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 28),
            _summaryCard(),
            const SizedBox(height: 28),
            const _DetailsTabs(),
            const SizedBox(height: 30),
            _documentsSection(),
            const SizedBox(height: 28),
            _auditCard(),
            const SizedBox(height: 48),
            OutlinedButton.icon(
              onPressed: _isGeneratingKey ? null : _openInviteDialog,
              icon: const Icon(Icons.key_outlined),
              label: Text(
                _clientKey == null
                    ? 'Generate client key'
                    : 'Manage client key',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF24446F),
                side: const BorderSide(color: Color(0xFF24446F)),
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 58,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => UploadDocumentScreen(project: project),
                    ),
                  );
                },
                icon: const Icon(Icons.add, size: 25),
                label: const Text(
                  'Add document',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF24446F),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _documentsSection() {
    final path = project['path'] as String?;
    if (path == null || path.isEmpty) {
      return _documentsContent(const []);
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .doc(path)
          .collection('documents')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Could not load documents.');
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final latest = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
        for (final document in snapshot.data!.docs) {
          final data = document.data();
          final documentKey = data['documentKey'] as String? ?? document.id;
          final current = latest[documentKey];
          final version = (data['version'] as num?)?.toInt() ?? 1;
          final currentVersion =
              (current?.data()['version'] as num?)?.toInt() ?? 0;
          if (current == null || version > currentVersion) {
            latest[documentKey] = document;
          }
        }
        return _documentsContent(latest.values.toList());
      },
    );
  }

  Widget _documentsContent(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Shared deliverables',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${documents.length} ${documents.length == 1 ? 'file' : 'files'}',
              style: const TextStyle(color: Colors.black54, fontSize: 15),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (documents.isEmpty)
          _deliverablesCard()
        else
          _documentsCard(documents),
      ],
    );
  }

  Widget _documentsCard(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE4E1DF)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          for (var index = 0; index < documents.length; index++) ...[
            _documentTile(documents[index].data()),
            if (index < documents.length - 1)
              const Divider(height: 1, color: Color(0xFFE4E1DF)),
          ],
        ],
      ),
    );
  }

  Widget _documentTile(Map<String, dynamic> document) {
    final version = (document['version'] as num?)?.toInt() ?? 1;
    final type = document['type'] as String? ?? 'Document';
    final name = document['title'] as String? ?? 'Untitled document';
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: const Icon(
        Icons.description_outlined,
        color: Colors.black54,
        size: 30,
      ),
      title: Text(name, style: const TextStyle(fontSize: 17)),
      subtitle: Text('$type, v$version'),
      trailing: const Icon(Icons.chevron_right, color: Colors.black45),
      onTap: () {},
    );
  }

  Future<void> _openInviteDialog() async {
    final settings = await showDialog<_InviteSettings>(
      context: context,
      builder: (_) => const _InviteClientsDialog(),
    );
    if (settings == null || !mounted) return;

    final path = project['path'] as String?;
    if (path == null || path.isEmpty) {
      _showMessage('This project cannot generate a key yet.');
      return;
    }

    setState(() => _isGeneratingKey = true);
    final key = _createKey();
    final expiresAt = DateTime.now().add(Duration(days: settings.validDays));
    try {
      await FirebaseFirestore.instance.doc(path).update({
        'clientKey': key,
        'keyCreatedAt': FieldValue.serverTimestamp(),
        'keyExpiresAt': Timestamp.fromDate(expiresAt),
        'memberLimit': settings.memberLimit,
        'joinedMembers': 0,
      });
      if (!mounted) return;
      setState(() {
        _project = {
          ..._project,
          'clientKey': key,
          'keyExpiresAt': Timestamp.fromDate(expiresAt),
          'memberLimit': settings.memberLimit,
          'joinedMembers': 0,
        };
        _isGeneratingKey = false;
      });
      await _showGeneratedKeyDialog(key, settings, expiresAt);
    } on FirebaseException catch (error) {
      if (!mounted) return;
      setState(() => _isGeneratingKey = false);
      _showMessage(
        error.code == 'permission-denied'
            ? 'You do not have permission to generate a key.'
            : 'Could not generate the key. Try again.',
      );
    }
  }

  String _createKey() {
    const characters = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    String segment() => List.generate(
      4,
      (_) => characters[random.nextInt(characters.length)],
    ).join();
    return 'DCK-${segment()}-${segment()}';
  }

  Future<void> _showGeneratedKeyDialog(
    String key,
    _InviteSettings settings,
    DateTime expiresAt,
  ) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _GeneratedKeyDialog(
        keyValue: key,
        validDays: settings.validDays,
        memberLimit: settings.memberLimit,
        expiresAt: expiresAt,
        onRevoke: _revokeKey,
      ),
    );
  }

  Future<void> _revokeKey() async {
    final path = project['path'] as String?;
    if (path == null) return;
    try {
      await FirebaseFirestore.instance.doc(path).update({
        'clientKey': FieldValue.delete(),
        'keyCreatedAt': FieldValue.delete(),
        'keyExpiresAt': FieldValue.delete(),
        'memberLimit': FieldValue.delete(),
        'joinedMembers': FieldValue.delete(),
      });
    } on FirebaseException catch (error) {
      if (mounted) {
        _showMessage(
          error.code == 'permission-denied'
              ? 'You do not have permission to revoke this key.'
              : 'Could not revoke the key. Try again.',
        );
      }
      return;
    }
    if (!mounted) return;
    setState(() {
      _project = {..._project}
        ..removeWhere(
          (key, _) => [
            'clientKey',
            'keyCreatedAt',
            'keyExpiresAt',
            'memberLimit',
            'joinedMembers',
          ].contains(key),
        );
    });
    Navigator.of(context).pop();
    _showMessage('Client key revoked.');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _summaryCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE4E1DF)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(child: _summaryValue('Client stakeholder', _client)),
          Container(width: 1, height: 58, color: const Color(0xFFE4E1DF)),
          Expanded(child: _summaryValue('Project status', _formattedStatus)),
        ],
      ),
    );
  }

  Widget _summaryValue(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 19),
          ),
        ],
      ),
    );
  }

  Widget _deliverablesCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE4E1DF)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F7F5),
              border: Border.all(color: const Color(0xFFE4E1DF)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.description_outlined,
              color: Colors.black54,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'No documents shared yet',
              style: TextStyle(fontSize: 17, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _auditCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE4E1DF)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.schedule, color: Colors.black54, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _description.isEmpty
                  ? 'Project activity and audit notes will appear here.'
                  : _description,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 17,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InviteSettings {
  const _InviteSettings({required this.validDays, required this.memberLimit});

  final int validDays;
  final int memberLimit;
}

class _InviteClientsDialog extends StatefulWidget {
  const _InviteClientsDialog();

  @override
  State<_InviteClientsDialog> createState() => _InviteClientsDialogState();
}

class _InviteClientsDialogState extends State<_InviteClientsDialog> {
  int _validDays = 7;
  int _memberLimit = 3;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFFCFAF9),
      title: const Text(
        'Invite clients',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Clients need this key to join the project.',
            style: TextStyle(color: Colors.black54, fontSize: 16),
          ),
          const SizedBox(height: 24),
          const Text(
            'Key valid for',
            style: TextStyle(color: Colors.black54, fontSize: 16),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            initialValue: _validDays,
            decoration: _dialogInputDecoration(),
            items: const [
              DropdownMenuItem(value: 1, child: Text('1 day')),
              DropdownMenuItem(value: 7, child: Text('7 days')),
              DropdownMenuItem(value: 30, child: Text('30 days')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _validDays = value);
            },
          ),
          const SizedBox(height: 20),
          const Text(
            'Number of members',
            style: TextStyle(color: Colors.black54, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE4E1DF)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: _memberLimit > 1
                      ? () => setState(() => _memberLimit--)
                      : null,
                ),
                Text(
                  '$_memberLimit',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _memberLimit < 50
                      ? () => setState(() => _memberLimit++)
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'The key stops working after this time or once the member limit is reached.',
            style: TextStyle(color: Colors.black54, height: 1.4),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      actions: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(
              _InviteSettings(validDays: _validDays, memberLimit: _memberLimit),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF24446F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Generate key',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _dialogInputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE4E1DF)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE4E1DF)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}

class _GeneratedKeyDialog extends StatelessWidget {
  const _GeneratedKeyDialog({
    required this.keyValue,
    required this.validDays,
    required this.memberLimit,
    required this.expiresAt,
    required this.onRevoke,
  });

  final String keyValue;
  final int validDays;
  final int memberLimit;
  final DateTime expiresAt;
  final Future<void> Function() onRevoke;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFFCFAF9),
      title: const Text(
        'Your client key',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  keyValue,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Expires in $validDays ${validDays == 1 ? 'day' : 'days'}',
                  style: const TextStyle(color: Colors.black54, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  '0 of $memberLimit members joined',
                  style: const TextStyle(color: Colors.black54, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  '${expiresAt.day}/${expiresAt.month}/${expiresAt.year}',
                  style: const TextStyle(color: Colors.black45, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: keyValue));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Key copied.')),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy_outlined),
                  label: const Text('Copy key'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: keyValue));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Key copied. Share it with your client.',
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Share'),
                ),
              ),
            ],
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      actions: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF24446F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Done',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        TextButton(
          onPressed: onRevoke,
          child: const Text(
            'Revoke key',
            style: TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      ],
    );
  }
}

class _DetailsTabs extends StatelessWidget {
  const _DetailsTabs();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 14),
          child: Text(
            'Documents',
            style: TextStyle(
              color: Color(0xFF24446F),
              fontSize: 23,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(width: 46),
        Padding(
          padding: EdgeInsets.only(bottom: 14),
          child: Text(
            'Members',
            style: TextStyle(color: Colors.black54, fontSize: 23),
          ),
        ),
      ],
    );
  }
}

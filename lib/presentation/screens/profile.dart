import 'package:dockit/presentation/auth/auth_service.dart';
import 'package:dockit/presentation/screens/login_screen.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final Future<Map<String, dynamic>?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
  }

  Future<Map<String, dynamic>?> _loadProfile() {
    return AuthService().getCurrentUserInfo();
  }

  void _refreshProfile() {
    setState(() {
      _profileFuture = _loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>?>(
    future: _profileFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      if (snapshot.hasError || snapshot.data == null) {
        return Scaffold(
          body: Center(
            child: Text(
              'Unable to load your profile.',
              style: TextStyle(color: AppColors.muted),
            ),
          ),
        );
      }

      return _ProfileContent(
        profile: snapshot.data!,
        onProfileUpdated: _refreshProfile,
      );
    },
  );
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.profile,
    required this.onProfileUpdated,
  });

  final Map<String, dynamic> profile;
  final VoidCallback onProfileUpdated;

  String get name {
    final value = profile['name'];
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return 'Dockit user';
  }

  String get email => profile['email'] as String? ?? '';

  String get role {
    final value = profile['role'] as String? ?? 'user';
    return value[0].toUpperCase() + value.substring(1);
  }

  String get initials {
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isFreelancer = role.toLowerCase() == 'freelancer';

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(30, 18, 30, 12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.navyDark,
                    child: const Icon(
                      Icons.person_outline,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 42),
              CircleAvatar(
                radius: 48,
                backgroundColor: const Color(0xFFF0EEEE),
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                email,
                style: const TextStyle(fontSize: 21, color: AppColors.muted),
              ),
              const SizedBox(height: 8),
              Text(
                role,
                style: const TextStyle(fontSize: 18, color: AppColors.muted),
              ),
              const SizedBox(height: 50),
              _sectionTitle('Account settings'),
              _settingsCard([
                _SettingsRow(
                  label: 'Edit name',
                  onTap: () => _editName(context),
                ),
                _SettingsRow(
                  label: 'Change password',
                  onTap: () => _changePassword(context),
                ),
                _SettingsRow(
                  label: 'Log out',
                  color: AppColors.danger,
                  onTap: () => _logOut(context),
                ),
              ]),
              const SizedBox(height: 48),
              _sectionTitle('Preferences'),
              _settingsCard([
                _SettingsRow(label: 'Notifications', onTap: () {}),
                _SettingsRow(
                  label: '${isFreelancer ? 'Freelancer' : 'Client'} portal URL',
                  subtitle:
                      'dockit.app/${name.toLowerCase().replaceAll(' ', '-')}',
                  trailing: Icons.copy_outlined,
                  onTap: () {},
                ),
              ]),
              const SizedBox(height: 72),
              const Text(
                'Version 1.0.4 · Dockit',
                style: TextStyle(fontSize: 16, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) Navigator.of(context).pop();
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_open_outlined),
            label: 'Projects',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Future<void> _logOut(BuildContext context) async {
    await AuthService().signOutUser();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _editName(BuildContext context) async {
    final newName = await showDialog<String>(
      context: context,
      builder: (_) => _EditNameDialog(initialName: name),
    );
    if (newName == null || !context.mounted) return;

    try {
      await AuthService().updateUserName(newName);
      if (!context.mounted) return;
      onProfileUpdated();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name updated successfully.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      _showActionError(context, error);
    }
  }

  Future<void> _changePassword(BuildContext context) async {
    final newPassword = await showDialog<String>(
      context: context,
      builder: (_) => const _ChangePasswordDialog(),
    );
    if (newPassword == null || !context.mounted) return;

    try {
      await AuthService().changePassword(newPassword);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      _showActionError(context, error);
    }
  }

  void _showActionError(BuildContext context, Object error) {
    final message = error is ArgumentError || error is StateError
        ? error.toString().split(': ').last
        : 'Unable to update your profile. Please try again.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _sectionTitle(String title) => Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 14),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, color: AppColors.muted),
      ),
    ),
  );

  Widget _settingsCard(List<_SettingsRow> rows) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      children: [
        for (var index = 0; index < rows.length; index++) ...[
          rows[index],
          if (index < rows.length - 1)
            const Divider(height: 1, indent: 24, endIndent: 0),
        ],
      ],
    ),
  );
}

class _EditNameDialog extends StatefulWidget {
  const _EditNameDialog({required this.initialName});

  final String initialName;

  @override
  State<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<_EditNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Edit name'),
    content: TextField(
      controller: _controller,
      autofocus: true,
      textCapitalization: TextCapitalization.words,
      decoration: const InputDecoration(labelText: 'Name'),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, _controller.text),
        child: const Text('Save'),
      ),
    ],
  );
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Change password'),
    content: TextField(
      controller: _controller,
      autofocus: true,
      obscureText: true,
      decoration: const InputDecoration(
        labelText: 'New password',
        hintText: 'At least 6 characters',
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, _controller.text),
        child: const Text('Update'),
      ),
    ],
  );
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.label,
    required this.onTap,
    this.subtitle,
    this.trailing = Icons.chevron_right,
    this.color = AppColors.ink,
  });

  final String label;
  final String? subtitle;
  final IconData trailing;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 20, 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 21, color: color)),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(trailing, color: color, size: 28),
        ],
      ),
    ),
  );
}

import 'package:dockit/presentation/auth/auth_service.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'auth_ui.dart';
import 'client/client_home.dart';
import 'freelancer/freelancer_home.dart';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool obscurePassword = true;
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  List<bool> _isSelected = [true, false];

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AuthScaffold(
    title: 'Create your account',
    child: ListView(
      children: [
        const Text(
          'Dockit - Manage your projects and tasks with ease.',
          style: TextStyle(fontSize: 19, color: AppColors.muted),
        ),
        const SizedBox(height: 46),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Text(
            'G',
            style: TextStyle(
              fontSize: 20,
              color: Colors.blue,
              fontWeight: FontWeight.w700,
            ),
          ),
          label: const Text(
            'Continue with Google',
            style: TextStyle(fontSize: 17),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(58),
          ),
        ),
        const SizedBox(height: 26),
        const Center(
          child: Text('or', style: TextStyle(color: AppColors.muted)),
        ),
        const SizedBox(height: 28),
        const AuthFieldLabel('Name'),
        TextField(
          controller: nameController,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(hintText: 'Your full name'),
        ),
        const SizedBox(height: 22),
        const AuthFieldLabel('Email'),
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(hintText: 'name@example.com'),
        ),
        const SizedBox(height: 22),
        const AuthFieldLabel('Password'),
        TextField(
          controller: passwordController,
          obscureText: obscurePassword,
          decoration: InputDecoration(
            hintText: 'Enter your password',
            suffixIcon: IconButton(
              onPressed: () =>
                  setState(() => obscurePassword = !obscurePassword),
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
        ),

        // ...existing code...
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final colorScheme = Theme.of(context).colorScheme;

            return SizedBox(
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: colorScheme.outline),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: List.generate(2, (index) {
                      final isSelected = _isSelected[index];
                      final label = index == 0 ? 'Freelancer' : 'Client';

                      return Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              for (var i = 0; i < _isSelected.length; i++) {
                                _isSelected[i] = i == index;
                              }
                            });
                          },
                          child: Container(
                            height: 50,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.navy
                                  : Colors.transparent,
                              border: index == 0
                                  ? Border(
                                      right: BorderSide(
                                        color: colorScheme.outline,
                                      ),
                                    )
                                  : null,
                            ),
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 16,
                                color: isSelected
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 30),

        // ...existing code...
        SizedBox(height: 30),
        AuthPrimaryButton(
          label: 'Create account',
          onPressed: () {
            final selectedRole = _isSelected[0] ? 'freelancer' : 'client';

            AuthService()
                .signUpWithEmailAndPassword(
                  nameController.text,
                  emailController.text,
                  passwordController.text,
                  selectedRole,
                )
                .then((user) {
                  if (!context.mounted) return;
                  if (user != null) {
                    final destination = selectedRole == 'freelancer'
                        ? const FreelancerHome()
                        : const ClientHome();

                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => destination),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Signup failed. Please try again.'),
                      ),
                    );
                  }
                });
          },
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            child: const Text(
              'Already have an account? Log in',
              style: TextStyle(color: AppColors.navy, fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'By continuing you agree to the Terms and Privacy Policy.',
          style: TextStyle(color: AppColors.muted, fontSize: 14, height: 1.5),
        ),
      ],
    ),
  );
}

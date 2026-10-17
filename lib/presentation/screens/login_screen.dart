import 'package:dockit/presentation/auth/auth_service.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'auth_ui.dart';
import 'client/client_home.dart';
import 'freelancer/freelancer_home.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AuthScaffold(
    title: 'Welcome back',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
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
        const SizedBox(height: 25),
        const Center(
          child: Text('or', style: TextStyle(color: AppColors.muted)),
        ),
        const SizedBox(height: 25),
        const AuthFieldLabel('Email'),
        TextField(
          controller: emailController,
          decoration: InputDecoration(hintText: 'sara@example.com'),
        ),
        const SizedBox(height: 22),
        const AuthFieldLabel('Password'),
        TextField(
          controller: passwordController,
          obscureText: true,
          decoration: InputDecoration(
            hintText: 'Enter your password',
            suffixIcon: Icon(Icons.visibility_outlined),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {},
            child: const Text(
              'Forgot password?',
              style: TextStyle(color: AppColors.ink),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: AuthPrimaryButton(
            label: "Login",
            onPressed: () {
              AuthService.signInWithEmailAndPassword(
                    emailController.text,
                    passwordController.text,
                  )
                  .then((user) {
                    if (user != null && context.mounted) {
                      final destination = user.role == 'freelancer'
                          ? const FreelancerHome()
                          : const ClientHome();

                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => destination),
                      );
                    }
                  })
                  .catchError((error) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Login failed: $error')),
                    );
                  });
            },
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: TextButton(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SignUpScreen())),
            child: const Text(
              "Don't have an account? Sign up",
              style: TextStyle(fontSize: 16, color: AppColors.ink),
            ),
          ),
        ),
      ],
    ),
  );
}

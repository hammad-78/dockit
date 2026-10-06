part of 'screens.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool obscurePassword = true;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
    title: 'Create your account',
    child: ListView(
      children: [
        const Text(
          'Join ll-council to review decisions and records.',
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
        const FieldLabel('Email'),
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(hintText: 'name@example.com'),
        ),
        const SizedBox(height: 22),
        const FieldLabel('Password'),
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
        const SizedBox(height: 30),
        PrimaryButton(label: 'Create account', onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: (){
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

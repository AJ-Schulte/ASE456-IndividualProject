import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:deck_builder/data/util/api.dart';
import 'package:deck_builder/data/util/user_provider.dart';
import 'package:deck_builder/data/model/user.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final APIRunner api = APIRunner();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  bool loading = false;
  bool isSignup = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => loading = true);
    print('Attempting login with: ${usernameController.text.trim()} / ${passwordController.text.trim()}');

    try {
      final data = await api.login(
        usernameController.text.trim(),
        passwordController.text.trim(),
      );

      final record = data['record'] as Map<String, dynamic>;
      final user = User.fromJson(record);

      context.read<UserProvider>().setUser(user);

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $e')),
        );
      }
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => loading = true);

    try {
      final record = await api.signup(usernameController.text.trim(), emailController.text.trim(), passwordController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created! Please log in.')),
        );
        setState(() => isSignup = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Signup failed: $e')),
        );
      }
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isSignup ? 'Sign Up' : 'Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSignup) ...[
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) => v == null || v.isEmpty
                      ? 'Please enter your email'
                      : null,
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Please enter your username' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Please enter your password' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: loading
                    ? null
                    : isSignup
                        ? _signup
                        : _login,
                child: loading
                    ? const CircularProgressIndicator()
                    : Text(isSignup ? 'Create Account' : 'Login'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() => isSignup = !isSignup),
                child: Text(isSignup
                    ? 'Already have an account? Log in'
                    : 'No account? Sign up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

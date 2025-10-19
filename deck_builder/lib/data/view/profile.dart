import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:deck_builder/data/util/api.dart';
import 'package:deck_builder/data/util/user_provider.dart';
import 'package:deck_builder/data/model/user.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final APIRunner api = APIRunner();
  late TextEditingController usernameController;
  late TextEditingController emailController;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProvider>().currentUser!;
    usernameController = TextEditingController(text: user.username);
    emailController = TextEditingController(text: user.email);
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => loading = true);

    try {
      final userProvider = context.read<UserProvider>();
      final user = userProvider.currentUser!;

      final updates = {
        'username': usernameController.text.trim(),
        'email': emailController.text.trim(),
      };

      final updated = await api.updateUser(user.id, updates);

      userProvider.setUser(updated);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sign Out')),
        ],
      ),
    );

    if (confirmed == true) {
      context.read<UserProvider>().logout();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No user data. Please log in.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Username cannot be empty' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Email cannot be empty' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: loading ? null : _updateProfile,
                child: loading
                    ? const CircularProgressIndicator()
                    : const Text('Update Profile'),
              ),
              const SizedBox(height: 24),
              const Divider(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                onPressed: _logout,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

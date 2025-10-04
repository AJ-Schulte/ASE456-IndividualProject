import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:deck_builder/data/util/user_provider.dart';
import 'package:deck_builder/data/util/api.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController usernameController;
  late TextEditingController passwordController;
  bool passwordVisible = false; 

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProvider>().currentUser!;
    usernameController = TextEditingController(text: user['username']);
    passwordController = TextEditingController(text: user['password']);
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final apiRunner = APIRunner();
    final email = userProvider.currentUser?['email'] ?? "";

    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: usernameController,
                decoration: InputDecoration(labelText: 'Username'),
                validator: (value) =>
                    value!.isEmpty ? 'Username cannot be empty' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: passwordController,
                obscureText: !passwordVisible,
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      passwordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        passwordVisible = !passwordVisible;
                      });
                    },
                  ),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Password cannot be empty' : null,
              ),
              const SizedBox(height: 12),
              Text('Email: $email'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final oldUsername =
                        userProvider.currentUser?['username'] ?? '';
                    final updates = {
                      'username': usernameController.text.trim(),
                      'password': passwordController.text.trim(),
                    };

                    final updatedUser = await apiRunner.updateUser(oldUsername, updates);
                    if (updatedUser != null) {
                      userProvider.setUser(updatedUser);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profile updated successfully')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to update profile')),
                      );
                    }
                  }
                },
                child: const Text('Update Profile'),
              ),
              const SizedBox(height: 24),
              Divider(),
              const SizedBox(height: 12),
              Center(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                  onPressed: () async {
                    final shouldLogout = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirm Sign Out'),
                        content: const Text(
                            'Are you sure you want to sign out?'),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(context, false), 
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(context, true), 
                            child: const Text('Sign Out'),
                          ),
                        ],
                      ),
                    );

                    if (shouldLogout == true) {
                      userProvider.logout(); 
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/home', 
                        (r)=>false
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

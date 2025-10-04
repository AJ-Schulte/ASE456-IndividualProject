import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:deck_builder/data/util/user_provider.dart';

class LoginPage extends StatefulWidget {
  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  bool isLogin = true;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(isLogin ? "Login" : "Sign Up"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: usernameController,
                decoration: InputDecoration(labelText: "Username"),
                validator: (value) =>
                    value!.isEmpty ? "Please enter your username" : null,
              ),

              if (!isLogin) ...[
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: "Email"),
                  validator: (value) =>
                      value!.isEmpty ? "Please enter your email" : null,
                ),
                SizedBox(height: 12),
              ],

              TextFormField(
                controller: passwordController,
                decoration: InputDecoration(labelText: "Password"),
                obscureText: true,
                validator: (value) =>
                    value!.isEmpty ? "Please enter your password" : null,
              ),

              if (!isLogin) ...[
                SizedBox(height: 12),
                TextFormField(
                  controller: confirmPasswordController,
                  decoration: InputDecoration(labelText: "Confirm Password"),
                  obscureText: true,
                  validator: (value) =>
                      value != passwordController.text ? "Passwords don't match" : null,
                ),
              ],

              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    bool success = false;

                    if (isLogin) {
                      success = await userProvider.login(
                        usernameController.text.trim(),
                        passwordController.text.trim(),
                      );
                    } else {
                      success = await userProvider.signup(
                        usernameController.text.trim(),
                        passwordController.text.trim(),
                        emailController.text.trim(),
                      );
                    }

                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(isLogin ? "Login successful!" : "Signup successful!")),
                      );
                      Navigator.pushNamedAndRemoveUntil(context, '/home', (r)=>false);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(isLogin ? "Login failed" : "Signup failed")),
                      );
                    }
                  }
                },
                child: Text(isLogin ? "Login" : "Sign Up"),
              ),

              TextButton(
                onPressed: () => setState(() => isLogin = !isLogin),
                child: Text(isLogin
                    ? "Don't have an account? Sign up"
                    : "Already have an account? Log in"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

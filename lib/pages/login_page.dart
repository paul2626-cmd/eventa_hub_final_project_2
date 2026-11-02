// lib/pages/login_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../helpers/error_helpers.dart';
import '../strings.dart';
import 'sign_up_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final formKey = GlobalKey<FormState>();
  final emailField = TextEditingController();
  final passwordField = TextEditingController();
  bool isLoading = false;
  bool obscurePassword = true;

  @override
  void dispose() {
    emailField.dispose();
    passwordField.dispose();
    super.dispose();
  }

  Future<void> logIn() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailField.text.trim(),
        password: passwordField.text,
      );
      // The AuthGate in main.dart shows the home screen automatically.
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(readableError(error))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> sendResetEmail() async {
    final resetField = TextEditingController(text: emailField.text.trim());

    final email = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(AppStrings.forgotPassword),
          content: TextField(
            controller: resetField,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: AppStrings.emailLabel),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(AppStrings.no),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, resetField.text.trim()),
              child: const Text(AppStrings.sendResetLink),
            ),
          ],
        );
      },
    );

    if (email == null || email.isEmpty) {
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.resetEmailSent)),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(readableError(error))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Image.asset(
                'assets/images/logo.png',
                height: 150,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.event, size: 72),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.loginTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: emailField,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: AppStrings.emailLabel,
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  // Same rule as sign up: Gmail or a .edu / .edu.ph address.
                  final pattern = RegExp(
                    r'^[\w.+-]+@(gmail\.com|[\w-]+(\.[\w-]+)*\.edu(\.ph)?)$',
                  );
                  if (value == null ||
                      !pattern.hasMatch(value.trim().toLowerCase())) {
                    return AppStrings.invalidEmail;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordField,
                obscureText: obscurePassword,
                decoration: InputDecoration(
                  labelText: AppStrings.passwordLabel,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    tooltip: obscurePassword
                        ? AppStrings.showPassword
                        : AppStrings.hidePassword,
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppStrings.wrongPassword;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isLoading ? null : logIn,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(AppStrings.loginTitle),
              ),
              TextButton(
                onPressed: isLoading ? null : sendResetEmail,
                child: const Text(AppStrings.forgotPassword),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: isLoading
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignUpPage(),
                          ),
                        );
                      },
                child: const Text(AppStrings.noAccount),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

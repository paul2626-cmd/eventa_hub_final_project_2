// lib/pages/sign_up_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../helpers/error_helpers.dart';
import '../strings.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final formKey = GlobalKey<FormState>();
  final nameField = TextEditingController();
  final emailField = TextEditingController();
  final passwordField = TextEditingController();
  final confirmField = TextEditingController();
  bool isLoading = false;
  bool obscurePassword = true;
  bool obscureConfirm = true;

  @override
  void dispose() {
    nameField.dispose();
    emailField.dispose();
    passwordField.dispose();
    confirmField.dispose();
    super.dispose();
  }

  Future<void> createAccount() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailField.text.trim(),
        password: passwordField.text,
      );

      final user = credential.user!;
      await user.updateDisplayName(nameField.text.trim());

      // Profile document for the signed-in student.
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'displayName': nameField.text.trim(),
        'email': emailField.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'reminderLeadMinutes': 60,
      });

      if (mounted) {
        Navigator.pop(context);
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.signUpTitle),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: nameField,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: AppStrings.nameLabel,
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppStrings.nameRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailField,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: AppStrings.emailLabel,
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  // Hardcoded Gmail-only check.
                  final pattern = RegExp(r'^[\w.+-]+@gmail\.com$');
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
                  if (value == null || value.length < 6) {
                    return AppStrings.weakPassword;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmField,
                obscureText: obscureConfirm,
                decoration: InputDecoration(
                  labelText: AppStrings.confirmPasswordLabel,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    tooltip: obscureConfirm
                        ? AppStrings.showPassword
                        : AppStrings.hidePassword,
                    icon: Icon(
                      obscureConfirm
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        obscureConfirm = !obscureConfirm;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value != passwordField.text) {
                    return AppStrings.passwordMismatch;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isLoading ? null : createAccount,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(AppStrings.createAccount),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

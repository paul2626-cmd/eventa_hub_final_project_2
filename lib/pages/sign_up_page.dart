// lib/pages/sign_up_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../helpers/error_helpers.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final formKey = GlobalKey<FormState>();
  final firstNameField = TextEditingController();
  final lastNameField = TextEditingController();
  final studentNumberField = TextEditingController();
  final contactField = TextEditingController();
  final emailField = TextEditingController();
  final passwordField = TextEditingController();
  final confirmField = TextEditingController();
  bool isLoading = false;
  bool obscurePassword = true;
  bool obscureConfirm = true;

  @override
  void dispose() {
    firstNameField.dispose();
    lastNameField.dispose();
    studentNumberField.dispose();
    contactField.dispose();
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

    final firstName = firstNameField.text.trim();
    final lastName = lastNameField.text.trim();
    final fullName = '$firstName $lastName';
    final studentNumber = studentNumberField.text.trim();
    final firestore = FirebaseFirestore.instance;
    User? createdUser;

    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailField.text.trim(),
        password: passwordField.text,
      );
      createdUser = credential.user;
      final uid = credential.user!.uid;

      // One student number can only be used once.
      await firestore.runTransaction((transaction) async {
        final numberDoc = await transaction.get(
          firestore.collection('studentNumbers').doc(studentNumber),
        );
        if (numberDoc.exists) {
          throw Exception('That student number is already registered.');
        }

        transaction.set(firestore.collection('users').doc(uid), {
          'firstName': firstName,
          'lastName': lastName,
          'displayName': fullName,
          'studentNumber': studentNumber,
          'contactNumber': contactField.text.trim(),
          'email': emailField.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'reminderLeadMinutes': 60,
        });
        transaction.set(numberDoc.reference, {
          'uid': uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      await credential.user!.updateDisplayName(fullName);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (error) {
      // Do not leave a half-made account behind.
      if (createdUser != null) {
        try {
          await createdUser.delete();
        } catch (_) {
          // Ignore: the account may already be gone.
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(readableError(error))));
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
      appBar: AppBar(title: const Text('Create account'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: firstNameField,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'First name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter your first name.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: lastNameField,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Last name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter your last name.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: studentNumberField,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: const InputDecoration(
                  labelText: 'Student number',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  // Exactly 10 digits.
                  final pattern = RegExp(r'^\d{10}$');
                  if (value == null || !pattern.hasMatch(value.trim())) {
                    return 'Student number must be exactly 10 digits.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: contactField,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(13),
                ],
                decoration: const InputDecoration(
                  labelText: 'Contact number',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  // 10 to 13 digits.
                  final pattern = RegExp(r'^\d{10,13}$');
                  if (value == null || !pattern.hasMatch(value.trim())) {
                    return 'Contact number must be 10 to 13 digits.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailField,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'School email or Gmail',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'This field is required.';
                  }
                  if (!value.contains('@')) {
                    return 'Enter a valid email.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordField,
                obscureText: obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    tooltip: obscurePassword ? 'Show password' : 'Hide password',
                    icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  // Needs at least one letter and one number.
                  final hasLetter = RegExp(r'[A-Za-z]').hasMatch(value ?? '');
                  final hasNumber = RegExp(r'[0-9]').hasMatch(value ?? '');
                  if (!hasLetter || !hasNumber) {
                    return 'Password must contain a letter and a number.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmField,
                obscureText: obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Confirm password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    tooltip: obscureConfirm ? 'Show password' : 'Hide password',
                    icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        obscureConfirm = !obscureConfirm;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value != passwordField.text) {
                    return 'Passwords do not match.';
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
                    : const Text('Create account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

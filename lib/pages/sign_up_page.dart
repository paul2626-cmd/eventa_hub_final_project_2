// lib/pages/sign_up_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../helpers/error_helpers.dart';
import '../strings.dart';

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
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
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
          throw Exception(AppStrings.studentNumberTaken);
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
                controller: firstNameField,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: AppStrings.firstNameLabel,
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppStrings.firstNameRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: lastNameField,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: AppStrings.lastNameLabel,
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppStrings.lastNameRequired;
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
                  labelText: AppStrings.studentNumberLabel,
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  // Exactly 10 digits.
                  final pattern = RegExp(r'^\d{10}$');
                  if (value == null || !pattern.hasMatch(value.trim())) {
                    return AppStrings.invalidStudentNumber;
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
                  labelText: AppStrings.contactNumberLabel,
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  // 10 to 13 digits.
                  final pattern = RegExp(r'^\d{10,13}$');
                  if (value == null || !pattern.hasMatch(value.trim())) {
                    return AppStrings.invalidContactNumber;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailField,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: AppStrings.schoolEmailLabel,
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  // Gmail or a school address that ends in .edu / .edu.ph.
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
                  // 8+ characters: capital, small, number, special.
                  final pattern = RegExp(
                    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$',
                  );
                  if (value == null || !pattern.hasMatch(value)) {
                    return AppStrings.strongPassword;
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

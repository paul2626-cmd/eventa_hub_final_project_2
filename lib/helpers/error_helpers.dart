// lib/helpers/error_helpers.dart
import 'package:firebase_auth/firebase_auth.dart';

import '../strings.dart';

// Turns Firebase errors into a short sentence a student can understand.
String readableError(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'wrong-password':
      case 'invalid-credential':
        return AppStrings.wrongPassword;
      case 'invalid-email':
        return AppStrings.invalidEmail;
      case 'email-already-in-use':
        return AppStrings.emailInUse;
      case 'weak-password':
        return AppStrings.weakPassword;
      case 'user-not-found':
        return AppStrings.userNotFound;
      case 'network-request-failed':
        return AppStrings.networkError;
      case 'too-many-requests':
        return AppStrings.tooManyRequests;
    }
  }

  if (error is FirebaseException) {
    if (error.code == 'permission-denied') {
      return AppStrings.permissionError;
    }
    if (error.code == 'unavailable' || error.code == 'network-request-failed') {
      return AppStrings.networkError;
    }
  }

  final message = error.toString().replaceFirst('Exception: ', '');
  return message.isEmpty ? AppStrings.somethingWrong : message;
}

// lib/helpers/error_helpers.dart
import 'package:firebase_auth/firebase_auth.dart';


// Turns Firebase errors into a short sentence a student can understand.
String readableError(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'Wrong password. Try again.';
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'email-already-in-use':
        return 'That email is already in use.';
      case 'weak-password':
        return 'Password is too weak. Try a longer one.';
      case 'user-not-found':
        return 'No account found for that email.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
    }
  }

  if (error is FirebaseException) {
    if (error.code == 'permission-denied') {
      return 'You do not have permission to do that.';
    }
    if (error.code == 'unavailable' || error.code == 'network-request-failed') {
      return 'Network error. Check your connection.';
    }
  }

  final message = error.toString().replaceFirst('Exception: ', '');
  return message.isEmpty ? 'Something went wrong. Try again.' : message;
}

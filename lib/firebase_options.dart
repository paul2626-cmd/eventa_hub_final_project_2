// lib/firebase_options.dart
// Generated values from android/app/google-services.json.
// Kept in sync with firebase.json (projectId: my-db-1b4c6).
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for iOS.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCXdfupmVIoKRVOsu2iV2ep6vZTrAx3jKI',
    appId: '1:616388693402:android:328574f5b321b4bd573e23',
    messagingSenderId: '616388693402',
    projectId: 'my-db-1b4c6',
    storageBucket: 'my-db-1b4c6.firebasestorage.app',
  );
}

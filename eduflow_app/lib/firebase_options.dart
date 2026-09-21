import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) throw UnsupportedError('Web not supported');
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError('Platform not supported');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDi9zWxjera2y5dcfmCbi1BOcuqOdrIRJY',
    appId: '1:1022930466247:android:1a52b8f7e3f429dd39d5e2',
    messagingSenderId: '1022930466247',
    projectId: 'eduflow-88537',
    storageBucket: 'eduflow-88537.firebasestorage.app',
  );
}
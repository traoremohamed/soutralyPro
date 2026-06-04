import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions are not configured for web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return ios;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCO5Q6BfrmKly1xAQgxHs4b5ECHi9V9P2E',
    appId: '1:286227810784:android:bb861d4adcc994fc04c385',
    messagingSenderId: '286227810784',
    projectId: 'soutraly-vtc-v2',
    storageBucket: 'soutraly-vtc-v2.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyClMY4N6hZwH8X46Hza0xoZIqDKicHL5O8',
    appId: '1:286227810784:ios:cd637d3090f9474e04c385',
    messagingSenderId: '286227810784',
    projectId: 'soutraly-vtc-v2',
    storageBucket: 'soutraly-vtc-v2.firebasestorage.app',
    iosBundleId: 'com.soutralyvtc.appchaufeur',
  );

}
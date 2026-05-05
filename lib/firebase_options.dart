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
    apiKey: 'AIzaSyAzHM8kymRO1cMM_3wW6Jm3FsHVSjVSXgc',
    appId: '1:915395800328:android:dfd0a04552c6168fdc10bd',
    messagingSenderId: '915395800328',
    projectId: 'soutraly-vtc',
    storageBucket: 'soutraly-vtc.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBuBUBfVhU95Pu6McPVHyBg-OzJ2M0R8Zc',
    appId: '1:915395800328:ios:4a884e7f78a6d52fdc10bd',
    messagingSenderId: '915395800328',
    projectId: 'soutraly-vtc',
    storageBucket: 'soutraly-vtc.firebasestorage.app',
    iosBundleId: 'com.soutralyvtc.appchaufeur',
  );

}
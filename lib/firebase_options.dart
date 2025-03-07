// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD_yBhppVO2L-9earduBf_Knrp95EcK0fE',
    appId: '1:692599636294:web:c6903f13be961b0a116547',
    messagingSenderId: '692599636294',
    projectId: 'frsa2-bc7e9',
    authDomain: 'frsa2-bc7e9.firebaseapp.com',
    storageBucket: 'frsa2-bc7e9.firebasestorage.app',
    measurementId: 'G-93PG8Q836G',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBjqGv43e1cGR8NLAavOz9KzsoCBAOn6Ok',
    appId: '1:692599636294:android:cdd45d8cc0dcdf6d116547',
    messagingSenderId: '692599636294',
    projectId: 'frsa2-bc7e9',
    storageBucket: 'frsa2-bc7e9.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD1b8VXbQJdS2Hv1HNqLUYtV4aeghaMJeI',
    appId: '1:692599636294:ios:74906faf9f3c89d8116547',
    messagingSenderId: '692599636294',
    projectId: 'frsa2-bc7e9',
    storageBucket: 'frsa2-bc7e9.firebasestorage.app',
    iosBundleId: 'com.example.frsa',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyD1b8VXbQJdS2Hv1HNqLUYtV4aeghaMJeI',
    appId: '1:692599636294:ios:74906faf9f3c89d8116547',
    messagingSenderId: '692599636294',
    projectId: 'frsa2-bc7e9',
    storageBucket: 'frsa2-bc7e9.firebasestorage.app',
    iosBundleId: 'com.example.frsa',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyD_yBhppVO2L-9earduBf_Knrp95EcK0fE',
    appId: '1:692599636294:web:4bc274b3dc904f1c116547',
    messagingSenderId: '692599636294',
    projectId: 'frsa2-bc7e9',
    authDomain: 'frsa2-bc7e9.firebaseapp.com',
    storageBucket: 'frsa2-bc7e9.firebasestorage.app',
    measurementId: 'G-Y6BF7Y9QF2',
  );
}

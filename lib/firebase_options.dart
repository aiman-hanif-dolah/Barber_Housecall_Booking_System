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
    apiKey: 'AIzaSyC8WJHOVH4t1mLx1Hr7fl3_uI1gZOMKvrQ',
    appId: '1:48191107498:web:16f7635d8478027d8dbbd3',
    messagingSenderId: '48191107498',
    projectId: 'techventura-fsktm',
    authDomain: 'techventura-fsktm.firebaseapp.com',
    storageBucket: 'techventura-fsktm.firebasestorage.app',
    measurementId: 'G-M95LN8PNY7',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB_1RBhqNfxZBhLfyS5CgHi5tSCq5b-cWw',
    appId: '1:48191107498:android:135e78ac58eeba7d8dbbd3',
    messagingSenderId: '48191107498',
    projectId: 'techventura-fsktm',
    storageBucket: 'techventura-fsktm.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCbaeEyqxbJi2oDwdrOEb1ffAPFwABaNI8',
    appId: '1:48191107498:ios:3ad1ae2d202435948dbbd3',
    messagingSenderId: '48191107498',
    projectId: 'techventura-fsktm',
    storageBucket: 'techventura-fsktm.firebasestorage.app',
    iosBundleId: 'com.tv.barberHousecall',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCbaeEyqxbJi2oDwdrOEb1ffAPFwABaNI8',
    appId: '1:48191107498:ios:3ad1ae2d202435948dbbd3',
    messagingSenderId: '48191107498',
    projectId: 'techventura-fsktm',
    storageBucket: 'techventura-fsktm.firebasestorage.app',
    iosBundleId: 'com.tv.barberHousecall',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyC8WJHOVH4t1mLx1Hr7fl3_uI1gZOMKvrQ',
    appId: '1:48191107498:web:0c1bb79ddfdfe0e98dbbd3',
    messagingSenderId: '48191107498',
    projectId: 'techventura-fsktm',
    authDomain: 'techventura-fsktm.firebaseapp.com',
    storageBucket: 'techventura-fsktm.firebasestorage.app',
    measurementId: 'G-5QFV5VY7TE',
  );
}

/// Firebase configuration options
///
/// IMPORTANT: This is a placeholder. To use Firebase:
/// 1. Create a Firebase project at https://console.firebase.google.com
/// 2. Run: flutterfire configure
/// 3. This will generate the actual firebase_options.dart
///
/// For now, disable Firebase initialization to test the UI.
library;

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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

  // Firebase project values — run 'flutterfire configure' to regenerate

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBPk0ATdBY6g_cGEJerP1m2RSEICWe7Qpc',
    appId: '1:883551466761:web:c79809059abc26268b8fd8',
    messagingSenderId: '883551466761',
    projectId: 'login1-aa21c',
    authDomain: 'login1-aa21c.firebaseapp.com',
    storageBucket: 'login1-aa21c.firebasestorage.app',
    measurementId: 'G-H1LN6C5CQW',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCdnhy8CJJr4zr53mZdZuf8lXUV2wHlD6g',
    appId: '1:883551466761:android:6c72117e94ae43b38b8fd8',
    messagingSenderId: '883551466761',
    projectId: 'login1-aa21c',
    storageBucket: 'login1-aa21c.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBrLhjWtV5VeGtGhErvbFBXHiUxy58wYgg',
    appId: '1:883551466761:ios:19f1b890b58a2e1b8b8fd8',
    messagingSenderId: '883551466761',
    projectId: 'login1-aa21c',
    storageBucket: 'login1-aa21c.firebasestorage.app',
    iosClientId:
        '883551466761-fn2nqoibtchckr3fokt70hag0lq3c5vk.apps.googleusercontent.com',
    iosBundleId: 'com.example.tulasihotels',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBrLhjWtV5VeGtGhErvbFBXHiUxy58wYgg',
    appId: '1:883551466761:ios:19f1b890b58a2e1b8b8fd8',
    messagingSenderId: '883551466761',
    projectId: 'login1-aa21c',
    storageBucket: 'login1-aa21c.firebasestorage.app',
    iosClientId:
        '883551466761-fn2nqoibtchckr3fokt70hag0lq3c5vk.apps.googleusercontent.com',
    iosBundleId: 'com.example.tulasihotels',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBPk0ATdBY6g_cGEJerP1m2RSEICWe7Qpc',
    appId: '1:883551466761:web:c79809059abc26268b8fd8',
    messagingSenderId: '883551466761',
    projectId: 'login1-aa21c',
    authDomain: 'login1-aa21c.firebaseapp.com',
    storageBucket: 'login1-aa21c.firebasestorage.app',
    measurementId: 'G-H1LN6C5CQW',
  );
}

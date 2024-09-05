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
    apiKey: 'AIzaSyCxQcTSiijeMohr5eAGZZZvVWoi3LrwlZU',
    appId: '1:887332751087:web:90741ec395fef4b6f1bd1a',
    messagingSenderId: '887332751087',
    projectId: 'newsumhua',
    authDomain: 'newsumhua.firebaseapp.com',
    databaseURL: 'https://newsumhua-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'newsumhua.appspot.com',
    measurementId: 'G-GGEZGSXP8R',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDd2fsTOtISy2gE8oL6TW5Z-4D59FWBii8',
    appId: '1:887332751087:android:36b676b5b8f87e70f1bd1a',
    messagingSenderId: '887332751087',
    projectId: 'newsumhua',
    databaseURL: 'https://newsumhua-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'newsumhua.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDvN_NzvQZM-ZXHGKpyJydLVMev-xNrxI0',
    appId: '1:887332751087:ios:2cd06d950db9ce9df1bd1a',
    messagingSenderId: '887332751087',
    projectId: 'newsumhua',
    databaseURL: 'https://newsumhua-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'newsumhua.appspot.com',
    iosBundleId: 'com.example.sumhuaProject',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDvN_NzvQZM-ZXHGKpyJydLVMev-xNrxI0',
    appId: '1:887332751087:ios:2cd06d950db9ce9df1bd1a',
    messagingSenderId: '887332751087',
    projectId: 'newsumhua',
    databaseURL: 'https://newsumhua-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'newsumhua.appspot.com',
    iosBundleId: 'com.example.sumhuaProject',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCxQcTSiijeMohr5eAGZZZvVWoi3LrwlZU',
    appId: '1:887332751087:web:37a77585f62f9af8f1bd1a',
    messagingSenderId: '887332751087',
    projectId: 'newsumhua',
    authDomain: 'newsumhua.firebaseapp.com',
    databaseURL: 'https://newsumhua-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'newsumhua.appspot.com',
    measurementId: 'G-9TP8266VV9',
  );
}

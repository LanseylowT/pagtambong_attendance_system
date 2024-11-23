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
    apiKey: 'AIzaSyCeJiHj8dOH5V1qfcAZyFoBIYeah-PGXtA',
    appId: '1:276223549958:web:5d410c154a2fd148d11987',
    messagingSenderId: '276223549958',
    projectId: 'pagtambong-firebasee',
    authDomain: 'pagtambong-firebasee.firebaseapp.com',
    storageBucket: 'pagtambong-firebasee.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC4k6sTf8nYPnDWs7Z4eYbXESvys5ywnHo',
    appId: '1:276223549958:android:75fef16699da1754d11987',
    messagingSenderId: '276223549958',
    projectId: 'pagtambong-firebasee',
    storageBucket: 'pagtambong-firebasee.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDkiU7KR0-PzNVhDP0WQMrQSNf1eZl3uE0',
    appId: '1:276223549958:ios:6c1f1c5fdbb00207d11987',
    messagingSenderId: '276223549958',
    projectId: 'pagtambong-firebasee',
    storageBucket: 'pagtambong-firebasee.firebasestorage.app',
    iosBundleId: 'com.example.pagtambongAttendanceSystem',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDkiU7KR0-PzNVhDP0WQMrQSNf1eZl3uE0',
    appId: '1:276223549958:ios:6c1f1c5fdbb00207d11987',
    messagingSenderId: '276223549958',
    projectId: 'pagtambong-firebasee',
    storageBucket: 'pagtambong-firebasee.firebasestorage.app',
    iosBundleId: 'com.example.pagtambongAttendanceSystem',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCeJiHj8dOH5V1qfcAZyFoBIYeah-PGXtA',
    appId: '1:276223549958:web:401f99fd56c0b3bdd11987',
    messagingSenderId: '276223549958',
    projectId: 'pagtambong-firebasee',
    authDomain: 'pagtambong-firebasee.firebaseapp.com',
    storageBucket: 'pagtambong-firebasee.firebasestorage.app',
  );

}
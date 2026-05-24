import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyClPoP0tOOXfgBG17x_SG8_Q0KCBaUo3io',
    authDomain: 'activitytracker-7ba37.firebaseapp.com',
    projectId: 'activitytracker-7ba37',
    storageBucket: 'activitytracker-7ba37.firebasestorage.app',
    messagingSenderId: '741181781131',
    appId: '1:741181781131:web:32b94ff0f3992e62ca508e',
    measurementId: 'G-LR9C5X1F8K',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBr60IK-nOL_-C0UMSn1mq9s7N6gtOcH-c',
    authDomain: 'activitytracker-7ba37.firebaseapp.com',
    projectId: 'activitytracker-7ba37',
    storageBucket: 'activitytracker-7ba37.firebasestorage.app',
    messagingSenderId: '741181781131',
    appId: '1:741181781131:android:e419309f6f5002c1ca508e',
  );
}

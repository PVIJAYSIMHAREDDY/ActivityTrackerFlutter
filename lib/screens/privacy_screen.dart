import 'package:flutter/material.dart';

const privacyText =
    "Activity Tracker by Viral Systems\nUpdated September 11, 2026\n\nYour data\nThe app stores your account identifier, Google name/email/photo (when you sign in with Google), and the fitness information you choose to enter in Firebase Authentication and Cloud Firestore. This can include body measurements, weight history, coaching assessments (experience, equipment, recovery, symptoms/restrictions and ingredient exclusions), phone number, meals, workouts, habits, tasks, goals and a custom profile photo. Google operates Firebase. Network requests also expose connection information such as IP addresses to the service provider.\n\nPurpose\nData is used to operate the app and synchronize your records. Custom photos are optional and stored with your profile. Guest use also creates a Firebase account; guest records cannot be recovered on another device until you link Google. Do not sign out of a guest account before linking if you want to keep its records.\n\nCoaching\nThe coach uses built-in rules and templates on your device. It is not a certified trainer, medical device or diagnostic service. Fitness and nutrition estimates are educational and may not suit your health, experience or circumstances. Consult a qualified professional before changing exercise or diet, especially with injuries or health conditions. Stop exercise if you experience pain. The app is intended for adults 18 and over.\n\nSharing and retention\nThe app has no advertising or analytics integration and does not sell your data. Firebase processes records to provide storage and sign-in. Records remain until you delete them or your account. Downloaded Word documents and PDFs and copies you share are outside the app's control.\n\nDelete your account\nOpen Profile > Delete account and data. Google users will be asked to verify their sign-in. Deletion removes the app's stored profile, fitness records and authentication account. If a network error interrupts deletion, retry to finish. You may also request deletion by emailing buntypeddi0@gmail.com from the account email and identifying Activity Tracker; do not send your password. Provider backup retention may apply.\n\nContact\nbuntypeddi0@gmail.com\n";

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Privacy & health information')),
    body: const SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: SelectableText(
        privacyText,
        style: TextStyle(fontSize: 16, height: 1.5),
      ),
    ),
  );
}

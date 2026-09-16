import 'package:flutter/material.dart';
import 'package:activity_tracker/screens/issa_library_screen.dart';
import 'package:activity_tracker/theme.dart';

/// Local review entrypoint; no Firebase account or user data required.
void main() => runApp(
  MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.theme,
    home: const IssaLibraryScreen(),
  ),
);

import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/library_service.dart';
import 'services/settings_service.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const UhdPlayerApp());
}

class UhdPlayerApp extends StatefulWidget {
  const UhdPlayerApp({super.key});

  @override
  State<UhdPlayerApp> createState() => _UhdPlayerAppState();
}

class _UhdPlayerAppState extends State<UhdPlayerApp> {
  final LibraryService _library = LibraryService();
  final SettingsService _settings = SettingsService();

  @override
  void initState() {
    super.initState();
    _library.load();
    _settings.load();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UHD Player',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: HomeScreen(library: _library, settings: _settings),
    );
  }
}

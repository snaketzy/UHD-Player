import 'package:flutter/material.dart';

/// 仿 DVDFab Player 的深色主题：深邃背景 + 橙色点缀色。
class AppTheme {
  AppTheme._();

  static const Color background = Color(0xFF0E1013);
  static const Color surface = Color(0xFF191C20);
  static const Color surfaceVariant = Color(0xFF22262C);
  static const Color accent = Color(0xFFFF7A1A);
  static const Color textSecondary = Color(0xFF9AA2AD);

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: base.colorScheme.copyWith(
        primary: accent,
        secondary: accent,
        surface: surface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
      ),
      cardColor: surface,
      sliderTheme: base.sliderTheme.copyWith(
        activeTrackColor: accent,
        thumbColor: accent,
        inactiveTrackColor: surfaceVariant,
        trackHeight: 3,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      textTheme: base.textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      dividerColor: surfaceVariant,
      popupMenuTheme: PopupMenuThemeData(
        color: surfaceVariant,
        textStyle: const TextStyle(color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// アプリ共通のテーマ。Material 3 のシード配色で light/dark を定義する。
abstract final class AppTheme {
  static const _seed = Color(0xFF3F6E4B); // 落ち着いた緑（読書アプリのトーン）

  static ThemeData get light => _base(Brightness.light);
  static ThemeData get dark => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      appBarTheme: const AppBarTheme(centerTitle: false),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/app.dart';
import 'src/core/env/app_env.dart';
import 'src/core/riverpod/retry_policy.dart';
import 'src/core/storage/shared_preferences_provider.dart';

/// 各エントリポイント（`main_dev.dart` / `main_prod.dart`）から呼ばれる共通起動処理。
///
/// 環境（[AppEnv]）と [SharedPreferences] を Provider に注入して [ProviderScope] を張る。
/// 起動処理を1箇所に集約することで、環境ごとの差分をエントリポイントだけに閉じ込める。
Future<void> bootstrap(AppEnv env) async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      // Riverpod 3 の自動リトライを全体で無効化する（Issue #9 / ADR-0007）。
      retry: noRetry,
      overrides: [
        appEnvProvider.overrideWithValue(env),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const BookReviewApp(),
    ),
  );
}

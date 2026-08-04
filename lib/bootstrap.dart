import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/app.dart';
import 'src/core/env/app_env.dart';
import 'src/core/error/global_error_handler.dart';
import 'src/core/riverpod/retry_policy.dart';
import 'src/core/storage/shared_preferences_provider.dart';

/// 各エントリポイント（`main_dev.dart` / `main_prod.dart`）から呼ばれる共通起動処理。
///
/// 環境（[AppEnv]）と [SharedPreferences] を Provider に注入して [ProviderScope] を張る。
/// 起動処理を1箇所に集約することで、環境ごとの差分をエントリポイントだけに閉じ込める。
Future<void> bootstrap(AppEnv env) async {
  WidgetsFlutterBinding.ensureInitialized();

  // 伝播してきた Error（＝バグ）の受け口を、アプリの処理を始める前に用意する。
  installGlobalErrorHandlers();

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      // Riverpod 3 の自動リトライを全体で無効化する（Issue #9）。
      retry: noRetry,
      // build 内の Error は Riverpod が AsyncError に変えて伝播を止めるため、
      // この経路だけオブザーバでグローバルハンドラへ合流させる。
      observers: const [UncaughtProviderErrorObserver()],
      overrides: [
        appEnvProvider.overrideWithValue(env),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const BookReviewApp(),
    ),
  );
}

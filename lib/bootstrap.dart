import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'src/app.dart';
import 'src/core/env/app_env.dart';

/// 各エントリポイント（`main_dev.dart` / `main_prod.dart`）から呼ばれる共通起動処理。
///
/// 環境（[AppEnv]）を [appEnvProvider] に注入して [ProviderScope] を張る。
/// 起動処理を1箇所に集約することで、環境ごとの差分をエントリポイントだけに閉じ込める。
Future<void> bootstrap(AppEnv env) async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ProviderScope(
      overrides: [appEnvProvider.overrideWithValue(env)],
      child: const BookReviewApp(),
    ),
  );
}

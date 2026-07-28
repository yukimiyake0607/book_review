import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'core/env/app_env.dart';
import 'core/theme/app_theme.dart';
import 'routing/app_router.dart';

/// アプリのルートウィジェット。
///
/// [HookConsumerWidget] を使い、Riverpod と flutter_hooks を同時に扱える。
class BookReviewApp extends HookConsumerWidget {
  const BookReviewApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final env = ref.watch(appEnvProvider);

    return MaterialApp.router(
      title: env.appName,
      debugShowCheckedModeBanner: env.isDev,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
    );
  }
}

import 'package:flutter/material.dart';

import '../core/error/app_exception.dart';

/// エラー状態の共通表示。[AppException] を網羅的に分岐してメッセージと再試行を出し分ける。
class AppErrorView extends StatelessWidget {
  const AppErrorView({
    super.key,
    required this.error,
    this.onRetry,
    this.retryLabel = '再試行',
  });

  final Object error;
  final VoidCallback? onRetry;

  /// [onRetry] のボタン表示。復帰手段が再取得でない場合に差し替える
  /// （例: 解決できない遷移からホームへ戻る）。
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final (message, icon) = _describe(error);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// sealed な [AppException] を網羅的に分岐（分岐漏れはコンパイルエラーになる）。
  (String, IconData) _describe(Object error) {
    if (error is AppException) {
      return switch (error) {
        NetworkException() => (error.message, Icons.wifi_off),
        NotFoundException() => (error.message, Icons.search_off),
        ServerException() => (error.message, Icons.cloud_off),
        ValidationException() => (error.message, Icons.error_outline),
        UnknownException() => (error.message, Icons.error_outline),
      };
    }
    return ('予期しないエラーが発生しました。', Icons.error_outline);
  }
}

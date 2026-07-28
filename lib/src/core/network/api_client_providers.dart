import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../api/book_review_api_client.dart';
import '../env/app_env.dart';

/// Dio インスタンスを供給する Provider。
///
/// ベースURLは環境（[appEnvProvider]）から取り、タイムアウトとログを設定する。
/// テスト時はこの Provider をオーバーライドしてモック用の Dio に差し替える。
final dioProvider = Provider<Dio>((ref) {
  final env = ref.watch(appEnvProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      // 4xx/5xx でも例外にせず、リポジトリ層で明示的に status を判定する。
      validateStatus: (status) => status != null && status < 500,
    ),
  );
  if (env.isDev) {
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  }
  return dio;
});

/// OpenAPI から生成した API クライアントを供給する Provider。
final apiClientProvider = Provider<BookReviewApiClient>((ref) {
  return BookReviewApiClient(ref.watch(dioProvider));
});

import 'package:book_review/src/core/env/app_env.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dio_provider.g.dart';

/// アプリ全体で共有する [Dio] インスタンスを供給する Provider。
///
/// baseUrl は現在の環境（[AppEnv]）から取り、接続/受信のタイムアウトを設定する。
/// 実際のAPI呼び出し（book_search など）は、この Dio を注入して使う。
@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  final env = ref.watch(appEnvProvider);
  return Dio(
    BaseOptions(
      baseUrl: env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      queryParameters: {
        if (env.googleBooksApiKey.isNotEmpty) 'key': env.googleBooksApiKey,
      },
    ),
  );
}

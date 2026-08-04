import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_env.g.dart';

/// アプリの実行環境（flavor）。
///
/// ネイティブのビルドフレーバーではなく、エントリポイント（`main.dart` /
/// `main_dev.dart` / `main_prod.dart`）で切り替える方式を採用している。
/// iOS/Android/CI のいずれでも追加のネイティブ設定なしに確実に動作し、
/// 環境差分（APIのベースURLなど）を型安全に一元管理できるためである。
///
/// [Flavor.demo] は APIキーを持たない人が clone 直後に触れるようにするための環境で、
/// 書籍検索だけを同梱データに差し替える。
enum Flavor { demo, dev, prod }

/// 環境ごとの設定値。
class AppEnv {
  const AppEnv({
    required this.flavor,
    required this.apiBaseUrl,
    required this.appName,
    this.googleBooksApiKey = '',
  });

  final Flavor flavor;

  /// APIのベースURL（Google Books API: https://www.googleapis.com/books/v1/）。
  final String apiBaseUrl;

  /// アプリ表示名（環境が分かるように dev では接尾辞を付ける）。
  final String appName;

  /// Google Books API キー（`--dart-define=GOOGLE_BOOKS_API_KEY=...` で注入）。
  ///
  /// リポジトリに直書きしない。未指定時は空文字（キー無しリクエストになる）。
  final String googleBooksApiKey;

  bool get isDev => flavor == Flavor.dev;

  /// 書籍検索を同梱データで動かすか（APIキーもネットワークも不要）。
  bool get useDemoData => flavor == Flavor.demo;

  static const AppEnv demo = AppEnv(
    flavor: Flavor.demo,
    apiBaseUrl: 'https://www.googleapis.com/books/v1/',
    appName: 'BookReview (demo)',
  );

  static const AppEnv dev = AppEnv(
    flavor: Flavor.dev,
    apiBaseUrl: 'https://www.googleapis.com/books/v1/',
    appName: 'BookReview (dev)',
    googleBooksApiKey: String.fromEnvironment('GOOGLE_BOOKS_API_KEY'),
  );

  // 本番環境のapiBaseUrlも同じものを使用することとする
  static const AppEnv prod = AppEnv(
    flavor: Flavor.prod,
    apiBaseUrl: 'https://www.googleapis.com/books/v1/',
    appName: 'BookReview',
    googleBooksApiKey: String.fromEnvironment('GOOGLE_BOOKS_API_KEY'),
  );
}

/// 現在の環境を供給する Provider。
///
/// エントリポイントで `overrideWithValue` により具体値を注入する。
/// 実体は起動時に必ず注入されるため、既定実装は明示的に例外を投げる。
@Riverpod(keepAlive: true)
AppEnv appEnv(Ref ref) => throw UnimplementedError(
  'appEnvProvider must be overridden in the entry point '
  '(main/main_dev/main_prod).',
);

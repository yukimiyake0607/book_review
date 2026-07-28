import 'package:hooks_riverpod/hooks_riverpod.dart';

/// アプリの実行環境（flavor）。
///
/// ネイティブのビルドフレーバーではなく、エントリポイント（`main_dev.dart` /
/// `main_prod.dart`）で切り替える方式を採用している。iOS/Android/CI のいずれでも
/// 追加のネイティブ設定なしに確実に動作し、環境差分（APIのベースURLなど）を
/// 型安全に一元管理できるためである。
enum Flavor { dev, prod }

/// 環境ごとの設定値。
class AppEnv {
  const AppEnv({
    required this.flavor,
    required this.apiBaseUrl,
    required this.appName,
  });

  final Flavor flavor;

  /// APIのベースURL。dev はローカルの Prism モックサーバを指す。
  final String apiBaseUrl;

  /// アプリ表示名（環境が分かるように dev では接尾辞を付ける）。
  final String appName;

  bool get isDev => flavor == Flavor.dev;

  static const AppEnv dev = AppEnv(
    flavor: Flavor.dev,
    // Prism モックサーバ（`npx @stoplight/prism-cli mock api/openapi.yaml`）の既定ポート。
    // iOS シミュレータ/実機からは localhost 到達性の都合で必要に応じて差し替える。
    apiBaseUrl: 'http://localhost:4010',
    appName: 'BookReview (dev)',
  );

  static const AppEnv prod = AppEnv(
    flavor: Flavor.prod,
    apiBaseUrl: 'https://api.example.com',
    appName: 'BookReview',
  );
}

/// 現在の環境を供給する Provider。
///
/// エントリポイントで `overrideWithValue` により具体値を注入する。既定は dev。
final appEnvProvider = Provider<AppEnv>(
  (ref) => throw UnimplementedError(
    'appEnvProvider must be overridden in the entry point (main_dev/main_prod).',
  ),
);

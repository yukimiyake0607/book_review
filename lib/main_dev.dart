import 'bootstrap.dart';
import 'src/core/env/app_env.dart';

/// 開発環境のエントリポイント。
///
/// 実行例: `flutter run -t lib/main_dev.dart`
void main() => bootstrap(AppEnv.dev);

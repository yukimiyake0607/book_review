import 'bootstrap.dart';
import 'src/core/env/app_env.dart';

/// 本番環境のエントリポイント。
///
/// 実行例: `flutter run -t lib/main_prod.dart`
void main() => bootstrap(AppEnv.prod);

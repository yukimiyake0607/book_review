import 'bootstrap.dart';
import 'src/core/env/app_env.dart';

/// 既定のエントリポイント（デモモード）。
///
/// APIキーを用意しなくても `flutter run` だけで全画面を触れるように、書籍検索は
/// 同梱データで動く。実際に Google Books API を叩く場合は `main_dev.dart` を使う。
void main() => bootstrap(AppEnv.demo);

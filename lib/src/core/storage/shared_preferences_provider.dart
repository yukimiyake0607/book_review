import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [SharedPreferences] のインスタンスを供給する Provider。
///
/// 取得は非同期のため、起動時（bootstrap）に生成した実体を `overrideWithValue` で注入する。
/// 同期的に参照できるようにすることで、キャッシュ層の実装を素直に書ける。
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in bootstrap().',
  );
});

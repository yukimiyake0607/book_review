import '../../../core/error/app_exception.dart';

/// 評価（★1〜5）を表す値オブジェクト。
///
/// 「1〜5の整数」という制約をドメインの中心に閉じ込め、
/// 不正な値がドメインへ侵入しないようにする。
extension type const Rating._(int value) {
  /// 信頼できる値（サーバ応答など）から生成する。範囲外は開発時に気づけるよう assert する。
  factory Rating(int value) {
    assert(value >= min && value <= max, 'rating must be in [$min, $max]');
    return Rating._(value);
  }

  /// ユーザー入力など信頼できない値から生成する。範囲外なら [ValidationException] を送出。
  static Rating parse(int value) {
    if (value < min || value > max) {
      throw const ValidationException('評価は1〜5の範囲で入力してください。');
    }
    return Rating._(value);
  }

  static const int min = 1;
  static const int max = 5;
}

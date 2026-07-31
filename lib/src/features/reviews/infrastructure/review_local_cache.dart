import 'dart:convert';

import 'package:book_review/src/features/reviews/domain/review.dart';
import 'package:book_review/src/features/reviews/infrastructure/dto/review_dto.dart';
import 'package:book_review/src/features/reviews/infrastructure/review_mapper.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences へのレビュー一覧への読み書きを閉じ込める
///
/// キーにバージョン（v1）を含め、将来フォーマットを変えても衝突しにくくする。
class ReviewLocalCache {
  ReviewLocalCache(this._prefs);
  final SharedPreferences _prefs;

  static const _storageKey = 'review_v1';

  /// 保存済み一覧を読む。壊れていれば空リスト（破棄する）
  List<Review> read() {
    final raw = _prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return const [];

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => ReviewDto.fromJson(e as Map<String, dynamic>).toDomain())
          .toList();
    } on Exception {
      _prefs.remove(_storageKey);
      return const [];
    }
  }

  /// 一覧をまるごと上書き保存する。
  Future<void> write(List<Review> reviews) async {
    final encoded = jsonEncode(reviews.map((r) => r.toDto().toJson()).toList());
    await _prefs.setString(_storageKey, encoded);
  }
}

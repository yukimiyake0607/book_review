import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../api/models/review.dart' as dto;

/// レビュー一覧を端末に保存する軽量キャッシュ（ADR-0003）。
///
/// オフライン時や初回描画の即時表示のために、直近の取得結果を保持する。
/// 保存形式は DTO の JSON 配列（API のスキーマ変更に追従しやすい）。
class ReviewLocalCache {
  ReviewLocalCache(this._prefs);

  final SharedPreferences _prefs;

  static const _key = 'cached_reviews_v1';

  /// 一覧を保存する（上書き）。
  Future<void> save(List<dto.Review> reviews) async {
    final encoded = jsonEncode(reviews.map((r) => r.toJson()).toList());
    await _prefs.setString(_key, encoded);
  }

  /// 保存済みの一覧を読み出す（なければ空リスト）。壊れたデータは黙って破棄する。
  List<dto.Review> load() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      return const [];
    }
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => dto.Review.fromJson(e as Map<String, Object?>))
          .toList();
    } on Object {
      return const [];
    }
  }
}

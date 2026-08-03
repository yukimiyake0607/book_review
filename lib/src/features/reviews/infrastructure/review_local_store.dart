import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/error/app_exception.dart';
import '../domain/review.dart';
import 'dto/review_dto.dart';
import 'review_mapper.dart';

/// SharedPreferences へのレビュー一覧の読み書きを閉じ込める。
///
/// キャッシュ（別に正本があり、失っても再取得できる控え）ではなく、レビューの
/// 単一の情報源（SoT）そのものを保持する（ADR-0008）。ここを失うとデータは戻らない。
///
/// キーにバージョン（v1）を含め、将来フォーマットを変えても衝突しにくくする。
class ReviewLocalStore {
  ReviewLocalStore(this._prefs);
  final SharedPreferences _prefs;

  static const _storageKey = 'review_v1';

  /// 保存済み一覧を読む。壊れていれば空リスト（破棄する）
  List<Review> read() {
    try {
      // getString 自体も、保存値の型が違えば TypeError を投げうるため try の中で呼ぶ。
      final raw = _prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) return const [];

      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => ReviewDto.fromJson(e as Map<String, dynamic>).toDomain())
          .toList();
    } on Object {
      // FormatException だけでなく、`[1]` のような不正構造による型キャスト失敗
      // （TypeError＝Error 系）も「破損した保存データ」として破棄する。
      _discardCorrupted();
      return const [];
    }
  }

  /// 破損データの後始末。
  ///
  /// `remove()` は端末への書き出しが非同期だが、メモリ上のキャッシュは同期で
  /// 消えるため、この直後の読み出しには即座に反映される。書き出しに失敗しても
  /// 「空として扱う」という [read] の結果は変わらず、次回起動時に同じ経路で
  /// もう一度破棄されるだけなので、完了は待たず失敗も伝播させない
  /// （best-effort のクリーンアップのために [read] を非同期化しない）。
  void _discardCorrupted() {
    unawaited(_prefs.remove(_storageKey).catchError((Object _) => false));
  }

  /// 一覧をまるごと上書き保存する。
  Future<void> write(List<Review> reviews) async {
    final encoded = jsonEncode(reviews.map((r) => r.toDto().toJson()).toList());
    final saved = await _prefs.setString(_storageKey, encoded);
    if (!saved) {
      // 保存に失敗したまま成功扱いにすると、再起動時にレビューが消える。
      throw const UnknownException('レビューの保存に失敗しました。時間をおいて再度お試しください。');
    }
  }
}

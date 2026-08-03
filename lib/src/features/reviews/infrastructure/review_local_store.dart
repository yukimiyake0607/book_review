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
  ///
  /// 端末の保存値は外部入力なので、構造の不一致は素のキャスト（TypeError＝Error 系）
  /// ではなく [FormatException] として表し、`on Exception` で受けて破棄する。
  /// Error（＝コードのバグ）は握りつぶさず上位へ伝播させる（ADR-0007）。
  List<Review> read() {
    try {
      // getString は内部で `as String?` するため、旧フォーマットで別の型が
      // 入っていると TypeError になる。型は get で受けて自分で確かめる。
      final stored = _prefs.get(_storageKey);
      if (stored == null) return const [];
      if (stored is! String) {
        throw const FormatException('保存されたレビューが文字列ではありません。');
      }
      if (stored.isEmpty) return const [];

      final decoded = jsonDecode(stored);
      if (decoded is! List) {
        throw const FormatException('保存されたレビューが配列ではありません。');
      }

      return decoded.map(_toReview).toList();
    } on Exception {
      // JSON の破損（FormatException）や `[1]` のような構造不一致を
      // 「破損した保存データ」として破棄する。
      _discardCorrupted();
      return const [];
    }
  }

  Review _toReview(Object? element) {
    if (element is! Map<String, dynamic>) {
      throw const FormatException('保存されたレビューが JSON オブジェクトではありません。');
    }
    return ReviewDto.fromJson(element).toDomain();
  }

  /// 破損データの後始末。
  ///
  /// `remove()` は端末への書き出しが非同期だが、メモリ上のキャッシュは同期で
  /// 消えるため、この直後の読み出しには即座に反映される。書き出しに失敗しても
  /// 「空として扱う」という [read] の結果は変わらず、次回起動時に同じ経路で
  /// もう一度破棄されるだけなので、完了は待たず失敗も伝播させない
  /// （best-effort のクリーンアップのために [read] を非同期化しない）。
  void _discardCorrupted() {
    unawaited(
      _prefs
          .remove(_storageKey)
          .catchError(
            (Object _) => false,
            // 見送るのは削除の失敗（Exception）だけ。Error はここでも握りつぶさず、
            // 未処理の非同期エラーとしてグローバルハンドラへ渡す（ADR-0007）。
            test: (error) => error is Exception,
          ),
    );
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

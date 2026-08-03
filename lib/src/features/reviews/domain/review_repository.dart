import 'review.dart';
import 'review_draft.dart';

/// レビューの取得・保存を担うリポジトリインターフェース（domain 層の契約）。
///
/// 実装は infrastructure 層。失敗は `AppException`（sealed）で表現する。
///
/// 永続化先は端末内のみで、これが単一の情報源（SoT）である（ADR-0008）。
/// そのため「サーバから取り直す」「キャッシュを先に返す」に相当する契約は持たない。
abstract interface class ReviewRepository {
  /// レビュー一覧を新着順（`createdAt` 降順）で取得する。
  ///
  /// 1件も無い場合は空リストを返す（「空」は成功状態として扱い、例外にはしない）。
  Future<List<Review>> fetchAll();

  /// 単一のレビューを取得する。該当が無ければ `NotFoundException` を送出する。
  Future<Review> fetchById(String id);

  /// レビューを新規作成し、採番済みの [Review] を返す。
  ///
  /// サーバを持たないため id はこの契約の実装側（infrastructure）で採番する。
  Future<Review> create(ReviewDraft draft);

  /// 既存レビューを更新し、更新後の [Review] を返す。
  ///
  /// 対象が無ければ `NotFoundException` を送出する（黙って作成し直さない）。
  Future<Review> update(String id, ReviewDraft draft);

  /// レビューを削除する。対象が無ければ `NotFoundException` を送出する。
  Future<void> delete(String id);
}

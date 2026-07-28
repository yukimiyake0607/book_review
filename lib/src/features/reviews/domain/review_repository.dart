import 'review.dart';
import 'review_draft.dart';

/// レビューの取得・保存を担うリポジトリインターフェース（domain 層の契約）。
///
/// 実装は infrastructure 層。失敗は [AppException]（sealed）で表現する。
abstract interface class ReviewRepository {
  /// レビュー一覧を新着順で取得する。
  ///
  /// [forceRefresh] が false のときは、可能ならキャッシュを利用してよい。
  Future<List<Review>> fetchAll({bool forceRefresh = false});

  /// 単一のレビューを取得する。
  Future<Review> fetchById(String id);

  /// レビューを新規作成し、サーバが採番した [Review] を返す。
  Future<Review> create(ReviewDraft draft);

  /// 既存レビューを更新し、更新後の [Review] を返す。
  Future<Review> update(String id, ReviewDraft draft);

  /// レビューを削除する。
  Future<void> delete(String id);

  /// 直近に取得したレビュー一覧のキャッシュを返す（なければ空）。
  ///
  /// オフライン時や初回描画の即時表示に用いる（ADR-0003）。
  List<Review> cachedReviews();
}

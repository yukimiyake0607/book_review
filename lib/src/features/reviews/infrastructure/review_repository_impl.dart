import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/review.dart';
import '../domain/review_draft.dart';
import '../domain/review_repository.dart';

part 'review_repository_impl.g.dart';

/// [ReviewRepository] の実装。
///
/// TODO(#15): OpenAPI 生成クライアント（サーバ CRUD）を廃止したため（#12）、
/// レビューは shared_preferences を単一の情報源とするローカル永続化へ置き換える。
/// 現状は未実装のスタブ（参照系は空、更新系は [UnimplementedError]）。
class ReviewRepositoryImpl implements ReviewRepository {
  const ReviewRepositoryImpl();

  @override
  Future<List<Review>> fetchAll({bool forceRefresh = false}) {
    // TODO(#15): shared_preferences から一覧を読み出して新しい順に返す。
    throw UnimplementedError('ReviewRepository.fetchAll は #15 で実装する');
  }

  @override
  Future<Review> fetchById(String id) {
    // TODO(#15): shared_preferences から該当 id の1件を読み出す。
    throw UnimplementedError('ReviewRepository.fetchById は #15 で実装する');
  }

  @override
  Future<Review> create(ReviewDraft draft) {
    // TODO(#15): id をクライアント採番し shared_preferences へ新規保存する。
    throw UnimplementedError('ReviewRepository.create は #15 で実装する');
  }

  @override
  Future<Review> update(String id, ReviewDraft draft) {
    // TODO(#15): shared_preferences の該当レビューを更新する。
    throw UnimplementedError('ReviewRepository.update は #15 で実装する');
  }

  @override
  Future<void> delete(String id) {
    // TODO(#15): shared_preferences から該当レビューを削除する。
    throw UnimplementedError('ReviewRepository.delete は #15 で実装する');
  }

  @override
  List<Review> cachedReviews() {
    // TODO(#15): shared_preferences のキャッシュを返す。地ならし段階では空を返す。
    return const [];
  }
}

/// [ReviewRepository] を供給する Provider。
@Riverpod(keepAlive: true)
ReviewRepository reviewRepository(Ref ref) => const ReviewRepositoryImpl();

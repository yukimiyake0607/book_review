import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../api/book_review_api_client.dart';
import '../../../core/error/error_mapper.dart';
import '../../../core/network/api_client_providers.dart';
import '../../../core/storage/shared_preferences_provider.dart';
import '../domain/review.dart';
import '../domain/review_draft.dart';
import '../domain/review_repository.dart';
import 'review_local_cache.dart';
import 'review_mapper.dart';

/// [ReviewRepository] の実装。
///
/// サーバ（生成 API クライアント）を単一の情報源とし、取得結果を [ReviewLocalCache] に保存する。
/// 外部由来の例外は sealed な AppException へ変換して送出する。
class ReviewRepositoryImpl implements ReviewRepository {
  ReviewRepositoryImpl(this._client, this._cache);

  final BookReviewApiClient _client;
  final ReviewLocalCache _cache;

  @override
  Future<List<Review>> fetchAll({bool forceRefresh = false}) async {
    try {
      final dtos = await _client.reviews.listReviews();
      await _cache.save(dtos);
      return _sortedByNewest(dtos.map((dto) => dto.toDomain()));
    } on Object catch (error) {
      throw mapDioException(error);
    }
  }

  @override
  Future<Review> fetchById(String id) async {
    try {
      final dto = await _client.reviews.getReview(id: id);
      return dto.toDomain();
    } on Object catch (error) {
      throw mapDioException(error);
    }
  }

  @override
  Future<Review> create(ReviewDraft draft) async {
    try {
      final dto = await _client.reviews.createReview(body: draft.toInput());
      return dto.toDomain();
    } on Object catch (error) {
      throw mapDioException(error);
    }
  }

  @override
  Future<Review> update(String id, ReviewDraft draft) async {
    try {
      final dto = await _client.reviews.updateReview(
        id: id,
        body: draft.toInput(),
      );
      return dto.toDomain();
    } on Object catch (error) {
      throw mapDioException(error);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _client.reviews.deleteReview(id: id);
    } on Object catch (error) {
      throw mapDioException(error);
    }
  }

  @override
  List<Review> cachedReviews() {
    return _sortedByNewest(_cache.load().map((dto) => dto.toDomain()));
  }

  List<Review> _sortedByNewest(Iterable<Review> reviews) {
    return reviews.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}

/// レビューのローカルキャッシュを供給する Provider。
final reviewLocalCacheProvider = Provider<ReviewLocalCache>((ref) {
  return ReviewLocalCache(ref.watch(sharedPreferencesProvider));
});

/// [ReviewRepository] を供給する Provider。
final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepositoryImpl(
    ref.watch(apiClientProvider),
    ref.watch(reviewLocalCacheProvider),
  );
});

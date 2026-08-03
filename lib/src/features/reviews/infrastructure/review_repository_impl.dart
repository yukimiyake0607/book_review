import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/storage/shared_preferences_provider.dart';
import '../domain/review.dart';
import '../domain/review_draft.dart';
import '../domain/review_repository.dart';
import 'review_local_store.dart';

part 'review_repository_impl.g.dart';

@Riverpod(keepAlive: true)
ReviewRepository reviewRepository(Ref ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ReviewRepositoryImpl(ReviewLocalStore(prefs));
}

/// [ReviewRepository] のローカル実装。
///
/// `shared_preferences`（[ReviewLocalStore]）だけで CRUD を完結させる。サーバが
/// 無いため、id の採番・タイムスタンプ・並び順はこの層の責務になる（ADR-0008）。
class ReviewRepositoryImpl implements ReviewRepository {
  ReviewRepositoryImpl(this._store);

  final ReviewLocalStore _store;

  @override
  Future<List<Review>> fetchAll() async => _sorted(_store.read());

  @override
  Future<Review> fetchById(String id) async {
    final found = _store.read().where((r) => r.id == id).firstOrNull;
    if (found == null) {
      throw const NotFoundException('レビューが見つかりませんでした。');
    }
    return found;
  }

  @override
  Future<Review> create(ReviewDraft draft) async {
    final now = DateTime.now();
    final created = Review(
      id: 'local-${now.microsecondsSinceEpoch}', // idはサーバーがないためクライアント採番
      bookId: draft.bookId,
      bookTitle: draft.bookTitle,
      bookThumbnailUrl: draft.bookThumbnailUrl,
      rating: draft.rating,
      comment: draft.comment,
      finishedOn: draft.finishedOn,
      createdAt: now,
      updatedAt: now,
    );
    final next = [created, ..._store.read()];
    await _store.write(next);
    return created;
  }

  @override
  Future<Review> update(String id, ReviewDraft draft) async {
    final current = _store.read();
    final index = current.indexWhere((r) => r.id == id);
    if (index < 0) {
      throw const NotFoundException('レビューが見つかりませんでした。');
    }
    final updated = current[index].copyWith(
      bookTitle: draft.bookTitle,
      bookThumbnailUrl: draft.bookThumbnailUrl,
      rating: draft.rating,
      comment: draft.comment,
      finishedOn: draft.finishedOn,
      updatedAt: DateTime.now(),
    );
    final next = [...current]..[index] = updated;
    await _store.write(next);
    return updated;
  }

  @override
  Future<void> delete(String id) async {
    final current = _store.read();
    final next = current.where((r) => r.id != id).toList();
    if (next.length == current.length) {
      throw const NotFoundException('レビューが見つかりませんでした。');
    }
    await _store.write(next);
  }

  List<Review> _sorted(List<Review> reviews) {
    return [...reviews]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}

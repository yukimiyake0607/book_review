import 'package:book_review/src/core/error/app_exception.dart';
import 'package:book_review/src/features/book_search/domain/book.dart';
import 'package:book_review/src/features/book_search/domain/book_repository.dart';
import 'package:book_review/src/features/reviews/domain/review.dart';
import 'package:book_review/src/features/reviews/domain/review_draft.dart';
import 'package:book_review/src/features/reviews/domain/review_repository.dart';

/// テスト用のインメモリ書籍リポジトリ。ネットワークに依存しない。
class FakeBookRepository implements BookRepository {
  FakeBookRepository({this.results = const [], this.error});

  List<Book> results;
  AppException? error;

  @override
  Future<List<Book>> search(String keyword, {int page = 1}) async {
    if (error != null) {
      throw error!;
    }
    return results;
  }
}

/// テスト用のインメモリレビューリポジトリ。
///
/// サーバの採番・保存を模倣し、任意の操作で失敗させられる（ロールバック検証用）。
class FakeReviewRepository implements ReviewRepository {
  FakeReviewRepository({List<Review>? seed}) : _items = [...?seed];

  final List<Review> _items;
  int _sequence = 0;

  AppException? failCreate;
  AppException? failUpdate;
  AppException? failDelete;
  AppException? failFetch;

  @override
  Future<List<Review>> fetchAll({bool forceRefresh = false}) async {
    if (failFetch != null) {
      throw failFetch!;
    }
    return _sortedByNewest();
  }

  @override
  Future<Review> fetchById(String id) async {
    final found = _items.where((r) => r.id == id).firstOrNull;
    if (found == null) {
      throw const NotFoundException();
    }
    return found;
  }

  @override
  Future<Review> create(ReviewDraft draft) async {
    if (failCreate != null) {
      throw failCreate!;
    }
    final now = DateTime.now();
    final review = Review(
      id: 'server-${_sequence++}',
      bookId: draft.bookId,
      bookTitle: draft.bookTitle,
      bookThumbnailUrl: draft.bookThumbnailUrl,
      rating: draft.rating,
      comment: draft.comment,
      finishedOn: draft.finishedOn,
      createdAt: now,
      updatedAt: now,
    );
    _items.add(review);
    return review;
  }

  @override
  Future<Review> update(String id, ReviewDraft draft) async {
    if (failUpdate != null) {
      throw failUpdate!;
    }
    final index = _items.indexWhere((r) => r.id == id);
    final updated = _items[index].copyWith(
      bookTitle: draft.bookTitle,
      rating: draft.rating,
      comment: draft.comment,
      finishedOn: draft.finishedOn,
      updatedAt: DateTime.now(),
    );
    _items[index] = updated;
    return updated;
  }

  @override
  Future<void> delete(String id) async {
    if (failDelete != null) {
      throw failDelete!;
    }
    _items.removeWhere((r) => r.id == id);
  }

  @override
  List<Review> cachedReviews() => _sortedByNewest();

  List<Review> _sortedByNewest() {
    return [..._items]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}

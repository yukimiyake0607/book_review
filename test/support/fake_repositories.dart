import 'dart:async';

import 'package:book_review/src/core/error/app_exception.dart';
import 'package:book_review/src/features/book_search/domain/book.dart';
import 'package:book_review/src/features/book_search/domain/book_repository.dart';
import 'package:book_review/src/features/reviews/domain/review.dart';
import 'package:book_review/src/features/reviews/domain/review_draft.dart';
import 'package:book_review/src/features/reviews/domain/review_repository.dart';

/// テスト用のインメモリ書籍リポジトリ。ネットワークに依存しない。
class FakeBookRepository implements BookRepository {
  FakeBookRepository({this.results = const [], this.error, this.gate});

  List<Book> results;
  AppException? error;

  /// 完了させるまで検索を待たせるゲート。loading 状態を観測するために使う。
  Completer<void>? gate;

  /// キーワードごとに応答や完了タイミングを作り分けたい場合に差し込むフック。
  /// 指定すると [results] / [error] / [gate] より優先される
  /// （連打時に先行の検索結果を破棄する挙動の検証などに使う）。
  Future<List<Book>> Function(String keyword)? onSearch;

  @override
  Future<List<Book>> search(String keyword) async {
    if (onSearch != null) {
      return onSearch!(keyword);
    }
    if (gate != null) {
      await gate!.future;
    }
    if (error != null) {
      throw error!;
    }
    return results;
  }
}

/// テスト用のインメモリレビューリポジトリ。
///
/// ローカル永続化を模倣し、任意の操作で失敗させられる
///（「失敗時に一覧が変わらない」ことの検証用）。
///
/// 存在しない id を渡したときの扱い（`NotFoundException`）も本実装と揃える。
/// フェイクだけが持つ挙動を作らない（testing.mdc）。
class FakeReviewRepository implements ReviewRepository {
  FakeReviewRepository({List<Review>? seed}) : _items = [...?seed];

  final List<Review> _items;
  int _sequence = 0;

  AppException? failCreate;
  AppException? failUpdate;
  AppException? failDelete;
  AppException? failFetch;

  @override
  Future<List<Review>> fetchAll() async {
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
      id: 'local-${_sequence++}',
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
    if (index < 0) {
      throw const NotFoundException();
    }
    final updated = _items[index].copyWith(
      bookTitle: draft.bookTitle,
      bookThumbnailUrl: draft.bookThumbnailUrl,
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
    final before = _items.length;
    _items.removeWhere((r) => r.id == id);
    if (_items.length == before) {
      throw const NotFoundException();
    }
  }

  List<Review> _sortedByNewest() {
    return [..._items]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}

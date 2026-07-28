import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../application/search_books_use_case.dart';
import '../domain/book.dart';

/// 書籍検索画面の状態を保持するコントローラ（presentation 層）。
///
/// 「まだ検索していない」状態と「検索したが0件」の状態を区別するため、
/// [hasSearched] と非同期状態 [books] を分けて持つ。
class BookSearchController extends AutoDisposeNotifier<BookSearchState> {
  @override
  BookSearchState build() => const BookSearchState();

  Future<void> search(String keyword) async {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) {
      state = const BookSearchState();
      return;
    }
    state = BookSearchState(
      keyword: trimmed,
      hasSearched: true,
      books: const AsyncLoading(),
    );
    final result = await AsyncValue.guard(
      () => ref.read(searchBooksUseCaseProvider)(trimmed),
    );
    // 検索語が変わっていなければ結果を反映（連打時の取り違えを防ぐ）。
    if (state.keyword == trimmed) {
      state = state.copyWith(books: result);
    }
  }

  void clear() => state = const BookSearchState();
}

/// 検索画面の状態。freezed を使わない軽量な immutable クラス。
class BookSearchState {
  const BookSearchState({
    this.keyword = '',
    this.hasSearched = false,
    this.books = const AsyncData<List<Book>>([]),
  });

  final String keyword;
  final bool hasSearched;
  final AsyncValue<List<Book>> books;

  BookSearchState copyWith({
    String? keyword,
    bool? hasSearched,
    AsyncValue<List<Book>>? books,
  }) {
    return BookSearchState(
      keyword: keyword ?? this.keyword,
      hasSearched: hasSearched ?? this.hasSearched,
      books: books ?? this.books,
    );
  }
}

final bookSearchControllerProvider =
    AutoDisposeNotifierProvider<BookSearchController, BookSearchState>(
      BookSearchController.new,
    );

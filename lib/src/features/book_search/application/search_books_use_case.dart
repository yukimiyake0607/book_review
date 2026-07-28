import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/book.dart';
import '../domain/book_repository.dart';
import '../infrastructure/book_repository_impl.dart';

part 'search_books_use_case.g.dart';

/// 「書籍を検索する」ユースケース（application 層）。
///
/// 現状は単一リポジトリへの委譲だが、検索操作の入口を1つに定めることで、
/// 将来の整形（重複除去・並び替え・複数ソース統合）を差し込む場所を確保する。
class SearchBooksUseCase {
  const SearchBooksUseCase(this._repository);

  final BookRepository _repository;

  Future<List<Book>> call(String keyword, {int page = 1}) {
    return _repository.search(keyword, page: page);
  }
}

@Riverpod(keepAlive: true)
SearchBooksUseCase searchBooksUseCase(Ref ref) =>
    SearchBooksUseCase(ref.watch(bookRepositoryProvider));

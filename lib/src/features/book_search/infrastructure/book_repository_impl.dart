import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../api/book_review_api_client.dart';
import '../../../core/error/error_mapper.dart';
import '../../../core/network/api_client_providers.dart';
import '../domain/book.dart';
import '../domain/book_repository.dart';
import 'book_mapper.dart';

part 'book_repository_impl.g.dart';

/// [BookRepository] の実装。生成 API クライアントを呼び、DTO をドメインへ変換する。
class BookRepositoryImpl implements BookRepository {
  BookRepositoryImpl(this._client);

  final BookReviewApiClient _client;

  @override
  Future<List<Book>> search(String keyword, {int page = 1}) async {
    try {
      final response = await _client.books.searchBooks(q: keyword, page: page);
      return response.items.map((dto) => dto.toDomain()).toList();
    } on Object catch (error) {
      // 外部由来の例外は sealed な AppException へ変換して送出する。
      throw mapDioException(error);
    }
  }
}

/// [BookRepository] を供給する Provider。
@Riverpod(keepAlive: true)
BookRepository bookRepository(Ref ref) =>
    BookRepositoryImpl(ref.watch(apiClientProvider));

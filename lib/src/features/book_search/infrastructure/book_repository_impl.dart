import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/book.dart';
import '../domain/book_repository.dart';

part 'book_repository_impl.g.dart';

/// [BookRepository] の実装。
///
/// TODO(#15): OpenAPI 生成クライアント（Prism モック）を廃止したため（#12）、
/// 書籍検索は実在の公開書籍 API を手書きの dio クライアント + mapper で叩く実装に
/// 置き換える。現状は未実装のスタブ（呼び出すと [UnimplementedError]）。
class BookRepositoryImpl implements BookRepository {
  const BookRepositoryImpl();

  @override
  Future<List<Book>> search(String keyword, {int page = 1}) {
    // TODO(#15): 公開書籍 API（手書き dio クライアント）で検索し、mapper で Book へ変換する。
    throw UnimplementedError('BookRepository.search は #15 で実装する');
  }
}

/// [BookRepository] を供給する Provider。
@Riverpod(keepAlive: true)
BookRepository bookRepository(Ref ref) => const BookRepositoryImpl();

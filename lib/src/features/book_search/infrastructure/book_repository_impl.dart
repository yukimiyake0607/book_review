import 'package:book_review/src/core/env/app_env.dart';
import 'package:book_review/src/core/error/error_mapper.dart';
import 'package:book_review/src/core/network/dio_provider.dart';
import 'package:book_review/src/features/book_search/domain/book.dart';
import 'package:book_review/src/features/book_search/domain/book_repository.dart';
import 'package:book_review/src/features/book_search/infrastructure/book_mapper.dart';
import 'package:book_review/src/features/book_search/infrastructure/demo_book_repository.dart';
import 'package:book_review/src/features/book_search/infrastructure/dto/google_books_dto.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'book_repository_impl.g.dart';

/// 環境に応じて実装を選ぶ。差し替えは domain の interface に対して行うため、
/// application / presentation はどちらが供給されるかを知らない。
@Riverpod(keepAlive: true)
BookRepository bookRepository(Ref ref) {
  if (ref.watch(appEnvProvider).useDemoData) {
    return DemoBookRepository();
  }
  return BookRepositoryImpl(ref.watch(dioProvider));
}

class BookRepositoryImpl implements BookRepository {
  const BookRepositoryImpl(this._dio);

  final Dio _dio;

  /// 1リクエストで取得する件数。ページネーションを行わないため固定値にしている。
  static const _maxResults = 20;

  @override
  Future<List<Book>> search(String keyword) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'volumes',
        queryParameters: {'q': keyword, 'maxResults': _maxResults},
      );

      final data = response.data;
      if (data == null) return const [];

      final dto = GoogleBooksResponseDto.fromJson(data);
      final items = dto.items;
      if (items == null || items.isEmpty) return const [];

      return items.map((item) => item.toDomain()).toList();
    } on Exception catch (e) {
      throw mapDioException(e);
    }
  }
}

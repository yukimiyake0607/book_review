import 'package:book_review/src/core/error/error_mapper.dart';
import 'package:book_review/src/core/network/dio_provider.dart';
import 'package:book_review/src/features/book_search/domain/book.dart';
import 'package:book_review/src/features/book_search/domain/book_repository.dart';
import 'package:book_review/src/features/book_search/infrastructure/book_mapper.dart';
import 'package:book_review/src/features/book_search/infrastructure/dto/google_books_dto.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'book_repository_impl.g.dart';

@Riverpod(keepAlive: true)
BookRepository bookRepository(Ref ref) {
  return BookRepositoryImpl(ref.watch(dioProvider));
}

class BookRepositoryImpl implements BookRepository {
  const BookRepositoryImpl(this._dio);

  final Dio _dio;

  static const _pageSize = 20;

  @override
  Future<List<Book>> search(String keyword, {int page = 1}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'volumes',
        queryParameters: {
          'q': keyword,
          'startIndex': (page - 1) * _pageSize,
          'maxResults': _pageSize,
        },
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

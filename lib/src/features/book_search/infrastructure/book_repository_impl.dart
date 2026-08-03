import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/env/app_env.dart';
import '../../../core/error/error_mapper.dart';
import '../../../core/network/dio_provider.dart';
import '../domain/book.dart';
import '../domain/book_repository.dart';
import 'book_mapper.dart';
import 'demo_book_repository.dart';
import 'dto/google_books_dto.dart';

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
    } on Object catch (e) {
      // 通信失敗（DioException）だけでなく、想定外のレスポンス構造による
      // 型キャスト失敗（TypeError＝Error 系）もここで AppException に変える。
      // `on Exception` では後者を取りこぼし、生の例外が上位へ漏れてしまう。
      throw mapDioException(e);
    }
  }
}

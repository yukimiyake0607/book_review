// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/book_search_response.dart';

part 'books_api.g.dart';

@RestApi()
abstract class BooksApi {
  factory BooksApi(Dio dio, {String? baseUrl}) = _BooksApi;

  /// 書籍をキーワード検索する.
  ///
  /// [q] - 検索キーワード（タイトル・著者名など）.
  @GET('/books')
  Future<BookSearchResponse> searchBooks({
    @Query('q') required String q,
    @Query('page') int? page = 1,
  });
}

// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';

import 'clients/books_api.dart';
import 'clients/reviews_api.dart';

/// Book Review API `v1.0.0`.
///
/// 読書レビュー管理アプリのバックエンドAPI仕様。.
/// この仕様が唯一の情報源（Single Source of Truth）であり、.
/// Dart クライアントはここから生成し、開発時は Prism でモックする。.
/// バックエンド本体の実装はこのリポジトリのスコープ外。.
///
class BookReviewApiClient {
  BookReviewApiClient(Dio dio, {String? baseUrl})
    : _dio = dio,
      _baseUrl = baseUrl;

  final Dio _dio;
  final String? _baseUrl;

  static String get version => '1.0.0';

  BooksApi? _books;
  ReviewsApi? _reviews;

  BooksApi get books => _books ??= BooksApi(_dio, baseUrl: _baseUrl);

  ReviewsApi get reviews => _reviews ??= ReviewsApi(_dio, baseUrl: _baseUrl);
}

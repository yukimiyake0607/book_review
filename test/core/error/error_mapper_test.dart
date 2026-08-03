import 'package:book_review/src/core/error/app_exception.dart';
import 'package:book_review/src/core/error/error_mapper.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final requestOptions = RequestOptions(path: '/reviews');

  group('mapDioException', () {
    test('タイムアウト系は NetworkException になる', () {
      final error = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.connectionTimeout,
      );
      expect(mapDioException(error), isA<NetworkException>());
    });

    test('404 は NotFoundException になる', () {
      final error = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.badResponse,
        response: Response<void>(
          requestOptions: requestOptions,
          statusCode: 404,
        ),
      );
      expect(mapDioException(error), isA<NotFoundException>());
    });

    test('500 は ServerException になる', () {
      final error = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.badResponse,
        response: Response<void>(
          requestOptions: requestOptions,
          statusCode: 503,
        ),
      );
      expect(mapDioException(error), isA<ServerException>());
    });

    test('すでに AppException ならそのまま返す', () {
      const original = ValidationException('だめ');
      expect(mapDioException(original), same(original));
    });

    test('DioException 以外は UnknownException になる', () {
      expect(mapDioException(Exception('x')), isA<UnknownException>());
    });

    // リポジトリ実装は `on Exception` で受けるため、通信の失敗以外に
    // レスポンスの構造不一致（パース失敗）もここへ来る。
    // Error 系は引数の型（Exception）で弾かれるため、実行時のテストは持たない。
    test('パース失敗（Exception 系）も UnknownException になる', () {
      expect(
        mapDioException(const FormatException('壊れた JSON')),
        isA<UnknownException>(),
      );
    });

    test('429 は ServerException（上限メッセージ）になる', () {
      final error = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.badResponse,
        response: Response<void>(
          requestOptions: requestOptions,
          statusCode: 429,
        ),
      );
      final mapped = mapDioException(error);
      expect(mapped, isA<ServerException>());
      expect(mapped.message, contains('上限'));
    });

    test('403 は ServerException（APIキー案内）になる', () {
      final error = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.badResponse,
        response: Response<void>(
          requestOptions: requestOptions,
          statusCode: 403,
        ),
      );
      final mapped = mapDioException(error);
      expect(mapped, isA<ServerException>());
      expect(mapped.message, contains('APIキー'));
    });
  });
}

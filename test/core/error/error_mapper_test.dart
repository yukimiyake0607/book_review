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
  });
}

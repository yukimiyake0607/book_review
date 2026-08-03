import 'package:book_review/src/core/error/app_exception.dart';
import 'package:book_review/src/features/book_search/infrastructure/book_repository_impl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late _MockDio dio;
  late BookRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: '/'));
  });

  setUp(() {
    dio = _MockDio();
    repository = BookRepositoryImpl(dio);
  });

  Response<dynamic> okResponse(Object? data) {
    return Response<dynamic>(
      requestOptions: RequestOptions(path: 'volumes'),
      data: data,
      statusCode: 200,
    );
  }

  test('トップレベルが Map なら Book に変換する', () async {
    when(
      () => dio.get<dynamic>(
        any(),
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => okResponse({
        'items': [
          {
            'id': 'book-1',
            'volumeInfo': {
              'title': 'リーダブルコード',
              'authors': ['Boswell'],
            },
          },
        ],
      }),
    );

    final books = await repository.search('code');

    expect(books, hasLength(1));
    expect(books.single.title, 'リーダブルコード');
  });

  test('トップレベルが配列なら AppException になる（TypeError にしない）', () async {
    when(
      () => dio.get<dynamic>(
        any(),
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer((_) async => okResponse(<dynamic>[]));

    await expectLater(
      repository.search('code'),
      throwsA(isA<UnknownException>()),
    );
  });

  test('トップレベルが文字列なら AppException になる（TypeError にしない）', () async {
    when(
      () => dio.get<dynamic>(
        any(),
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer((_) async => okResponse('not-a-map'));

    await expectLater(
      repository.search('code'),
      throwsA(isA<UnknownException>()),
    );
  });

  test('data が null なら空リストを返す', () async {
    when(
      () => dio.get<dynamic>(
        any(),
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer((_) async => okResponse(null));

    expect(await repository.search('code'), isEmpty);
  });
}

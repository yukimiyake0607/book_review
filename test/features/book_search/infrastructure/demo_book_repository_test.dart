import 'dart:convert';

import 'package:book_review/src/core/env/app_env.dart';
import 'package:book_review/src/core/error/app_exception.dart';
import 'package:book_review/src/core/riverpod/retry_policy.dart';
import 'package:book_review/src/features/book_search/infrastructure/book_repository_impl.dart';
import 'package:book_review/src/features/book_search/infrastructure/demo_book_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 同梱データの代わりに任意の JSON を返すバンドル。
class _FakeAssetBundle extends CachingAssetBundle {
  _FakeAssetBundle(this.json);

  final String json;

  @override
  Future<ByteData> load(String key) async {
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(json)));
  }
}

const _json = '''
{
  "items": [
    {
      "id": "book-1",
      "volumeInfo": {
        "title": "現場で使える Flutter開発入門",
        "authors": ["澤良弘"],
        "imageLinks": {
          "thumbnail": "http://books.google.com/books/content?id=book-1"
        }
      }
    },
    {
      "id": "book-2",
      "volumeInfo": {
        "title": "テスト駆動開発",
        "authors": ["Kent Beck"]
      }
    }
  ]
}
''';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  DemoBookRepository buildRepository() {
    return DemoBookRepository(
      bundle: _FakeAssetBundle(_json),
      latency: Duration.zero,
    );
  }

  test('タイトルの部分一致で絞り込み、mapper を通した Book を返す', () async {
    final books = await buildRepository().search('flutter');

    expect(books, hasLength(1));
    expect(books.first.title, '現場で使える Flutter開発入門');
    // ATS 対策の https 化は実 API と同じ mapper が担う
    expect(books.first.thumbnailUrl, startsWith('https://'));
  });

  test('著者名でも検索でき、大文字小文字は区別しない', () async {
    final books = await buildRepository().search('kent beck');

    expect(books, hasLength(1));
    expect(books.first.title, 'テスト駆動開発');
  });

  test('該当なしは空リストを返す（例外にしない）', () async {
    expect(await buildRepository().search('該当しないキーワード'), isEmpty);
  });

  test('空文字の検索は同梱データを返さない', () async {
    expect(await buildRepository().search('   '), isEmpty);
  });

  test('壊れた同梱データは AppException として送出する（生の例外を漏らさない）', () async {
    final repository = DemoBookRepository(
      bundle: _FakeAssetBundle('{"items": "配列ではない"}'),
      latency: Duration.zero,
    );

    await expectLater(
      repository.search('flutter'),
      throwsA(isA<AppException>()),
    );
  });

  test('アセットの欠落は AppException にせず Error として伝播させる', () async {
    // 同梱漏れはデータの不備ではなくビルドの不備（＝バグ）で、Flutter も
    // FlutterError（Error 系）で通知する。握りつぶさずグローバルハンドラへ
    // 届かせる方針のため、ここでは AppException に化けないことを固定する（ADR-0007）。
    final repository = DemoBookRepository(
      assetPath: 'assets/demo/does_not_exist.json',
      latency: Duration.zero,
    );

    await expectLater(
      repository.search('flutter'),
      throwsA(allOf(isA<Error>(), isNot(isA<AppException>()))),
    );
  });

  test('同梱アセットが実際に読めて Book に変換できる', () async {
    final repository = DemoBookRepository(latency: Duration.zero);

    final books = await repository.search('flutter');

    expect(books, isNotEmpty);
    expect(books.every((book) => book.title.isNotEmpty), isTrue);
  });

  test('デモ環境では同梱データの実装が供給される', () {
    final container = ProviderContainer(
      retry: noRetry,
      overrides: [appEnvProvider.overrideWithValue(AppEnv.demo)],
    );
    addTearDown(container.dispose);

    expect(container.read(bookRepositoryProvider), isA<DemoBookRepository>());
  });

  test('dev 環境では実 API の実装が供給される', () {
    final container = ProviderContainer(
      retry: noRetry,
      overrides: [appEnvProvider.overrideWithValue(AppEnv.dev)],
    );
    addTearDown(container.dispose);

    expect(container.read(bookRepositoryProvider), isA<BookRepositoryImpl>());
  });
}

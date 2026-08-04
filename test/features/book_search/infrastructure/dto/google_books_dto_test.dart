import 'package:book_review/src/features/book_search/infrastructure/dto/google_books_dto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_annotation/json_annotation.dart';

/// `build.yaml` の `checked: true` が効いていることを固定するテスト。
///
/// この設定が外れると生成コードが素の `as` キャストに戻り、外部 JSON の型不一致が
/// `TypeError`（Error 系）になる。リポジトリ実装は `on Exception` で受けるので、
/// その瞬間に「API のレスポンス構造が変わっただけ」でアプリが落ちるようになる。
/// 生成物はコミットしないため、設定の生死はここで検知する。
void main() {
  test('フィールドの型不一致は Exception（Error ではない）で飛ぶ', () {
    expect(
      () => GoogleBooksResponseDto.fromJson({'items': '配列ではない'}),
      throwsA(
        allOf(
          isA<CheckedFromJsonException>(),
          isA<Exception>(),
          isNot(isA<Error>()),
        ),
      ),
    );
  });

  test('入れ子の要素が JSON オブジェクトでない場合も Exception で飛ぶ', () {
    expect(
      () => GoogleBooksResponseDto.fromJson({
        'items': ['文字列'],
      }),
      throwsA(isA<Exception>()),
    );
  });

  test('想定どおりの構造なら DTO に変換できる', () {
    final dto = GoogleBooksResponseDto.fromJson({
      'items': [
        {
          'id': 'book-1',
          'volumeInfo': {'title': 'リーダブルコード'},
        },
      ],
    });

    expect(dto.items, hasLength(1));
    expect(dto.items!.single.volumeInfo?.title, 'リーダブルコード');
  });
}

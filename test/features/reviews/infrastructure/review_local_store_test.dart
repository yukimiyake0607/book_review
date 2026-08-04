import 'dart:convert';

import 'package:book_review/src/features/reviews/domain/rating.dart';
import 'package:book_review/src/features/reviews/domain/review.dart';
import 'package:book_review/src/features/reviews/infrastructure/review_local_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('write した comment / finishedOn が read で復元される', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = ReviewLocalStore(prefs);
    final finishedOn = DateTime(2026, 7, 1);

    await store.write([
      Review(
        id: 'local-1',
        bookId: 'b1',
        bookTitle: 'リーダブルコード',
        rating: Rating(5),
        comment: '学びが多い',
        finishedOn: finishedOn,
        createdAt: DateTime(2026, 7, 30),
        updatedAt: DateTime(2026, 7, 30),
      ),
    ]);

    // 別インスタンスでも同じ prefs から読めること
    final reread = ReviewLocalStore(prefs).read();
    expect(reread, hasLength(1));
    expect(reread.first.comment, '学びが多い');
    expect(reread.first.finishedOn, finishedOn);
    expect(reread.first.bookTitle, 'リーダブルコード');
  });

  test('壊れた JSON は空リストになり、キーが消える', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('review_v1', '{not-json');

    final result = ReviewLocalStore(prefs).read();
    expect(result, isEmpty);
    expect(prefs.getString('review_v1'), isNull);
  });

  test('保存値が文字列でなくても空リストになり、キーが消える', () async {
    // 旧フォーマットが残っているケース。getString だと TypeError（Error 系）で
    // 落ちるため、型は自分で確かめて「破損データ」として扱う。
    SharedPreferences.setMockInitialValues({'review_v1': 42});
    final prefs = await SharedPreferences.getInstance();

    final result = ReviewLocalStore(prefs).read();
    expect(result, isEmpty);
    expect(prefs.get('review_v1'), isNull);
  });

  test('JSON が配列でない場合も空リストになり、キーが消える', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('review_v1', '{"id": "local-1"}');

    final result = ReviewLocalStore(prefs).read();
    expect(result, isEmpty);
    expect(prefs.getString('review_v1'), isNull);
  });

  test('配列の要素が JSON オブジェクトでない場合も空リストになる', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('review_v1', '[1]');

    final result = ReviewLocalStore(prefs).read();
    expect(result, isEmpty);
    expect(prefs.getString('review_v1'), isNull);
  });

  test('DTO のフィールド型不一致も破損データとして破棄する', () async {
    // CheckedFromJsonException は FormatException に揃えてから握りつぶす。
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'review_v1',
      jsonEncode([
        {
          'id': 'local-1',
          'bookId': 'b1',
          'bookTitle': 'リーダブルコード',
          'rating': '文字列', // int であるべき
          'createdAt': '2026-07-30T00:00:00.000',
          'updatedAt': '2026-07-30T00:00:00.000',
        },
      ]),
    );

    final result = ReviewLocalStore(prefs).read();
    expect(result, isEmpty);
    expect(prefs.getString('review_v1'), isNull);
  });

  test('JSON としては読めるが rating が範囲外のデータも破棄する', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'review_v1',
      jsonEncode([
        {
          'id': 'local-1',
          'bookId': 'b1',
          'bookTitle': 'リーダブルコード',
          'rating': 9, // ドメインの制約（1〜5）を外れた値
          'createdAt': '2026-07-30T00:00:00.000',
          'updatedAt': '2026-07-30T00:00:00.000',
        },
      ]),
    );

    // 範囲外の評価をドメインへ通さない。壊れたデータと同じく破棄する。
    final result = ReviewLocalStore(prefs).read();
    expect(result, isEmpty);
    expect(prefs.getString('review_v1'), isNull);
  });
}

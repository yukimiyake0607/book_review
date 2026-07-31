import 'package:book_review/src/features/reviews/domain/rating.dart';
import 'package:book_review/src/features/reviews/domain/review.dart';
import 'package:book_review/src/features/reviews/infrastructure/review_local_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('write した comment / finishedOn が read で復元される', () async {
    final prefs = await SharedPreferences.getInstance();
    final cache = ReviewLocalCache(prefs);
    final finishedOn = DateTime(2026, 7, 1);

    await cache.write([
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
    final reread = ReviewLocalCache(prefs).read();
    expect(reread, hasLength(1));
    expect(reread.first.comment, '学びが多い');
    expect(reread.first.finishedOn, finishedOn);
    expect(reread.first.bookTitle, 'リーダブルコード');
  });

  test('壊れた JSON は空リストになり、キーが消える', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('review_v1', '{not-json');

    final result = ReviewLocalCache(prefs).read();
    expect(result, isEmpty);
    expect(prefs.getString('review_v1'), isNull);
  });
}

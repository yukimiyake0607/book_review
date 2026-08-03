import 'package:book_review/src/core/error/app_exception.dart';
import 'package:book_review/src/features/reviews/domain/rating.dart';
import 'package:book_review/src/features/reviews/domain/review_draft.dart';
import 'package:book_review/src/features/reviews/infrastructure/review_local_store.dart';
import 'package:book_review/src/features/reviews/infrastructure/review_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// サーバがないため、ID 採番・タイムスタンプ・並び順はすべてこの層の責任になる。
/// 壊れると「更新したのに一覧の順番が変わらない」「再起動で消える」に直結するため、
/// 実際の SharedPreferences（モック実装）越しに検証する。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late ReviewRepositoryImpl repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repository = ReviewRepositoryImpl(ReviewLocalStore(prefs));
  });

  ReviewDraft draft({
    String bookId = 'book-1',
    String bookTitle = 'リーダブルコード',
    int rating = 4,
    String? comment = '読み返したい',
    DateTime? finishedOn,
  }) {
    return ReviewDraft(
      bookId: bookId,
      bookTitle: bookTitle,
      rating: Rating(rating),
      bookThumbnailUrl: 'https://example.com/cover.jpg',
      comment: comment,
      finishedOn: finishedOn,
    );
  }

  // DateTime.now() の分解能に依存させないため、時刻を進める必要がある箇所で挟む。
  Future<void> tick() => Future<void>.delayed(const Duration(milliseconds: 5));

  group('create', () {
    test('クライアント側で id を採番し、createdAt と updatedAt を揃える', () async {
      final created = await repository.create(draft());

      expect(created.id, startsWith('local-'));
      expect(created.createdAt, created.updatedAt);
      expect(created.bookTitle, 'リーダブルコード');
      expect(created.rating, Rating(4));
    });

    test('連続で作成しても id が衝突しない', () async {
      final first = await repository.create(draft(bookId: 'book-1'));
      await tick();
      final second = await repository.create(draft(bookId: 'book-2'));

      expect(first.id, isNot(second.id));
    });

    test('SharedPreferences に永続化され、別インスタンスからも読める', () async {
      final created = await repository.create(draft());

      final reread = await ReviewRepositoryImpl(
        ReviewLocalStore(prefs),
      ).fetchAll();

      expect(reread, hasLength(1));
      expect(reread.first.id, created.id);
      expect(reread.first.comment, '読み返したい');
    });
  });

  group('update', () {
    test('createdAt は据え置き、updatedAt だけを進める', () async {
      final created = await repository.create(draft(rating: 3));
      await tick();

      final updated = await repository.update(
        created.id,
        draft(rating: 5, comment: '再読して評価を上げた'),
      );

      expect(updated.id, created.id);
      expect(updated.createdAt, created.createdAt);
      expect(updated.updatedAt.isAfter(created.updatedAt), isTrue);
      expect(updated.rating, Rating(5));
      expect(updated.comment, '再読して評価を上げた');
    });

    test('コメントを空にする更新も反映される（null で上書きできる）', () async {
      final created = await repository.create(draft());

      final updated = await repository.update(created.id, draft(comment: null));

      expect(updated.comment, isNull);
      expect(updated.hasComment, isFalse);
    });

    test('存在しない id は NotFoundException', () async {
      expect(
        () => repository.update('local-unknown', draft()),
        throwsA(isA<NotFoundException>()),
      );
    });
  });

  group('delete', () {
    test('削除すると一覧から消え、永続化にも反映される', () async {
      final created = await repository.create(draft());

      await repository.delete(created.id);

      expect(await repository.fetchAll(), isEmpty);
      expect(ReviewLocalStore(prefs).read(), isEmpty);
    });

    test('存在しない id は NotFoundException（黙って成功させない）', () async {
      expect(
        () => repository.delete('local-unknown'),
        throwsA(isA<NotFoundException>()),
      );
    });
  });

  group('fetch', () {
    test('fetchAll は createdAt の降順（新着順）で返す', () async {
      final oldest = await repository.create(draft(bookTitle: '1冊目'));
      await tick();
      final middle = await repository.create(draft(bookTitle: '2冊目'));
      await tick();
      final newest = await repository.create(draft(bookTitle: '3冊目'));

      final all = await repository.fetchAll();

      expect(all.map((r) => r.id), [newest.id, middle.id, oldest.id]);
    });

    test('更新しても並び順は createdAt 基準のまま変わらない', () async {
      final oldest = await repository.create(draft(bookTitle: '1冊目'));
      await tick();
      final newest = await repository.create(draft(bookTitle: '2冊目'));
      await tick();

      await repository.update(oldest.id, draft(bookTitle: '1冊目（改訂）'));

      final all = await repository.fetchAll();
      expect(all.map((r) => r.id), [newest.id, oldest.id]);
    });

    test('fetchById は該当がなければ NotFoundException', () async {
      expect(
        () => repository.fetchById('local-unknown'),
        throwsA(isA<NotFoundException>()),
      );
    });
  });
}

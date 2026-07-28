import 'package:book_review/src/core/error/app_exception.dart';
import 'package:book_review/src/features/reviews/domain/rating.dart';
import 'package:book_review/src/features/reviews/domain/review_draft.dart';
import 'package:book_review/src/features/reviews/infrastructure/review_repository_impl.dart';
import 'package:book_review/src/features/reviews/presentation/review_list_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../support/fake_repositories.dart';

ReviewDraft _draft() => ReviewDraft(
  bookId: 'b1',
  bookTitle: 'テスト駆動開発',
  rating: Rating(4),
  comment: '良かった',
);

ProviderContainer _container(FakeReviewRepository fake) {
  final container = ProviderContainer(
    overrides: [reviewRepositoryProvider.overrideWithValue(fake)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('ReviewListController の楽観的更新', () {
    test('add: 成功するとサーバ採番の結果で一覧に反映される', () async {
      final container = _container(FakeReviewRepository());
      await container.read(reviewListControllerProvider.future);

      await container.read(reviewListControllerProvider.notifier).add(_draft());

      final list = container.read(reviewListControllerProvider).value!;
      expect(list, hasLength(1));
      expect(list.first.id, startsWith('server-')); // 仮IDではなく採番済み
      expect(list.first.bookTitle, 'テスト駆動開発');
    });

    test('add: 失敗すると直前状態へロールバックし例外を送出する', () async {
      final fake = FakeReviewRepository()
        ..failCreate = const NetworkException();
      final container = _container(fake);
      await container.read(reviewListControllerProvider.future);

      await expectLater(
        container.read(reviewListControllerProvider.notifier).add(_draft()),
        throwsA(isA<NetworkException>()),
      );

      // ロールバックされ、一覧は空のまま。
      expect(container.read(reviewListControllerProvider).value, isEmpty);
    });

    test('remove: 失敗すると削除がロールバックされる', () async {
      final fake = FakeReviewRepository();
      final container = _container(fake);
      await container.read(reviewListControllerProvider.future);
      final notifier = container.read(reviewListControllerProvider.notifier);

      await notifier.add(_draft());
      final id = container.read(reviewListControllerProvider).value!.first.id;

      fake.failDelete = const ServerException();
      await expectLater(notifier.remove(id), throwsA(isA<ServerException>()));

      // 削除はロールバックされ、1件残っている。
      expect(container.read(reviewListControllerProvider).value, hasLength(1));
    });

    test('build: サーバ取得失敗でもキャッシュがあれば表示する', () async {
      final fake = FakeReviewRepository()..failFetch = const NetworkException();
      // キャッシュに1件（fetchById 経由ではなく create で積む）。
      await fake.create(_draft());
      final container = _container(fake);

      final list = await container.read(reviewListControllerProvider.future);
      expect(list, hasLength(1));
    });
  });
}

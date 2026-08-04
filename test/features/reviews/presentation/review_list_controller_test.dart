import 'package:book_review/src/core/error/app_exception.dart';
import 'package:book_review/src/core/riverpod/retry_policy.dart';
import 'package:book_review/src/features/reviews/domain/rating.dart';
import 'package:book_review/src/features/reviews/domain/review.dart';
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
    // アプリ（bootstrap）と同じリトライ方針で動かす。既定のままだと Riverpod 3 が
    // build の失敗を自動リトライし続け、AsyncError を観測できない。
    retry: noRetry,
    overrides: [reviewRepositoryProvider.overrideWithValue(fake)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('ReviewListController（書き込み完了後に反映）', () {
    test('add: 成功すると一覧に反映される', () async {
      final container = _container(FakeReviewRepository());
      await container.read(reviewListControllerProvider.future);

      await container.read(reviewListControllerProvider.notifier).add(_draft());

      final list = container.read(reviewListControllerProvider).value!;
      expect(list, hasLength(1));
      expect(list.first.id, startsWith('local-'));
      expect(list.first.bookTitle, 'テスト駆動開発');
      expect(list.first.comment, '良かった');
    });

    test('add: 失敗すると一覧は変わらず例外を送出する', () async {
      final fake = FakeReviewRepository()
        ..failCreate = const NetworkException();
      final container = _container(fake);
      await container.read(reviewListControllerProvider.future);

      await expectLater(
        container.read(reviewListControllerProvider.notifier).add(_draft()),
        throwsA(isA<NetworkException>()),
      );

      // 書き込み前に UI を変えないため、一覧は空のまま。
      expect(container.read(reviewListControllerProvider).value, isEmpty);
    });

    test('remove: 失敗すると一覧から消えない', () async {
      final fake = FakeReviewRepository();
      final container = _container(fake);
      await container.read(reviewListControllerProvider.future);
      final notifier = container.read(reviewListControllerProvider.notifier);

      await notifier.add(_draft());
      final id = container.read(reviewListControllerProvider).value!.first.id;

      fake.failDelete = const ServerException();
      await expectLater(notifier.remove(id), throwsA(isA<ServerException>()));

      expect(container.read(reviewListControllerProvider).value, hasLength(1));
    });

    test('build: 読み込みに失敗すると AsyncLoading から AsyncError へ遷移する', () async {
      final fake = FakeReviewRepository()..failFetch = const NetworkException();
      final container = _container(fake);

      final states = <AsyncValue<List<Review>>>[];
      container.listen(
        reviewListControllerProvider,
        (_, next) => states.add(next),
        fireImmediately: true,
      );

      await expectLater(
        container.read(reviewListControllerProvider.future),
        throwsA(isA<NetworkException>()),
      );

      // 失敗はフォールバックせず、そのまま AsyncError として画面へ渡す。
      expect(states.first, isA<AsyncLoading<List<Review>>>());
      expect(states.last, isA<AsyncError<List<Review>>>());
      expect(states.last.error, isA<NetworkException>());
    });

    test('refresh: Error は AsyncError に載せず、一覧も変えずに送出する', () async {
      final fake = FakeReviewRepository();
      final container = _container(fake);
      await container.read(reviewListControllerProvider.future);
      final notifier = container.read(reviewListControllerProvider.notifier);
      await notifier.add(_draft());

      fake.failFetch = StateError('バグ');
      await expectLater(notifier.refresh(), throwsA(isA<StateError>()));

      // Error は AppErrorView に見せる失敗ではないため、直前のデータを保つ。
      final state = container.read(reviewListControllerProvider);
      expect(state, isA<AsyncData<List<Review>>>());
      expect(state.value, hasLength(1));
    });
  });
}

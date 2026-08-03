import 'package:book_review/src/app.dart';
import 'package:book_review/src/core/env/app_env.dart';
import 'package:book_review/src/core/riverpod/retry_policy.dart';
import 'package:book_review/src/features/book_search/infrastructure/book_repository_impl.dart';
import 'package:book_review/src/features/reviews/domain/rating.dart';
import 'package:book_review/src/features/reviews/domain/review.dart';
import 'package:book_review/src/features/reviews/infrastructure/review_repository_impl.dart';
import 'package:book_review/src/routing/app_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../support/fake_repositories.dart';

/// URL から直接開かれた場合（ディープリンク・状態復元）の遷移を固定する。
///
/// go_router の `extra` は URL に乗らず復元もされないため、`extra` を前提にした
/// 画面は直接開かれると壊れる。ここでは「URL だけで開けること」と「開けない
/// 場合でも落ちずに復帰できること」を守る。
void main() {
  final review = Review(
    id: 'r1',
    bookId: 'b1',
    bookTitle: 'リファクタリング',
    rating: Rating(4),
    comment: '設計の指針が増えた',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  /// アプリを起動し、必要なら [location] へ遷移させる。
  ///
  /// 遷移は本物の `goRouterProvider` 越しに行い、ルート定義そのものを検証する。
  Future<void> pumpAppAt(
    WidgetTester tester, {
    required FakeReviewRepository reviewRepo,
    String? location,
  }) async {
    final container = ProviderContainer(
      // アプリ（bootstrap）と同じ設定で動かす（ADR-0007）。
      retry: noRetry,
      overrides: [
        appEnvProvider.overrideWithValue(AppEnv.dev),
        bookRepositoryProvider.overrideWithValue(FakeBookRepository()),
        reviewRepositoryProvider.overrideWithValue(reviewRepo),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const BookReviewApp(),
      ),
    );
    await tester.pumpAndSettle();

    if (location != null) {
      container.read(goRouterProvider).go(location);
      await tester.pumpAndSettle();
    }
  }

  group('レビュー編集（/reviews/:id/edit）', () {
    testWidgets('URL から直接開いても id で読み直してフォームが開く', (tester) async {
      await pumpAppAt(
        tester,
        reviewRepo: FakeReviewRepository(seed: [review]),
        location: AppRoute.reviewEdit('r1'),
      );

      // extra を渡していないが、編集対象が復元できている。
      expect(find.text('更新する'), findsOneWidget);
      expect(find.text('リファクタリング'), findsOneWidget);
      expect(find.text('設計の指針が増えた'), findsOneWidget);
    });

    testWidgets('詳細画面の編集ボタンからも同じフォームへ遷移する', (tester) async {
      await pumpAppAt(
        tester,
        reviewRepo: FakeReviewRepository(seed: [review]),
        location: AppRoute.reviewDetail('r1'),
      );

      await tester.tap(find.byTooltip('編集'));
      await tester.pumpAndSettle();

      expect(find.text('更新する'), findsOneWidget);
    });

    testWidgets('存在しない id なら見つからない旨を表示する', (tester) async {
      await pumpAppAt(
        tester,
        reviewRepo: FakeReviewRepository(),
        location: AppRoute.reviewEdit('missing'),
      );

      expect(find.text('対象が見つかりませんでした。'), findsOneWidget);
    });
  });

  group('レビュー登録（/reviews/new）', () {
    testWidgets('書籍が渡されていなければ落ちず、選び直しを促す', (tester) async {
      // 検索結果の Book は URL から復元できないため、直接開くと対象が決まらない。
      await pumpAppAt(
        tester,
        reviewRepo: FakeReviewRepository(),
        location: AppRoute.reviewNew,
      );

      expect(find.text('画面が見つかりません'), findsOneWidget);
      expect(find.textContaining('書籍を検索して選び直して'), findsOneWidget);
    });
  });

  group('未定義のパス', () {
    testWidgets('エラー画面を出し、ホームへ戻れる', (tester) async {
      await pumpAppAt(
        tester,
        reviewRepo: FakeReviewRepository(),
        location: '/unknown',
      );

      expect(find.text('お探しの画面は見つかりませんでした。'), findsOneWidget);

      // ディープリンクでは戻り先が無いため、行き止まりにしない。
      await tester.tap(find.text('ホームへ戻る'));
      await tester.pumpAndSettle();

      expect(find.textContaining('まだレビューがありません'), findsOneWidget);
    });
  });
}

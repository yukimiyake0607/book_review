import 'package:book_review/src/app.dart';
import 'package:book_review/src/core/env/app_env.dart';
import 'package:book_review/src/features/book_search/domain/book.dart';
import 'package:book_review/src/features/book_search/infrastructure/book_repository_impl.dart';
import 'package:book_review/src/features/reviews/infrastructure/review_repository_impl.dart';
import 'package:book_review/src/features/reviews/presentation/review_list_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../support/fake_repositories.dart';

void main() {
  testWidgets('コアフロー: 検索 → レビュー登録 → 一覧に反映される', (tester) async {
    final bookRepo = FakeBookRepository(
      results: const [
        Book(id: 'b1', title: 'リファクタリング', authors: ['Fowler']),
      ],
    );
    final reviewRepo = FakeReviewRepository();

    final container = ProviderContainer(
      overrides: [
        appEnvProvider.overrideWithValue(AppEnv.dev),
        bookRepositoryProvider.overrideWithValue(bookRepo),
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

    // 初期状態は空。
    expect(find.textContaining('まだレビューがありません'), findsOneWidget);

    // 追加ボタン → 検索画面へ。
    await tester.tap(find.text('レビューを追加'));
    await tester.pumpAndSettle();

    // キーワード検索。
    await tester.enterText(find.byType(TextField), 'リファクタ');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    // 検索結果の書籍を選択 → 登録フォームへ。
    await tester.tap(find.text('リファクタリング'));
    await tester.pumpAndSettle();

    // 評価（★4）を選択して登録。
    await tester.tap(find.byIcon(Icons.star_border).at(3));
    await tester.pump();
    await tester.tap(find.text('登録する'));
    await tester.pumpAndSettle();

    // 一覧に採番済みレビューが反映されている。
    final reviews = container.read(reviewListControllerProvider).value!;
    expect(reviews, hasLength(1));
    expect(reviews.first.bookTitle, 'リファクタリング');
    expect(reviews.first.rating.value, 4);
    expect(reviews.first.id, startsWith('local-'));
  });
}

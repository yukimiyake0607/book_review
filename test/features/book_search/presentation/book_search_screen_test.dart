import 'dart:async';

import 'package:book_review/src/core/error/app_exception.dart';
import 'package:book_review/src/features/book_search/domain/book.dart';
import 'package:book_review/src/features/book_search/infrastructure/book_repository_impl.dart';
import 'package:book_review/src/features/book_search/presentation/book_search_controller.dart';
import 'package:book_review/src/features/book_search/presentation/book_search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../support/fake_repositories.dart';

Future<void> _pump(WidgetTester tester, FakeBookRepository fake) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [bookRepositoryProvider.overrideWithValue(fake)],
      child: const MaterialApp(home: BookSearchScreen()),
    ),
  );
}

void main() {
  group('BookSearchScreen の状態表示', () {
    testWidgets('検索前はガイド文言を表示する', (tester) async {
      await _pump(tester, FakeBookRepository());
      expect(find.textContaining('キーワードを入力'), findsOneWidget);
    });

    testWidgets('検索中はローディングを表示し、完了すると結果に切り替わる', (tester) async {
      final gate = Completer<void>();
      final fake = FakeBookRepository(
        results: const [
          Book(id: '1', title: 'リーダブルコード', authors: ['Boswell']),
        ],
        gate: gate,
      );
      await _pump(tester, fake);

      await tester.enterText(find.byType(TextField), 'code');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      // AsyncLoading への遷移だけを反映させる（結果はゲートで止めたまま）。
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('リーダブルコード'), findsNothing);

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('リーダブルコード'), findsOneWidget);
    });

    testWidgets('検索結果があれば一覧に表示する', (tester) async {
      final fake = FakeBookRepository(
        results: const [
          Book(id: '1', title: 'リーダブルコード', authors: ['Boswell']),
        ],
      );
      await _pump(tester, fake);

      await tester.enterText(find.byType(TextField), 'code');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(find.text('リーダブルコード'), findsOneWidget);
    });

    testWidgets('0件なら「見つかりませんでした」を表示する', (tester) async {
      await _pump(tester, FakeBookRepository(results: const []));

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(find.textContaining('見つかりませんでした'), findsOneWidget);
    });

    testWidgets('失敗ならエラー表示と再試行ボタンを出す', (tester) async {
      await _pump(tester, FakeBookRepository(error: const NetworkException()));

      await tester.enterText(find.byType(TextField), 'x');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(find.text('再試行'), findsOneWidget);
    });
  });

  group('BookSearchController の状態遷移', () {
    ProviderContainer containerWith(FakeBookRepository fake) {
      final container = ProviderContainer(
        overrides: [bookRepositoryProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('空文字では検索しない', () {
      final container = containerWith(FakeBookRepository());

      final state = container.read(bookSearchControllerProvider);
      expect(state.hasSearched, isFalse);
    });

    test('検索開始で AsyncLoading になり、成功すると AsyncData へ遷移する', () async {
      final gate = Completer<void>();
      final container = containerWith(
        FakeBookRepository(
          results: const [
            Book(id: '1', title: 'リーダブルコード', authors: ['Boswell']),
          ],
          gate: gate,
        ),
      );

      final searching = container
          .read(bookSearchControllerProvider.notifier)
          .search('code');

      expect(
        container.read(bookSearchControllerProvider).books,
        isA<AsyncLoading<List<Book>>>(),
      );

      gate.complete();
      await searching;

      final state = container.read(bookSearchControllerProvider);
      expect(state.books, isA<AsyncData<List<Book>>>());
      expect(state.books.requireValue.single.title, 'リーダブルコード');
    });

    test('リポジトリが失敗すると AsyncError へ遷移する', () async {
      final container = containerWith(
        FakeBookRepository(error: const NetworkException()),
      );

      await container
          .read(bookSearchControllerProvider.notifier)
          .search('code');

      final state = container.read(bookSearchControllerProvider);
      expect(state.books, isA<AsyncError<List<Book>>>());
      expect(state.books.error, isA<NetworkException>());
    });

    test('検索語が変わった後に先行の検索が完了しても、その結果は破棄する', () async {
      final slowGate = Completer<void>();
      final fastGate = Completer<void>();
      final fake = FakeBookRepository()
        ..onSearch = (keyword) async {
          if (keyword == 'slow') {
            await slowGate.future;
            return const [Book(id: 'slow', title: '先行の検索結果', authors: [])];
          }
          await fastGate.future;
          return const [Book(id: 'fast', title: '後発の検索結果', authors: [])];
        };
      final container = containerWith(fake);
      final controller = container.read(bookSearchControllerProvider.notifier);

      // 先行の検索が終わらないうちに次の検索を始める（連打の再現）。
      final slow = controller.search('slow');
      final fast = controller.search('fast');

      fastGate.complete();
      await fast;
      slowGate.complete();
      await slow;

      final state = container.read(bookSearchControllerProvider);
      expect(state.keyword, 'fast');
      expect(state.books.requireValue.single.title, '後発の検索結果');
    });
  });
}

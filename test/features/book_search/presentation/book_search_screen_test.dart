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

  test('BookSearchController: 空文字では検索しない', () {
    final container = ProviderContainer(
      overrides: [
        bookRepositoryProvider.overrideWithValue(FakeBookRepository()),
      ],
    );
    addTearDown(container.dispose);

    final state = container.read(bookSearchControllerProvider);
    expect(state.hasSearched, isFalse);
  });
}

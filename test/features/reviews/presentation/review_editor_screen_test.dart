import 'package:book_review/src/core/riverpod/retry_policy.dart';
import 'package:book_review/src/features/book_search/domain/book.dart';
import 'package:book_review/src/features/reviews/presentation/review_editor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  testWidgets('評価を選ばずに登録するとバリデーションで止まる', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        // アプリ（bootstrap）と同じ設定で動かす。
        retry: noRetry,
        child: MaterialApp(
          home: ReviewEditorScreen.create(
            book: Book(
              id: 'b1',
              title: 'Clean Architecture',
              authors: ['Martin'],
            ),
          ),
        ),
      ),
    );

    // 対象書籍名が表示されている。
    expect(find.text('Clean Architecture'), findsOneWidget);

    // 評価未選択のまま登録。
    await tester.tap(find.text('登録する'));
    await tester.pump(); // SnackBar を出す

    expect(find.textContaining('評価（★）を選択してください'), findsOneWidget);
  });
}

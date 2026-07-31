import 'package:book_review/src/core/riverpod/retry_policy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// テスト専用の例外。`Exception` 派生なので既定リトライの対象になり得る。
class _BoomException implements Exception {
  const _BoomException();
}

void main() {
  group('noRetry ポリシー', () {
    test('build 失敗をリトライせず、1回のビルドで即エラーになる', () async {
      var buildCount = 0;
      final provider = FutureProvider<int>((ref) async {
        buildCount++;
        throw const _BoomException();
      });

      final container = ProviderContainer(retry: noRetry);
      addTearDown(container.dispose);

      await expectLater(
        container.read(provider.future),
        throwsA(isA<_BoomException>()),
      );

      // イベントループを回しても再ビルドされないことを確認する。
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(buildCount, 1);
      expect(container.read(provider), isA<AsyncError<int>>());
    });

    test('対照: リトライ有効なら build が複数回走る（テストの妥当性確認）', () async {
      var buildCount = 0;
      final provider = FutureProvider<int>((ref) async {
        buildCount++;
        throw const _BoomException();
      });

      // 遅延なしで数回だけリトライを許可し、無限ループを避ける。
      final container = ProviderContainer(
        retry: (retryCount, error) => retryCount < 2 ? Duration.zero : null,
      );
      addTearDown(container.dispose);
      container.listen<AsyncValue<int>>(
        provider,
        (_, _) {},
        onError: (_, _) {},
      );

      for (var i = 0; i < 30 && buildCount < 3; i++) {
        await Future<void>.delayed(Duration.zero);
      }

      expect(buildCount, greaterThan(1));
    });
  });
}

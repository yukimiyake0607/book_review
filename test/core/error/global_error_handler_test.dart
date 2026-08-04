import 'package:book_review/src/core/error/app_exception.dart';
import 'package:book_review/src/core/error/global_error_handler.dart';
import 'package:book_review/src/core/riverpod/retry_policy.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 報告された失敗を集める。呼び出し後は元のハンドラへ戻す。
List<Object> _captureReports() {
  final reported = <Object>[];
  final previous = FlutterError.onError;
  FlutterError.onError = (details) => reported.add(details.exception);
  addTearDown(() => FlutterError.onError = previous);
  return reported;
}

/// アプリ（bootstrap）と同じ設定でオブザーバを効かせたコンテナ。
ProviderContainer _observedContainer() {
  final container = ProviderContainer(
    retry: noRetry,
    observers: const [UncaughtProviderErrorObserver()],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('UncaughtProviderErrorObserver', () {
    test('build で起きた Error はグローバルハンドラへ報告する', () async {
      final reported = _captureReports();
      final provider = FutureProvider<int>((ref) async {
        throw StateError('バグ');
      });
      final container = _observedContainer();

      await expectLater(
        container.read(provider.future),
        throwsA(isA<StateError>()),
      );

      // Riverpod が AsyncError に変えて伝播を止めるため、この経路だけは
      // オブザーバが拾わないとバグの痕跡が残らない。
      expect(reported.single, isA<StateError>());
    });

    test('build の失敗が AppException なら報告しない（UI が扱う失敗）', () async {
      final reported = _captureReports();
      final provider = FutureProvider<int>((ref) async {
        throw const NetworkException();
      });
      final container = _observedContainer();

      await expectLater(
        container.read(provider.future),
        throwsA(isA<NetworkException>()),
      );

      expect(reported, isEmpty);
    });
  });

  group('installGlobalErrorHandlers', () {
    test('未処理の非同期エラーを処理済みとして受け、既定の出力へ流す', () {
      final previousFlutterOnError = FlutterError.onError;
      final previousPlatformOnError = PlatformDispatcher.instance.onError;
      final previousDebugPrint = debugPrint;
      final logs = <String>[];
      debugPrint = (String? message, {int? wrapWidth}) =>
          logs.add(message ?? '');
      addTearDown(() {
        debugPrint = previousDebugPrint;
        FlutterError.onError = previousFlutterOnError;
        PlatformDispatcher.instance.onError = previousPlatformOnError;
      });
      FlutterError.resetErrorCount();

      installGlobalErrorHandlers();
      final handled = PlatformDispatcher.instance.onError!(
        StateError('伝播してきたバグ'),
        StackTrace.current,
      );

      // false を返すと埋め込み側の既定出力と二重になる。
      expect(handled, isTrue);
      expect(logs.join('\n'), contains('伝播してきたバグ'));
    });
  });
}

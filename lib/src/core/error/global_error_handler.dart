import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 報告に添える出所（DevTools やログでアプリ由来だと分かるようにする）。
const _library = 'book_review';

/// 捕捉されなかった失敗の受け口を配線する。
///
/// 本アプリは「想定される失敗」だけを `Exception`（sealed な `AppException`）として
/// 型付けし、`Error`（プログラムのバグ）は catch せず上位へ伝播させる。伝播した
/// `Error` の行き先がここで、Flutter が持つ2つの入口を [_report] に合流させる。
///
/// - [FlutterError.onError]: build / layout などフレームワークが捕捉した失敗
/// - [PlatformDispatcher.onError]: root isolate の未処理の非同期エラー
///   （`AsyncValue.guard` が `test` で捕捉を拒み rethrow した `Error` など）
///
/// `runApp` より前（`WidgetsFlutterBinding.ensureInitialized()` の直後）に呼ぶ。
void installGlobalErrorHandlers() {
  FlutterError.onError = _report;

  PlatformDispatcher.instance.onError = (error, stack) {
    _report(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: _library,
        context: ErrorDescription('root isolate で捕捉されなかった非同期エラー'),
      ),
    );
    // 処理済みとして返す（false だと埋め込み側の既定出力と二重になる）。
    return true;
  };
}

/// 報告の唯一の出口。
///
/// **本来はこの直後にクラッシュ収集サービス（Firebase Crashlytics の
/// `recordError`）へ送る。** 本 Repo では Firebase の導入まで実装範囲を広げない
/// ため送信先を持たず、既定の出力（コンソール / DevTools）だけを残している。
/// 送信の有無ではなく「捕捉されなかった失敗をどこに集めるか」を設計として示す
/// ことが目的で、後から足す1行の位置をここに限定している
/// （README「監視・クラッシュ収集」）。
void _report(FlutterErrorDetails details) {
  FlutterError.presentError(details);
}

/// Provider の `build` で起きた失敗のうち、`Exception` でないものを
/// グローバルハンドラへ流すオブザーバ。
///
/// Riverpod は `build` の失敗をフレームワーク側で捕捉して `AsyncError` に変える
/// ため、`Error` であっても上位へ伝播しない（`AsyncValue.guard` の `test` も通らない）。
/// 放置すると画面に「予期しないエラー」と出るだけでバグの痕跡が残らないので、この
/// 経路だけはオブザーバで拾い、[FlutterError.reportError] 経由で他と同じ出口へ送る。
///
/// `Exception`（`AppException` を含む）は想定内の失敗として UI が扱うため報告しない。
final class UncaughtProviderErrorObserver extends ProviderObserver {
  const UncaughtProviderErrorObserver();

  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    if (error is Exception) return;

    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: _library,
        context: ErrorDescription('${context.provider} の build 中'),
      ),
    );
  }
}

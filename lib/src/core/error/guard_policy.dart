import 'app_exception.dart';

/// `AsyncValue.guard` に渡す捕捉条件（ADR-0007）。
///
/// `AsyncValue.guard` は既定で `Object` を捕まえるため、何も渡さないと
/// `Error`（＝コードのバグ）まで `AsyncValue.error` に載り、画面に「予期しない
/// エラー」と出るだけでグローバルハンドラに届かない。想定される失敗
/// （[AppException]）だけを捕まえ、それ以外は rethrow させて
/// `PlatformDispatcher.onError` まで通す。
///
/// ```dart
/// state = await AsyncValue.guard(_repository.fetchAll, onlyAppException);
/// ```
bool onlyAppException(Object error) => error is AppException;

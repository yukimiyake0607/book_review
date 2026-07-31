/// Riverpod 3 の自動リトライを無効化するためのポリシー（Issue #9 / ADR-0007）。
///
/// Riverpod 3 は Provider の `build` 失敗時に指数バックオフ（最大10回）で
/// 自動リトライする。本アプリは失敗を sealed [AppException] + `AppErrorView`
/// （`onRetry` 付き）で決定論的に見せる設計を主役に置くため、この自動リトライを
/// [ProviderScope] で全体無効化する。
///
/// - build で throw するのは `reviewById` のローカル NotFound のみで、
///   変化しないキャッシュへのリトライは無意味。
/// - 書籍検索は `AsyncValue.guard`（メソッド内）で失敗を捕捉するためリトライ対象外。
/// - レビュー一覧はローカル読みのみで throw しない。
///
/// [ProviderScope.retry] / [ProviderContainer] に渡して使う。
Duration? noRetry(int retryCount, Object error) => null;

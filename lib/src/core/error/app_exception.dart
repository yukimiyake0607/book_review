/// アプリ内で扱う失敗を型として表す sealed クラス階層。
///
/// 例外の握りつぶしを避け、失敗を「網羅的に分岐できる型」として扱うために用いる。
/// リポジトリ層は外部由来の例外（[DioException] など）をこの型へマッピングして送出し、
/// presentation 層は `AsyncValue.error` から受け取ってユーザー向けメッセージに変換する。
sealed class AppException implements Exception {
  const AppException(this.message);

  /// ユーザーに提示できる日本語メッセージ。
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// ネットワーク不通・タイムアウトなど、接続自体に失敗した。
final class NetworkException extends AppException {
  const NetworkException([super.message = 'ネットワークに接続できませんでした。通信環境を確認してください。']);
}

/// リクエストは届いたが、対象リソースが存在しない（404）。
final class NotFoundException extends AppException {
  const NotFoundException([super.message = '対象が見つかりませんでした。']);
}

/// サーバ側のエラー（5xx）。
final class ServerException extends AppException {
  const ServerException([super.message = 'サーバでエラーが発生しました。時間をおいて再度お試しください。']);
}

/// 入力値がドメインの制約を満たさない（クライアント側バリデーション、または400）。
final class ValidationException extends AppException {
  const ValidationException(super.message);
}

/// 上記のいずれにも当てはまらない予期しない失敗。
final class UnknownException extends AppException {
  const UnknownException([super.message = '予期しないエラーが発生しました。']);
}

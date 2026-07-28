import 'package:dio/dio.dart';

import 'app_exception.dart';

/// 外部由来の例外を、ドメインが扱える [AppException] へ変換する。
///
/// リポジトリ実装はこの関数を通して失敗を型付けし、上位層に生の [DioException] を漏らさない。
AppException mapDioException(Object error) {
  if (error is AppException) {
    return error;
  }
  if (error is! DioException) {
    return const UnknownException();
  }

  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
    case DioExceptionType.connectionError:
      return const NetworkException();
    case DioExceptionType.badCertificate:
      return const NetworkException('安全な接続を確立できませんでした。');
    case DioExceptionType.cancel:
      return const UnknownException('通信がキャンセルされました。');
    case DioExceptionType.badResponse:
      return _mapStatus(error.response?.statusCode);
    case DioExceptionType.unknown:
      return const UnknownException();
  }
}

/// HTTP ステータスコードから [AppException] を決定する。
AppException mapStatusCode(int? statusCode) => _mapStatus(statusCode);

AppException _mapStatus(int? statusCode) {
  if (statusCode == null) {
    return const UnknownException();
  }
  if (statusCode == 404) {
    return const NotFoundException();
  }
  if (statusCode == 400) {
    return const ValidationException('入力内容に誤りがあります。');
  }
  if (statusCode >= 500) {
    return const ServerException();
  }
  return const UnknownException();
}

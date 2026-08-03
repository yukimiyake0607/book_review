import 'book.dart';

/// 書籍検索のリポジトリインターフェース（domain 層の契約）。
///
/// 実装は infrastructure 層に置き、依存性逆転により domain は実装を知らない。
/// 失敗は [AppException]（sealed）を送出して表現する。
abstract interface class BookRepository {
  /// キーワードで書籍を検索する。
  ///
  /// 該当なしの場合は空リストを返す（「空」は成功状態として扱い、例外にはしない）。
  ///
  /// ページネーションは契約に含めない。1画面分で題材として十分であり、
  /// 使わない拡張ポイントを残さないため。必要になった時点でこの契約を拡張する。
  Future<List<Book>> search(String keyword);
}

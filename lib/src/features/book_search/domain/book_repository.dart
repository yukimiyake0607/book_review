import 'book.dart';

/// 書籍検索のリポジトリインターフェース（domain 層の契約）。
///
/// 実装は infrastructure 層に置き、依存性逆転により domain は実装を知らない。
/// 失敗は [AppException]（sealed）を送出して表現する。
abstract interface class BookRepository {
  /// キーワードで書籍を検索する。
  ///
  /// 該当なしの場合は空リストを返す（「空」は成功状態として扱い、例外にはしない）。
  Future<List<Book>> search(String keyword, {int page = 1});
}

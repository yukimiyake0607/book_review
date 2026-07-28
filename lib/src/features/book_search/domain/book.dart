import 'package:freezed_annotation/freezed_annotation.dart';

part 'book.freezed.dart';

/// 書籍（検索結果）を表すドメインエンティティ。
///
/// 外部書籍データベース由来のデータだが、ドメインでは API の DTO とは切り離した
/// 不変モデルとして扱う（変換は infrastructure 層で行う）。
@freezed
class Book with _$Book {
  const factory Book({
    required String id,
    required String title,
    required List<String> authors,
    String? thumbnailUrl,
  }) = _Book;

  const Book._();

  /// 著者名を表示用に連結する（未設定なら「著者不明」）。
  String get authorsLabel => authors.isEmpty ? '著者不明' : authors.join(', ');
}

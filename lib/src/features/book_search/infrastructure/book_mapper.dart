import '../../../api/models/book.dart' as dto;
import '../domain/book.dart';

/// API の DTO（[dto.Book]）とドメインの [Book] を相互変換する。
///
/// 変換をこの1箇所に閉じ込めることで、API 仕様の変更がドメインへ波及する範囲を局所化する。
extension BookDtoMapper on dto.Book {
  Book toDomain() => Book(
    id: id,
    title: title,
    authors: List.unmodifiable(authors),
    thumbnailUrl: thumbnailUrl,
  );
}

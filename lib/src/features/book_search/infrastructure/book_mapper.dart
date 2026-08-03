import '../domain/book.dart';
import 'dto/google_books_dto.dart';

extension GoogleBookItemDtoMapper on GoogleBookItemDto {
  Book toDomain() {
    final info = volumeInfo;
    final title = info?.title?.trim();
    return Book(
      id: id,
      title: (title == null || title.isEmpty) ? 'タイトル不明' : title,
      authors: info?.authors ?? const [],
      thumbnailUrl: _httpsUrl(
        info?.imageLinks?.thumbnail ?? info?.imageLinks?.smallThumbnail,
      ),
    );
  }
}

/// `http://` を `https://` に置換する（iOS の ATS 対策）。
String? _httpsUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  if (url.startsWith('http://')) {
    return 'https://${url.substring('http://'.length)}';
  }
  return url;
}

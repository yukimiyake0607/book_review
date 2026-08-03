import 'package:book_review/src/features/book_search/infrastructure/book_mapper.dart';
import 'package:book_review/src/features/book_search/infrastructure/dto/google_books_dto.dart';
import 'package:flutter_test/flutter_test.dart';

/// Google Books のレスポンスは volumeInfo 以下がほぼすべて optional なため、
/// 欠落パターンごとに domain の [Book] が破綻しないことを mapper 単体で確認する。
void main() {
  GoogleBookItemDto itemWith({
    String id = 'book-1',
    GoogleVolumeInfoDto? volumeInfo,
  }) {
    return GoogleBookItemDto(id: id, volumeInfo: volumeInfo);
  }

  group('タイトル', () {
    const cases = <({String? title, String expected, String reason})>[
      (title: null, expected: 'タイトル不明', reason: 'title キーが無い'),
      (title: '', expected: 'タイトル不明', reason: 'title が空文字'),
      (title: '   ', expected: 'タイトル不明', reason: 'title が空白のみ'),
      (
        title: '  リーダブルコード  ',
        expected: 'リーダブルコード',
        reason: '前後の空白は落とす',
      ),
    ];

    for (final c in cases) {
      test('${c.reason} → "${c.expected}"', () {
        final book = itemWith(
          volumeInfo: GoogleVolumeInfoDto(title: c.title),
        ).toDomain();

        expect(book.title, c.expected);
      });
    }
  });

  group('著者', () {
    test('authors が無ければ空リストになる（null を domain へ持ち込まない）', () {
      final book = itemWith(
        volumeInfo: const GoogleVolumeInfoDto(title: 'テスト駆動開発'),
      ).toDomain();

      expect(book.authors, isEmpty);
      expect(book.authorsLabel, '著者不明');
    });

    test('authors はそのまま domain へ渡る', () {
      final book = itemWith(
        volumeInfo: const GoogleVolumeInfoDto(
          title: 'テスト駆動開発',
          authors: ['Kent Beck', '和田卓人'],
        ),
      ).toDomain();

      expect(book.authors, ['Kent Beck', '和田卓人']);
      expect(book.authorsLabel, 'Kent Beck, 和田卓人');
    });
  });

  group('書影URL', () {
    const cases =
        <({String? thumbnail, String? small, String? expected, String reason})>[
          (
            thumbnail: 'https://example.com/large.jpg',
            small: 'https://example.com/small.jpg',
            expected: 'https://example.com/large.jpg',
            reason: '両方あれば thumbnail を優先する',
          ),
          (
            thumbnail: null,
            small: 'https://example.com/small.jpg',
            expected: 'https://example.com/small.jpg',
            reason: 'thumbnail が無ければ smallThumbnail にフォールバックする',
          ),
          (
            thumbnail: 'http://example.com/large.jpg',
            small: null,
            expected: 'https://example.com/large.jpg',
            reason: 'http は https へ置換する（iOS の ATS 対策）',
          ),
          (
            thumbnail: null,
            small: null,
            expected: null,
            reason: 'imageLinks が空なら null',
          ),
        ];

    for (final c in cases) {
      test(c.reason, () {
        final book = itemWith(
          volumeInfo: GoogleVolumeInfoDto(
            title: '書影テスト',
            imageLinks: GoogleImageLinksDto(
              thumbnail: c.thumbnail,
              smallThumbnail: c.small,
            ),
          ),
        ).toDomain();

        expect(book.thumbnailUrl, c.expected);
      });
    }

    test('imageLinks 自体が無ければ null', () {
      final book = itemWith(
        volumeInfo: const GoogleVolumeInfoDto(title: '書影テスト'),
      ).toDomain();

      expect(book.thumbnailUrl, isNull);
    });

    test('https 以外のスキームは置換せずそのまま返す', () {
      final book = itemWith(
        volumeInfo: const GoogleVolumeInfoDto(
          title: '書影テスト',
          imageLinks: GoogleImageLinksDto(
            thumbnail: 'data:image/png;base64,AAAA',
          ),
        ),
      ).toDomain();

      expect(book.thumbnailUrl, 'data:image/png;base64,AAAA');
    });
  });

  test('volumeInfo ごと欠落していても Book を組み立てられる', () {
    final book = itemWith(id: 'book-9').toDomain();

    expect(book.id, 'book-9');
    expect(book.title, 'タイトル不明');
    expect(book.authors, isEmpty);
    expect(book.thumbnailUrl, isNull);
  });
}

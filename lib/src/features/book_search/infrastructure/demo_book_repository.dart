import 'dart:convert';

import 'package:book_review/src/features/book_search/domain/book.dart';
import 'package:book_review/src/features/book_search/domain/book_repository.dart';
import 'package:book_review/src/features/book_search/infrastructure/book_mapper.dart';
import 'package:book_review/src/features/book_search/infrastructure/dto/google_books_dto.dart';
import 'package:flutter/services.dart';

/// デモモード（`Flavor.demo`）用の書籍リポジトリ。
///
/// clone 直後に APIキーなしで検索フローを触れるようにするためのもので、
/// 同梱した Google Books のレスポンス（[assetPath]）を読み、実 API 実装と同じ
/// DTO / mapper を通して domain の [Book] へ変換する。
/// キーワードはタイトルと著者名の部分一致（大文字小文字を無視）で絞り込む。
class DemoBookRepository implements BookRepository {
  DemoBookRepository({
    AssetBundle? bundle,
    this.assetPath = _defaultAssetPath,
    this.latency = const Duration(milliseconds: 400),
  }) : _bundle = bundle ?? rootBundle;

  static const _defaultAssetPath = 'assets/demo/google_books_volumes.json';

  final AssetBundle _bundle;

  /// 読み込む同梱データのパス。
  final String assetPath;

  /// 読み込み中の状態を確認できるように挟む待ち時間。
  final Duration latency;

  List<Book>? _books;

  /// 同梱データから該当する書籍を返す。該当なしは空リスト。
  ///
  /// 実 API と違いページングは行わないため、[page] は無視する。
  @override
  Future<List<Book>> search(String keyword, {int page = 1}) async {
    await Future<void>.delayed(latency);

    final query = keyword.trim().toLowerCase();
    if (query.isEmpty) return const [];

    final books = _books ??= await _load();
    return books.where((book) => _matches(book, query)).toList();
  }

  Future<List<Book>> _load() async {
    final raw = await _bundle.loadString(assetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final dto = GoogleBooksResponseDto.fromJson(json);
    return dto.items?.map((item) => item.toDomain()).toList() ?? const [];
  }

  bool _matches(Book book, String query) {
    if (book.title.toLowerCase().contains(query)) return true;
    return book.authors.any((author) => author.toLowerCase().contains(query));
  }
}

import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../core/error/app_exception.dart';
import '../domain/book.dart';
import '../domain/book_repository.dart';
import 'book_mapper.dart';
import 'dto/google_books_dto.dart';

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
  @override
  Future<List<Book>> search(String keyword) async {
    await Future<void>.delayed(latency);

    final query = keyword.trim().toLowerCase();
    if (query.isEmpty) return const [];

    final books = _books ??= await _load();
    return books.where((book) => _matches(book, query)).toList();
  }

  Future<List<Book>> _load() async {
    try {
      final raw = await _bundle.loadString(assetPath);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final dto = GoogleBooksResponseDto.fromJson(json);
      return dto.items?.map((item) => item.toDomain()).toList() ?? const [];
    } on Object {
      // アセットの欠落・JSON 破損はどちらも「デモデータが使えない」状態でしかない。
      // 不正な構造による型キャスト失敗（TypeError＝Error 系）も含めて受け、
      // 実 API 実装と同じく infrastructure の境界で AppException に型付けする。
      throw const UnknownException('デモ用データを読み込めませんでした。');
    }
  }

  bool _matches(Book book, String query) {
    if (book.title.toLowerCase().contains(query)) return true;
    return book.authors.any((author) => author.toLowerCase().contains(query));
  }
}

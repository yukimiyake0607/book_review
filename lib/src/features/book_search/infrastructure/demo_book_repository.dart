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

  /// 同梱データを読み、実 API 実装と同じ DTO / mapper を通して domain へ変換する。
  ///
  /// JSON の破損・構造不一致は「デモデータが使えない」状態でしかないため、
  /// infrastructure の境界で [UnknownException] に型付けする。一方でアセット自体の
  /// 欠落は Flutter が `FlutterError`（Error 系）で通知する。同梱漏れはビルドの
  /// 不備＝バグなので捕まえず、グローバルハンドラへ伝播させる。
  Future<List<Book>> _load() async {
    try {
      final raw = await _bundle.loadString(assetPath);
      // 素のキャストは型不一致を TypeError（Error 系）にしてしまうため、
      // 外部データの構造は自分で確かめ、Exception として表す。
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('デモ用データが JSON オブジェクトではありません。');
      }
      final dto = GoogleBooksResponseDto.fromJson(decoded);
      return dto.items?.map((item) => item.toDomain()).toList() ?? const [];
    } on Exception {
      throw const UnknownException('デモ用データを読み込めませんでした。');
    }
  }

  bool _matches(Book book, String query) {
    if (book.title.toLowerCase().contains(query)) return true;
    return book.authors.any((author) => author.toLowerCase().contains(query));
  }
}

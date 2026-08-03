import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../common_widgets/app_error_view.dart';
import '../core/error/app_exception.dart';
import '../features/book_search/domain/book.dart';
import '../features/book_search/presentation/book_search_screen.dart';
import '../features/reviews/presentation/review_detail_screen.dart';
import '../features/reviews/presentation/review_editor_screen.dart';
import '../features/reviews/presentation/review_list_screen.dart';

part 'app_router.g.dart';

/// アプリの画面遷移を定義するパス。
///
/// 文字列リテラルの散在を避け、遷移先を型のように扱えるようにまとめている。
abstract final class AppRoute {
  static const reviews = '/';
  static const search = '/search';
  static const reviewNew = '/reviews/new';

  /// go_router へ渡すパスパターン。定義側と遷移先の生成
  /// （[reviewDetail] / [reviewEdit]）で同じ形を二重管理しないよう隣に置く。
  static const reviewDetailPattern = '/reviews/:id';
  static const reviewEditPattern = '/reviews/:id/edit';

  static String reviewDetail(String id) => '/reviews/$id';
  static String reviewEdit(String id) => '/reviews/$id/edit';
}

/// go_router を供給する Provider。
///
/// ルーティング定義を Riverpod 管理下に置くことで、将来 認証状態などに応じた
/// リダイレクト（`redirect`）を Provider 経由で差し込めるようにしている（ADR-0004）。
@Riverpod(keepAlive: true)
GoRouter goRouter(Ref ref) {
  return GoRouter(
    initialLocation: AppRoute.reviews,
    // 定義に無いパス（手打ちの URL・古いリンク）の受け口。
    errorBuilder: (context, state) =>
        const _RouteNotFoundScreen(message: 'お探しの画面は見つかりませんでした。'),
    routes: [
      GoRoute(
        path: AppRoute.reviews,
        builder: (context, state) => const ReviewListScreen(),
      ),
      GoRoute(
        path: AppRoute.search,
        builder: (context, state) => const BookSearchScreen(),
      ),
      // '/reviews/new' は ':id' より先に定義して literal 一致を優先させる。
      GoRoute(
        path: AppRoute.reviewNew,
        builder: (context, state) {
          final book = state.extra;
          // 検索結果の Book は端末に永続化しておらず URL からは復元できないため、
          // この画面だけは extra で運ぶ。extra が無い遷移（ディープリンク等）は
          // 登録対象が決まらないので、書籍を選び直してもらう。
          // `as Book?` で受けると型不一致が TypeError（Error 系）になり、外部から
          // 与えられた値でバグ扱いのクラッシュを起こすため is で確かめる。
          if (book is! Book) {
            return const _RouteNotFoundScreen(
              message: '登録する書籍が指定されていません。書籍を検索して選び直してください。',
            );
          }
          return ReviewEditorScreen.create(book: book);
        },
      ),
      GoRoute(
        path: AppRoute.reviewDetailPattern,
        builder: (context, state) =>
            ReviewDetailScreen(reviewId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoute.reviewEditPattern,
        // extra ではなく URL の id から読み直す。extra は復元されないため、
        // ディープリンクやプロセス再生成の後でも開けるようにする。
        builder: (context, state) =>
            ReviewEditorLoader(reviewId: state.pathParameters['id']!),
      ),
    ],
  );
}

/// 解決できない遷移を知らせる画面。
///
/// 未定義のパス（`errorBuilder`）と、必要な値が渡っていない遷移
/// （`/reviews/new` に書籍が無い場合）の両方で使う。ディープリンクで直接
/// 開かれると戻り先が無いため、ホームへの導線を必ず出して行き止まりにしない。
class _RouteNotFoundScreen extends StatelessWidget {
  const _RouteNotFoundScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('画面が見つかりません')),
      body: AppErrorView(
        error: NotFoundException(message),
        onRetry: () => context.go(AppRoute.reviews),
        retryLabel: 'ホームへ戻る',
      ),
    );
  }
}

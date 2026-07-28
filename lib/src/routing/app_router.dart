import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/book_search/domain/book.dart';
import '../features/book_search/presentation/book_search_screen.dart';
import '../features/reviews/domain/review.dart';
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
        builder: (context, state) =>
            ReviewEditorScreen(book: state.extra as Book?),
      ),
      GoRoute(
        path: '/reviews/:id',
        builder: (context, state) =>
            ReviewDetailScreen(reviewId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/reviews/:id/edit',
        builder: (context, state) =>
            ReviewEditorScreen(existing: state.extra as Review?),
      ),
    ],
  );
}

import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../features/book_search/presentation/book_search_screen.dart';
import '../features/reviews/presentation/review_detail_screen.dart';
import '../features/reviews/presentation/review_list_screen.dart';

/// アプリの画面遷移を定義するパス。
///
/// 文字列リテラルの散在を避け、遷移先を型のように扱えるようにまとめている。
abstract final class AppRoute {
  static const reviews = '/';
  static const search = '/search';

  /// レビュー詳細への絶対パスを組み立てる。
  static String reviewDetail(String id) => '/reviews/$id';
}

/// go_router を供給する Provider。
///
/// ルーティング定義を Riverpod 管理下に置くことで、将来 認証状態などに応じた
/// リダイレクト（`redirect`）を Provider 経由で差し込めるようにしている（ADR-0004）。
final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoute.reviews,
    routes: [
      GoRoute(
        path: AppRoute.reviews,
        builder: (context, state) => const ReviewListScreen(),
        routes: [
          GoRoute(
            path: 'reviews/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return ReviewDetailScreen(reviewId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRoute.search,
        builder: (context, state) => const BookSearchScreen(),
      ),
    ],
  );
});

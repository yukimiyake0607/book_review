import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../common_widgets/app_error_view.dart';
import '../../../common_widgets/rating_stars.dart';
import '../../../routing/app_router.dart';
import '../domain/review.dart';
import 'review_list_controller.dart';

/// レビュー一覧画面（ホーム）。新着順で表示し、プルリフレッシュで再取得する。
class ReviewListScreen extends ConsumerWidget {
  const ReviewListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = ref.watch(reviewListControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('マイレビュー'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: '書籍を検索して追加',
            onPressed: () => context.push(AppRoute.search),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoute.search),
        icon: const Icon(Icons.add),
        label: const Text('レビューを追加'),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(reviewListControllerProvider.notifier).refresh(),
        child: reviews.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ScrollableFill(
            child: AppErrorView(
              error: error,
              onRetry: () => ref.invalidate(reviewListControllerProvider),
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const _ScrollableFill(child: _EmptyReviews());
            }
            return ListView.separated(
              padding: const EdgeInsets.only(bottom: 96),
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) =>
                  _ReviewTile(review: items[index]),
            );
          },
        ),
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        review.bookTitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          RatingStars(rating: review.rating),
          if (review.hasComment) ...[
            const SizedBox(height: 4),
            Text(review.comment!, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
      isThreeLine: review.hasComment,
      // 読了日があればそれを優先。未設定なら登録日を表示する（どちらもラベルで区別）。
      trailing: _DateLabel(
        label: review.finishedOn != null ? '読了' : '登録',
        date: review.finishedOn ?? review.createdAt,
      ),
      onTap: () => context.push(AppRoute.reviewDetail(review.id)),
    );
  }
}

class _DateLabel extends StatelessWidget {
  const _DateLabel({required this.label, required this.date});

  final String label;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: style),
        Text(DateFormat('yyyy/MM/dd').format(date), style: style),
      ],
    );
  }
}

class _EmptyReviews extends StatelessWidget {
  const _EmptyReviews();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outline;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.rate_review_outlined, size: 48, color: color),
            const SizedBox(height: 16),
            Text(
              'まだレビューがありません。\n右下のボタンから書籍を検索して追加しましょう。',
              textAlign: TextAlign.center,
              style: TextStyle(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

/// RefreshIndicator 配下でも空/エラー表示を画面いっぱいにし、かつ引っ張って更新できるようにする。
class _ScrollableFill extends StatelessWidget {
  const _ScrollableFill({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: child,
        ),
      ),
    );
  }
}

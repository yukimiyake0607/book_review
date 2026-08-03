import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../common_widgets/app_error_view.dart';
import '../../../common_widgets/rating_stars.dart';
import '../../../core/error/app_exception.dart';
import '../../../routing/app_router.dart';
import '../domain/rating.dart';
import '../domain/review.dart';
import 'review_list_controller.dart';

/// F-03 レビュー詳細画面。編集・削除への入口を持つ。
class ReviewDetailScreen extends ConsumerWidget {
  const ReviewDetailScreen({super.key, required this.reviewId});

  final String reviewId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final review = ref.watch(reviewByIdProvider(reviewId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('レビュー詳細'),
        actions: [
          if (review.value != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: '編集',
              onPressed: () => context.push(
                AppRoute.reviewEdit(reviewId),
                extra: review.value,
              ),
            ),
        ],
      ),
      body: review.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppErrorView(
          error: error,
          onRetry: () => ref.invalidate(reviewByIdProvider(reviewId)),
        ),
        data: (data) => _ReviewDetailBody(
          review: data,
          onDelete: () => _confirmAndDelete(context, ref, data),
        ),
      ),
    );
  }

  Future<void> _confirmAndDelete(
    BuildContext context,
    WidgetRef ref,
    Review review,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('レビューを削除しますか？'),
        content: Text('「${review.bookTitle}」のレビューを削除します。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      await ref.read(reviewListControllerProvider.notifier).remove(review.id);
      // 非同期完了中に画面を離れている可能性があるため、遷移前に必ず確認する。
      // （既に離れている場合に pop すると別画面を閉じてしまう）
      if (!context.mounted) return;
      router.pop();
      messenger.showSnackBar(const SnackBar(content: Text('レビューを削除しました。')));
    } on AppException catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}

class _ReviewDetailBody extends StatelessWidget {
  const _ReviewDetailBody({required this.review, required this.onDelete});

  final Review review;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(review.bookTitle, style: textTheme.headlineSmall),
        const SizedBox(height: 12),
        Row(
          children: [
            RatingStars(rating: review.rating, size: 24),
            const SizedBox(width: 8),
            Text('${review.rating.value} / ${Rating.max}'),
          ],
        ),
        const SizedBox(height: 16),
        if (review.finishedOn != null)
          _MetaRow(
            label: '読了日',
            value: DateFormat('yyyy年M月d日').format(review.finishedOn!),
          ),
        _MetaRow(
          label: '登録日',
          value: DateFormat('yyyy年M月d日').format(review.createdAt),
        ),
        const Divider(height: 32),
        Text(
          review.hasComment ? review.comment! : '（感想は未記入です）',
          style: textTheme.bodyLarge,
        ),
        const SizedBox(height: 32),
        OutlinedButton.icon(
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline),
          label: const Text('このレビューを削除'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
        ),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Text(value),
        ],
      ),
    );
  }
}

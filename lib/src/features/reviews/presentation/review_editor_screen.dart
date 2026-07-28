import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/error/app_exception.dart';
import '../../book_search/domain/book.dart';
import '../domain/rating.dart';
import '../domain/review.dart';
import '../domain/review_draft.dart';
import 'review_list_controller.dart';

/// F-02 レビューの登録／編集フォーム。
///
/// - 検索結果から来た場合は [book] が渡され「新規作成」
/// - 詳細から来た場合は [existing] が渡され「編集」
class ReviewEditorScreen extends HookConsumerWidget {
  const ReviewEditorScreen({super.key, this.book, this.existing})
    : assert(book != null || existing != null, 'book か existing のいずれかが必要');

  final Book? book;
  final Review? existing;

  bool get _isEditing => existing != null;
  String get _bookId => existing?.bookId ?? book!.id;
  String get _bookTitle => existing?.bookTitle ?? book!.title;
  String? get _thumbnail => existing?.bookThumbnailUrl ?? book?.thumbnailUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rating = useState<int>(existing?.rating.value ?? 0);
    final commentController = useTextEditingController(
      text: existing?.comment ?? '',
    );
    final finishedOn = useState<DateTime?>(existing?.finishedOn);
    final isSaving = useState<bool>(false);

    Future<void> save() async {
      if (rating.value < Rating.min) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('評価（★）を選択してください。')));
        return;
      }
      final comment = commentController.text.trim();
      final draft = ReviewDraft(
        bookId: _bookId,
        bookTitle: _bookTitle,
        bookThumbnailUrl: _thumbnail,
        rating: Rating.parse(rating.value),
        comment: comment.isEmpty ? null : comment,
        finishedOn: finishedOn.value,
      );

      final messenger = ScaffoldMessenger.of(context);
      final router = GoRouter.of(context);
      final controller = ref.read(reviewListControllerProvider.notifier);

      isSaving.value = true;
      try {
        if (_isEditing) {
          await controller.edit(existing!.id, draft);
        } else {
          await controller.add(draft);
        }
        // 一覧の楽観的更新は即時に反映済み。フォームを閉じる。
        router.pop();
        messenger.showSnackBar(
          SnackBar(content: Text(_isEditing ? 'レビューを更新しました。' : 'レビューを登録しました。')),
        );
      } on AppException catch (e) {
        // 失敗時は一覧側でロールバック済み。フォームは残してエラーを通知する。
        isSaving.value = false;
        messenger.showSnackBar(SnackBar(content: Text(e.message)));
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'レビューを編集' : 'レビューを登録')),
      body: AbsorbPointer(
        absorbing: isSaving.value,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _BookHeader(title: _bookTitle, thumbnailUrl: _thumbnail),
            const SizedBox(height: 24),
            Text('評価', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _RatingInput(
              value: rating.value,
              onChanged: (v) => rating.value = v,
            ),
            const SizedBox(height: 24),
            Text('感想', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: commentController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: '感じたこと・印象に残った点など（任意）',
              ),
            ),
            const SizedBox(height: 24),
            Text('読了日', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _FinishedOnField(
              value: finishedOn.value,
              onChanged: (v) => finishedOn.value = v,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: isSaving.value ? null : save,
              icon: isSaving.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(_isEditing ? '更新する' : '登録する'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookHeader extends StatelessWidget {
  const _BookHeader({required this.title, required this.thumbnailUrl});

  final String title;
  final String? thumbnailUrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (thumbnailUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.network(
              thumbnailUrl!,
              width: 48,
              height: 68,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Icon(Icons.book_outlined),
            ),
          )
        else
          const Icon(Icons.book_outlined, size: 40),
        const SizedBox(width: 12),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
      ],
    );
  }
}

class _RatingInput extends StatelessWidget {
  const _RatingInput({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        for (var i = Rating.min; i <= Rating.max; i++)
          IconButton(
            iconSize: 36,
            onPressed: () => onChanged(i),
            icon: Icon(
              i <= value ? Icons.star : Icons.star_border,
              color: color,
            ),
          ),
      ],
    );
  }
}

class _FinishedOnField extends StatelessWidget {
  const _FinishedOnField({required this.value, required this.onChanged});

  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            value == null ? '未設定' : DateFormat('yyyy年M月d日').format(value!),
          ),
        ),
        if (value != null)
          TextButton(
            onPressed: () => onChanged(null),
            child: const Text('クリア'),
          ),
        TextButton.icon(
          icon: const Icon(Icons.calendar_today, size: 18),
          label: const Text('日付を選択'),
          onPressed: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: value ?? now,
              firstDate: DateTime(2000),
              lastDate: now,
            );
            if (picked != null) {
              onChanged(picked);
            }
          },
        ),
      ],
    );
  }
}

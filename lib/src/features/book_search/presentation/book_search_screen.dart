import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../common_widgets/app_error_view.dart';
import '../../../routing/app_router.dart';
import '../domain/book.dart';
import 'book_search_controller.dart';

/// F-01 書籍検索画面。
///
/// loading / error / empty / success の各状態を明示的に描き分ける。
class BookSearchScreen extends HookConsumerWidget {
  const BookSearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(bookSearchControllerProvider.notifier);
    final state = ref.watch(bookSearchControllerProvider);
    final textController = useTextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('書籍を検索'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: textController,
              textInputAction: TextInputAction.search,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'タイトル・著者名で検索',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    textController.clear();
                    controller.clear();
                  },
                ),
                filled: true,
              ),
              onSubmitted: controller.search,
            ),
          ),
        ),
      ),
      body: _BookSearchBody(
        state: state,
        onRetry: () => controller.search(state.keyword),
      ),
    );
  }
}

class _BookSearchBody extends StatelessWidget {
  const _BookSearchBody({required this.state, required this.onRetry});

  final BookSearchState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (!state.hasSearched) {
      return const _CenteredHint(
        icon: Icons.menu_book_outlined,
        message: 'キーワードを入力して書籍を検索してください。',
      );
    }
    return state.books.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => AppErrorView(error: error, onRetry: onRetry),
      data: (books) {
        if (books.isEmpty) {
          return const _CenteredHint(
            icon: Icons.search_off,
            message: '該当する書籍が見つかりませんでした。',
          );
        }
        return ListView.separated(
          itemCount: books.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) => _BookTile(book: books[index]),
        );
      },
    );
  }
}

class _BookTile extends StatelessWidget {
  const _BookTile({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _Thumbnail(url: book.thumbnailUrl),
      title: Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        book.authorsLabel,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
      // 選択した書籍を持ってレビュー作成画面へ遷移する（F-02 へ接続）。
      onTap: () => context.push(AppRoute.reviewNew, extra: book),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    const width = 40.0;
    const height = 56.0;
    if (url == null) {
      return Container(
        width: width,
        height: height,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Icon(Icons.book_outlined, size: 20),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.network(
        url!,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const SizedBox(
          width: width,
          height: height,
          child: Icon(Icons.book_outlined, size: 20),
        ),
      ),
    );
  }
}

class _CenteredHint extends StatelessWidget {
  const _CenteredHint({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outline;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

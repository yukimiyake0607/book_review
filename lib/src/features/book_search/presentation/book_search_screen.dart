import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// F-01 書籍検索画面（feature phase で実装）。
class BookSearchScreen extends ConsumerWidget {
  const BookSearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('書籍を検索')),
      body: const Center(child: Text('Book search (coming soon)')),
    );
  }
}

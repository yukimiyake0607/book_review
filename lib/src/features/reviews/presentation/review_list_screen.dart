import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// F-03 レビュー一覧画面（feature phase で実装）。
class ReviewListScreen extends ConsumerWidget {
  const ReviewListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('マイレビュー')),
      body: const Center(child: Text('Review list (coming soon)')),
    );
  }
}

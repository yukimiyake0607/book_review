import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// F-03 レビュー詳細画面（feature phase で実装）。
class ReviewDetailScreen extends ConsumerWidget {
  const ReviewDetailScreen({super.key, required this.reviewId});

  final String reviewId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('レビュー詳細')),
      body: Center(child: Text('Review detail: $reviewId (coming soon)')),
    );
  }
}

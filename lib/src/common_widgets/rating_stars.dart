import 'package:flutter/material.dart';

import '../features/reviews/domain/rating.dart';

/// 評価（★）を表示する。読み取り専用。
class RatingStars extends StatelessWidget {
  const RatingStars({super.key, required this.rating, this.size = 18});

  final Rating rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = Rating.min; i <= Rating.max; i++)
          Icon(
            i <= rating.value ? Icons.star : Icons.star_border,
            size: size,
            color: color,
          ),
      ],
    );
  }
}

import 'package:freezed_annotation/freezed_annotation.dart';

import 'rating.dart';

part 'review.freezed.dart';

/// 登録済みのレビューを表すドメインエンティティ（不変）。
///
/// 一覧表示のため書籍名・サムネイルを非正規化して保持する。
/// API/DB の表現（DTO）とは分離し、境界で相互変換する。
@freezed
abstract class Review with _$Review {
  const factory Review({
    required String id,
    required String bookId,
    required String bookTitle,
    required Rating rating,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? bookThumbnailUrl,
    String? comment,
    DateTime? finishedOn,
  }) = _Review;

  const Review._();

  bool get hasComment => comment != null && comment!.trim().isNotEmpty;
}

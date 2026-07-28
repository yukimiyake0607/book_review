// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'review.g.dart';

@JsonSerializable()
class Review {
  const Review({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    required this.rating,
    required this.createdAt,
    required this.updatedAt,
    this.bookThumbnailUrl,
    this.comment,
    this.finishedOn,
  });

  factory Review.fromJson(Map<String, Object?> json) => _$ReviewFromJson(json);

  final String id;
  final String bookId;

  /// 一覧表示のために書籍名を非正規化して保持する
  final String bookTitle;
  final String? bookThumbnailUrl;
  final int rating;
  final String? comment;

  /// 読了日（YYYY-MM-DD）
  final DateTime? finishedOn;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toJson() => _$ReviewToJson(this);
}

// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'review_input.g.dart';

@JsonSerializable()
class ReviewInput {
  const ReviewInput({
    required this.bookId,
    required this.bookTitle,
    required this.rating,
    this.bookThumbnailUrl,
    this.comment,
    this.finishedOn,
  });

  factory ReviewInput.fromJson(Map<String, Object?> json) =>
      _$ReviewInputFromJson(json);

  final String bookId;
  final String bookTitle;
  final String? bookThumbnailUrl;
  final int rating;
  final String? comment;
  final DateTime? finishedOn;

  Map<String, Object?> toJson() => _$ReviewInputToJson(this);
}

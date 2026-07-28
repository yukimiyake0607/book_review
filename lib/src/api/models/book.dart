// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'book.g.dart';

@JsonSerializable()
class Book {
  const Book({
    required this.id,
    required this.title,
    required this.authors,
    this.thumbnailUrl,
  });

  factory Book.fromJson(Map<String, Object?> json) => _$BookFromJson(json);

  /// 書籍の一意ID（外部DB由来）
  final String id;
  final String title;
  final List<String> authors;
  final String? thumbnailUrl;

  Map<String, Object?> toJson() => _$BookToJson(this);
}

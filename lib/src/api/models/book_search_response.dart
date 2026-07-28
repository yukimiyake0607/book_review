// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'book.dart';

part 'book_search_response.g.dart';

@JsonSerializable()
class BookSearchResponse {
  const BookSearchResponse({
    required this.items,
    required this.page,
    required this.hasNextPage,
  });

  factory BookSearchResponse.fromJson(Map<String, Object?> json) =>
      _$BookSearchResponseFromJson(json);

  final List<Book> items;
  final int page;
  final bool hasNextPage;

  Map<String, Object?> toJson() => _$BookSearchResponseToJson(this);
}

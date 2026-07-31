import 'package:freezed_annotation/freezed_annotation.dart';

part 'review_dto.freezed.dart';
part 'review_dto.g.dart';

/// ローカル永続用のレビューDTO。
/// 
/// domainの　 [Review]とは分離し、SharedPreferencesにはこのJSON型で保存する。
@freezed
abstract class ReviewDto with _$ReviewDto {
  const factory ReviewDto({
    required String id,
    required String bookId,
    required String bookTitle,
    // Ratingはdomain専用にするので、DTOではint型で保存する
    required int rating,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? bookThumbnailUrl,
    String? comment,
    DateTime? finishedOn,
  }) = _ReviewDto;
  factory ReviewDto.fromJson(Map<String, dynamic> json) =>
      _$ReviewDtoFromJson(json);
}
import 'package:freezed_annotation/freezed_annotation.dart';

part 'google_books_dto.g.dart';
part 'google_books_dto.freezed.dart';

@freezed
abstract class GoogleBooksResponseDto with _$GoogleBooksResponseDto {
  const factory GoogleBooksResponseDto({List<GoogleBookItemDto>? items}) =
      _GoogleBooksResponseDto;
  factory GoogleBooksResponseDto.fromJson(Map<String, dynamic> json) =>
      _$GoogleBooksResponseDtoFromJson(json);
}

@freezed
abstract class GoogleBookItemDto with _$GoogleBookItemDto {
  const factory GoogleBookItemDto({
    required String id,
    GoogleVolumeInfoDto? volumeInfo,
  }) = _GoogleBookItemDto;
  factory GoogleBookItemDto.fromJson(Map<String, dynamic> json) =>
      _$GoogleBookItemDtoFromJson(json);
}

@freezed
abstract class GoogleVolumeInfoDto with _$GoogleVolumeInfoDto {
  const factory GoogleVolumeInfoDto({
    String? title,
    List<String>? authors,
    GoogleImageLinksDto? imageLinks,
  }) = _GoogleVolumeInfoDto;
  factory GoogleVolumeInfoDto.fromJson(Map<String, dynamic> json) =>
      _$GoogleVolumeInfoDtoFromJson(json);
}

@freezed
abstract class GoogleImageLinksDto with _$GoogleImageLinksDto {
  const factory GoogleImageLinksDto({
    String? thumbnail,
    String? smallThumbnail,
  }) = _GoogleImageLinksDto;

  factory GoogleImageLinksDto.fromJson(Map<String, dynamic> json) =>
      _$GoogleImageLinksDtoFromJson(json);
}

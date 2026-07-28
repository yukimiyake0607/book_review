// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'api_error.g.dart';

@JsonSerializable()
class ApiError {
  const ApiError({required this.code, required this.message});

  factory ApiError.fromJson(Map<String, Object?> json) =>
      _$ApiErrorFromJson(json);

  final String code;
  final String message;

  Map<String, Object?> toJson() => _$ApiErrorToJson(this);
}

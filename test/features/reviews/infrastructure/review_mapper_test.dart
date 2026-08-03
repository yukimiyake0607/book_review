import 'dart:convert';

import 'package:book_review/src/core/error/app_exception.dart';
import 'package:book_review/src/features/reviews/domain/rating.dart';
import 'package:book_review/src/features/reviews/domain/review.dart';
import 'package:book_review/src/features/reviews/infrastructure/dto/review_dto.dart';
import 'package:book_review/src/features/reviews/infrastructure/review_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

/// レビューは shared_preferences が SoT（ADR-0003）なので、
/// domain ⇄ DTO ⇄ JSON の往復で情報が落ちると、そのまま保存データの欠損になる。
void main() {
  Review buildReview({
    String? bookThumbnailUrl = 'https://example.com/cover.jpg',
    String? comment = '読み返したい',
    DateTime? finishedOn,
  }) {
    return Review(
      id: 'local-1',
      bookId: 'book-1',
      bookTitle: 'リーダブルコード',
      rating: Rating(4),
      createdAt: DateTime(2026, 7, 30, 10, 15, 30),
      updatedAt: DateTime(2026, 8, 1, 9),
      bookThumbnailUrl: bookThumbnailUrl,
      comment: comment,
      finishedOn: finishedOn ?? DateTime(2026, 7, 28),
    );
  }

  test('Review → DTO → Review で全フィールドが保たれる', () {
    final original = buildReview();

    expect(original.toDto().toDomain(), original);
  });

  test('rating は DTO では int、domain では Rating として扱う', () {
    final dto = buildReview().toDto();

    expect(dto.rating, 4);
    expect(dto.toDomain().rating, Rating(4));
  });

  test('nullable なフィールドは null のまま往復する', () {
    final original = Review(
      id: 'local-2',
      bookId: 'book-2',
      bookTitle: 'テスト駆動開発',
      rating: Rating(5),
      createdAt: DateTime(2026, 7, 30),
      updatedAt: DateTime(2026, 7, 30),
    );

    final restored = original.toDto().toDomain();

    expect(restored.bookThumbnailUrl, isNull);
    expect(restored.comment, isNull);
    expect(restored.finishedOn, isNull);
    expect(restored.hasComment, isFalse);
    expect(restored, original);
  });

  test('範囲外の rating を持つ DTO は ValidationException で弾く', () {
    // 保存データは信頼できない入力として扱う（assert では release で素通りする）。
    final dto = buildReview().toDto().copyWith(rating: 9);

    expect(dto.toDomain, throwsA(isA<ValidationException>()));
  });

  test('JSON 文字列を経由しても DateTime が保たれる', () {
    final original = buildReview();

    final encoded = jsonEncode(original.toDto().toJson());
    final restored = ReviewDto.fromJson(
      jsonDecode(encoded) as Map<String, dynamic>,
    ).toDomain();

    expect(restored.createdAt, original.createdAt);
    expect(restored.updatedAt, original.updatedAt);
    expect(restored.finishedOn, original.finishedOn);
    expect(restored, original);
  });
}

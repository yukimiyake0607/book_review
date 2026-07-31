import 'package:book_review/src/features/reviews/domain/rating.dart';
import 'package:book_review/src/features/reviews/domain/review.dart';
import 'package:book_review/src/features/reviews/infrastructure/dto/review_dto.dart';

extension ReviewDtoMapper on ReviewDto {
  Review toDomain() {
    return Review(
      id: id,
      bookId: bookId,
      bookTitle: bookTitle,
      rating: Rating(rating),
      createdAt: createdAt,
      updatedAt: updatedAt,
      bookThumbnailUrl: bookThumbnailUrl,
      comment: comment,
      finishedOn: finishedOn,
    );
  }
}

extension ReviewMapper on Review {
  ReviewDto toDto() {
    return ReviewDto(
      id: id,
      bookId: bookId,
      bookTitle: bookTitle,
      rating: rating.value,
      createdAt: createdAt,
      updatedAt: updatedAt,
      bookThumbnailUrl: bookThumbnailUrl,
      comment: comment,
      finishedOn: finishedOn,
    );
  }
}

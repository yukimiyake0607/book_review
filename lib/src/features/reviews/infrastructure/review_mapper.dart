import '../../../api/models/review.dart' as dto;
import '../../../api/models/review_input.dart' as dto;
import '../domain/rating.dart';
import '../domain/review.dart';
import '../domain/review_draft.dart';

/// API の DTO とドメインの [Review] / [ReviewDraft] を相互変換する。
extension ReviewDtoMapper on dto.Review {
  Review toDomain() => Review(
    id: id,
    bookId: bookId,
    bookTitle: bookTitle,
    bookThumbnailUrl: bookThumbnailUrl,
    // サーバ応答は信頼できる値として Rating を構築する。
    rating: Rating(rating),
    comment: comment,
    finishedOn: finishedOn,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

extension ReviewDraftMapper on ReviewDraft {
  dto.ReviewInput toInput() => dto.ReviewInput(
    bookId: bookId,
    bookTitle: bookTitle,
    bookThumbnailUrl: bookThumbnailUrl,
    rating: rating.value,
    comment: comment,
    finishedOn: finishedOn,
  );
}

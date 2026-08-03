import '../domain/rating.dart';
import '../domain/review.dart';
import 'dto/review_dto.dart';

extension ReviewDtoMapper on ReviewDto {
  /// 保存済み DTO を domain の [Review] へ変換する。
  ///
  /// 端末内の JSON は手で書き換えられるうえ、旧フォーマットが残ることもあるため
  /// **信頼できない入力**として扱い、[Rating.parse] を通す。assert しか行わない
  /// `Rating()` では release ビルドで範囲外の値がドメインへ入り込む。
  /// ここで送出される `ValidationException` は `ReviewLocalStore.read()` が受け、
  /// 「壊れた保存データは破棄する」既定の扱いに合流する。
  Review toDomain() {
    return Review(
      id: id,
      bookId: bookId,
      bookTitle: bookTitle,
      rating: Rating.parse(rating),
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

import 'package:freezed_annotation/freezed_annotation.dart';

import 'rating.dart';

part 'review_draft.freezed.dart';

/// レビューの新規作成・更新に渡す入力値（まだ id を持たない）。
///
/// 既存の [Review] と分けることで、「登録済みの事実」と「これから登録したい内容」を
/// 型で区別する。バリデーション済みの [Rating] を持つため、不正値は構築時点で弾かれる。
@freezed
class ReviewDraft with _$ReviewDraft {
  const factory ReviewDraft({
    required String bookId,
    required String bookTitle,
    required Rating rating,
    String? bookThumbnailUrl,
    String? comment,
    DateTime? finishedOn,
  }) = _ReviewDraft;
}

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/review.dart';
import '../domain/review_draft.dart';
import '../domain/review_repository.dart';
import '../infrastructure/review_repository_impl.dart';

part 'save_review_use_case.g.dart';

/// レビューの保存（新規作成 / 更新）を担うユースケース（application 層）。
///
/// 「id があれば更新、なければ作成」という分岐をここに閉じ込め、
/// presentation からは「保存する」という単一の意図として扱えるようにする。
class SaveReviewUseCase {
  const SaveReviewUseCase(this._repository);

  final ReviewRepository _repository;

  Future<Review> call({String? id, required ReviewDraft draft}) {
    return id == null
        ? _repository.create(draft)
        : _repository.update(id, draft);
  }
}

@Riverpod(keepAlive: true)
SaveReviewUseCase saveReviewUseCase(Ref ref) =>
    SaveReviewUseCase(ref.watch(reviewRepositoryProvider));

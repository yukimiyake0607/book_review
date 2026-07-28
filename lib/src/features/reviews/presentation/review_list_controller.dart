import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../application/save_review_use_case.dart';
import '../domain/review.dart';
import '../domain/review_draft.dart';
import '../domain/review_repository.dart';
import '../infrastructure/review_repository_impl.dart';

part 'review_list_controller.g.dart';

/// レビュー一覧の状態を保持する中心的なコントローラ。
///
/// 一覧が「レビューの現在状態」の単一の入れ物であり、作成/更新/削除の
/// **楽観的更新**もここで行う（UIを即時更新し、失敗したら直前状態へロールバックする）。
@Riverpod(keepAlive: true)
class ReviewListController extends _$ReviewListController {
  ReviewRepository get _repository => ref.read(reviewRepositoryProvider);

  @override
  Future<List<Review>> build() async {
    try {
      return await _repository.fetchAll();
    } on Object {
      // オフライン等でサーバ取得に失敗しても、キャッシュがあればそれを見せる（ADR-0003）。
      final cached = _repository.cachedReviews();
      if (cached.isNotEmpty) {
        return cached;
      }
      rethrow;
    }
  }

  /// プルリフレッシュ等での再取得。
  ///
  /// Riverpod 3 では loading 遷移時に直前値の保持がフレームワーク側で扱われ、
  /// `copyWithPrevious` は内部APIになった。UIのスピナーは `RefreshIndicator` が担うため、
  /// ここでは `guard` で結果（data/error）のみを反映する。
  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => _repository.fetchAll(forceRefresh: true),
    );
  }

  /// レビューを新規作成する（楽観的更新）。
  ///
  /// 仮の [Review] を先頭に差し込んで即座にUIへ反映し、サーバ採番の結果で置き換える。
  /// 失敗時は差し込みを取り消して例外を再送出する（呼び出し側で通知）。
  Future<void> add(ReviewDraft draft) async {
    final current = state.value ?? const [];
    final now = DateTime.now();
    final optimistic = Review(
      id: 'temp-${now.microsecondsSinceEpoch}',
      bookId: draft.bookId,
      bookTitle: draft.bookTitle,
      bookThumbnailUrl: draft.bookThumbnailUrl,
      rating: draft.rating,
      comment: draft.comment,
      finishedOn: draft.finishedOn,
      createdAt: now,
      updatedAt: now,
    );
    state = AsyncData([optimistic, ...current]);
    try {
      final saved = await ref.read(saveReviewUseCaseProvider)(draft: draft);
      state = AsyncData(_sorted([saved, ...current]));
    } on Object {
      state = AsyncData(current); // ロールバック
      rethrow;
    }
  }

  /// 既存レビューを更新する（楽観的更新）。
  Future<void> edit(String id, ReviewDraft draft) async {
    final current = state.value ?? const [];
    final index = current.indexWhere((r) => r.id == id);
    if (index < 0) {
      await ref.read(saveReviewUseCaseProvider)(id: id, draft: draft);
      return;
    }
    final optimistic = current[index].copyWith(
      bookTitle: draft.bookTitle,
      bookThumbnailUrl: draft.bookThumbnailUrl,
      rating: draft.rating,
      comment: draft.comment,
      finishedOn: draft.finishedOn,
      updatedAt: DateTime.now(),
    );
    state = AsyncData([...current]..[index] = optimistic);
    try {
      final saved = await ref.read(saveReviewUseCaseProvider)(
        id: id,
        draft: draft,
      );
      state = AsyncData([...current]..[index] = saved);
    } on Object {
      state = AsyncData(current); // ロールバック
      rethrow;
    }
  }

  /// レビューを削除する（楽観的更新）。
  Future<void> remove(String id) async {
    final current = state.value ?? const [];
    state = AsyncData(current.where((r) => r.id != id).toList());
    try {
      await _repository.delete(id);
    } on Object {
      state = AsyncData(current); // ロールバック
      rethrow;
    }
  }

  List<Review> _sorted(List<Review> reviews) {
    return [...reviews]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}

/// 一覧から id で1件を引く。一覧に無ければサーバから取得する（詳細画面用）。
@riverpod
Future<Review> reviewById(Ref ref, String id) async {
  final list = ref.watch(reviewListControllerProvider).value;
  final found = list?.where((r) => r.id == id).firstOrNull;
  if (found != null) {
    return found;
  }
  return ref.watch(reviewRepositoryProvider).fetchById(id);
}

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../application/save_review_use_case.dart';
import '../domain/review.dart';
import '../domain/review_draft.dart';
import '../domain/review_repository.dart';
import '../infrastructure/review_repository_impl.dart';

part 'review_list_controller.g.dart';

/// レビュー一覧の状態を保持するコントローラ（presentation 層）。
///
/// 一覧はホーム画面だけでなく詳細画面（[reviewByIdProvider]）からも参照され、
/// アプリ起動中は同じ内容を見せ続けたい状態のため `keepAlive` で保持する
/// （破棄と再読込みを繰り返しても、ローカルから同じ結果を読み直すだけになる）。
@Riverpod(keepAlive: true)
class ReviewListController extends _$ReviewListController {
  ReviewRepository get _repository => ref.read(reviewRepositoryProvider);

  @override
  Future<List<Review>> build() => _repository.fetchAll();

  /// プルリフレッシュ等での再取得で使用。
  Future<void> refresh() async {
    state = await AsyncValue.guard(_repository.fetchAll);
  }

  /// レビューを新規作成する。
  ///
  /// 保存完了後に一覧へ反映する。失敗時は一覧を変えず例外を再送出する。
  Future<void> add(ReviewDraft draft) async {
    final saved = await ref.read(saveReviewUseCaseProvider)(draft: draft);
    final current = state.value ?? const [];
    state = AsyncData(_sorted([saved, ...current]));
  }

  /// 既存レビューを更新する。
  Future<void> edit(String id, ReviewDraft draft) async {
    final saved = await ref.read(saveReviewUseCaseProvider)(
      id: id,
      draft: draft,
    );
    final current = state.value ?? const [];
    final index = current.indexWhere((r) => r.id == id);

    if (index < 0) {
      state = AsyncData(_sorted([saved, ...current]));
      return;
    }

    state = AsyncData([...current]..[index] = saved);
  }

  /// レビューを削除する。
  Future<void> remove(String id) async {
    await _repository.delete(id);
    final current = state.value ?? const [];
    state = AsyncData(current.where((r) => r.id != id).toList());
  }

  List<Review> _sorted(List<Review> reviews) {
    return [...reviews]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}

/// 一覧から id で1件を引く。一覧に無ければリポジトリから取得する（詳細画面用）。
@riverpod
Future<Review> reviewById(Ref ref, String id) async {
  final list = ref.watch(reviewListControllerProvider).value;
  final found = list?.where((r) => r.id == id).firstOrNull;
  if (found != null) {
    return found;
  }
  return ref.watch(reviewRepositoryProvider).fetchById(id);
}

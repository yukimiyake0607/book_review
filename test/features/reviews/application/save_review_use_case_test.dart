import 'package:book_review/src/features/reviews/application/save_review_use_case.dart';
import 'package:book_review/src/features/reviews/domain/rating.dart';
import 'package:book_review/src/features/reviews/domain/review.dart';
import 'package:book_review/src/features/reviews/domain/review_draft.dart';
import 'package:book_review/src/features/reviews/domain/review_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockReviewRepository extends Mock implements ReviewRepository {}

ReviewDraft _draft() =>
    ReviewDraft(bookId: 'b1', bookTitle: 'T', rating: Rating(3));

Review _review(String id) => Review(
  id: id,
  bookId: 'b1',
  bookTitle: 'T',
  rating: Rating(3),
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  setUpAll(() => registerFallbackValue(_draft()));

  late MockReviewRepository repository;
  late SaveReviewUseCase useCase;

  setUp(() {
    repository = MockReviewRepository();
    useCase = SaveReviewUseCase(repository);
  });

  test('id が無ければ create を呼ぶ', () async {
    when(() => repository.create(any())).thenAnswer((_) async => _review('c1'));

    final result = await useCase(draft: _draft());

    expect(result.id, 'c1');
    verify(() => repository.create(any())).called(1);
    verifyNever(() => repository.update(any(), any()));
  });

  test('id があれば update を呼ぶ', () async {
    when(
      () => repository.update(any(), any()),
    ).thenAnswer((_) async => _review('u1'));

    final result = await useCase(id: 'u1', draft: _draft());

    expect(result.id, 'u1');
    verify(() => repository.update('u1', any())).called(1);
    verifyNever(() => repository.create(any()));
  });
}

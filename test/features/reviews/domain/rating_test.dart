import 'package:book_review/src/core/error/app_exception.dart';
import 'package:book_review/src/features/reviews/domain/rating.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Rating', () {
    test('境界値(1と5)を含む有効な値を受け付ける', () {
      expect(Rating.parse(1).value, 1);
      expect(Rating.parse(5).value, 5);
      expect(Rating.parse(3).value, 3);
    });

    test('範囲外(0や6)は ValidationException を送出する', () {
      expect(() => Rating.parse(0), throwsA(isA<ValidationException>()));
      expect(() => Rating.parse(6), throwsA(isA<ValidationException>()));
    });

    test('同じ値の Rating は等価である', () {
      expect(Rating(4), Rating(4));
    });
  });
}

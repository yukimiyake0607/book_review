// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/review.dart';
import '../models/review_input.dart';

part 'reviews_api.g.dart';

@RestApi()
abstract class ReviewsApi {
  factory ReviewsApi(Dio dio, {String? baseUrl}) = _ReviewsApi;

  /// レビュー一覧を取得する（新着順）
  @GET('/reviews')
  Future<List<Review>> listReviews();

  /// レビューを新規作成する
  @POST('/reviews')
  Future<Review> createReview({@Body() required ReviewInput body});

  /// レビュー詳細を取得する
  @GET('/reviews/{id}')
  Future<Review> getReview({@Path('id') required String id});

  /// レビューを更新する
  @PUT('/reviews/{id}')
  Future<Review> updateReview({
    @Path('id') required String id,
    @Body() required ReviewInput body,
  });

  /// レビューを削除する
  @DELETE('/reviews/{id}')
  Future<void> deleteReview({@Path('id') required String id});
}

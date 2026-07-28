# ADR-0007: sealed class によるエラー設計

- ステータス: Accepted
- 日付: 2026-07-28

## コンテキスト

失敗を「握りつぶさず」「網羅的に分岐でき」「UIまで型で運べる」形にしたい。
非同期処理が中心のため、状態（loading/error/data）と失敗の型付けを両立させる必要がある。

## 決定

**失敗を sealed クラス [`AppException`](../../lib/src/core/error/app_exception.dart) の階層で表現する。**

```
sealed AppException
├── NetworkException     接続失敗・タイムアウト
├── NotFoundException    404
├── ServerException      5xx
├── ValidationException  入力不正 / 400
└── UnknownException     それ以外
```

- infrastructure 層で外部由来の例外（`DioException` など）を
  [`mapDioException`](../../lib/src/core/error/error_mapper.dart) により `AppException` へ変換して送出する
  （上位層に生の `DioException` を漏らさない）
- application/presentation では `AsyncValue.guard` で捕捉し、`AsyncValue.error` に `AppException` が載る
- UI は `switch` で `AppException` を**網羅的に**分岐し、メッセージと再試行の出し分けを行う
  （sealed なので分岐漏れはコンパイル時に検出される）
- 楽観的更新（F-02）では、保存失敗時に直前状態へロールバックし、`AppException.message` を通知する

## 検討した代替案

### a. 例外を投げっぱなし / try-catch を各所に散在
どこで何が失敗し得るか型に現れず、握りつぶしを誘発。却下。

### b. Result 型（`Result<T, AppException>` の monad）を全面採用
明示的だが、非同期の loading/error/data はすでに `AsyncValue` が表現できる。
両方を導入すると二重管理になり冗長。**非同期は `AsyncValue`、失敗の種類は sealed 型**という
役割分担にとどめ、独自 Result 型は導入しない（過剰設計の回避）。
同期的なドメイン検証（[`Rating`](../../lib/src/features/reviews/domain/rating.dart)）は
`ValidationException` の送出で表現する。

### c. dartz / fpdart の Either
学習コストと本題材の規模が見合わず、標準の `AsyncValue` + sealed で十分。却下。

## 結果（トレードオフ）

- 得たもの: 型で運ばれる失敗、UI での網羅的分岐、握りつぶしの防止
- 諦めたもの: Result monad による関数型スタイルの連鎖（本規模では不要と判断）

# ADR-0007: sealed class によるエラー設計

- ステータス: Accepted
- 日付: 2026-07-28
- 更新: 2026-07-31（Issue #15 / ADR-0008 方針B に合わせてレビュー更新の記述を修正）

## コンテキスト

失敗を「握りつぶさず」「網羅的に分岐でき」「UIまで型で運べる」形にしたい。
非同期処理が中心のため、状態（loading/error/data）と失敗の型付けを両立させる必要がある。

## 決定

**失敗を sealed クラス [`AppException`](../../lib/src/core/error/app_exception.dart) の階層で表現する。**

```
sealed AppException
├── NetworkException     接続失敗・タイムアウト
├── NotFoundException    404
├── ServerException      5xx / 429 / 403 などサーバ・API側の拒否
├── ValidationException  入力不正 / 400
└── UnknownException     それ以外
```

- infrastructure 層で外部由来の例外（`DioException` など）を
  [`mapDioException`](../../lib/src/core/error/error_mapper.dart) により `AppException` へ変換して送出する
  （上位層に生の `DioException` を漏らさない）
- application/presentation では `AsyncValue.guard` で捕捉し、`AsyncValue.error` に `AppException` が載る
- UI は `switch` で `AppException` を**網羅的に**分岐し、メッセージと再試行の出し分けを行う
  （sealed なので分岐漏れはコンパイル時に検出される）

### 機能ごとの出し方（ADR-0008 方針B）

| 機能 | 失敗の見せ方 |
|---|---|
| 書籍検索（F-01） | `AsyncValue` の error を `AppErrorView` で表示（エラー設計の主役） |
| レビュー保存・削除（F-02） | 書き込み完了まで待ち、失敗時は一覧を変えず `AppException.message` を SnackBar 等で通知する。**楽観的更新・ロールバックは行わない** |

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

### d. レビューでも楽観的更新＋ロールバックを維持
サーバ往復が前提の旧構成では有効だったが、レビューをローカル永続化した後は複雑さに見合わない（ADR-0008）。却下。

## 結果（トレードオフ）

- 得たもの: 型で運ばれる失敗、UI での網羅的分岐、握りつぶしの防止。検索とレビューで失敗の見せ方を役割分担できる
- 諦めたもの: Result monad による関数型スタイルの連鎖、レビュー操作の楽観的更新による即時感

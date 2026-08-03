# ADR-0007: sealed class によるエラー設計

- ステータス: Accepted
- 日付: 2026-07-28
- 更新: 2026-07-31（Issue #15 / ADR-0008 方針B に合わせてレビュー更新の記述を修正）
- 更新: 2026-07-31（Issue #9 / Riverpod 3 の自動リトライを無効化する決定を追記）
- 更新: 2026-08-03（catch を `on Exception` に統一し、`Error` はグローバルハンドラへ伝播させる決定を追記）

## コンテキスト

失敗を「握りつぶさず」「網羅的に分岐でき」「UIまで型で運べる」形にしたい。
非同期処理が中心のため、状態（loading/error/data）と失敗の型付けを両立させる必要がある。

同時に、**失敗には性質の違う2種類がある**。通信断や不正な入力のように「起こりうるので
UI で見せるべきもの（`Exception`）」と、null 参照や型の取り違えのように「起きた時点で
コードが間違っているもの（`Error`）」で、後者をユーザー向けメッセージに変換してしまうと
バグが「予期しないエラー」の陰に隠れる。Effective Dart も on 句のない catch を避けるよう
求めており、`Error` は捕まえて回復する対象ではない。

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
- application/presentation では `AsyncValue.guard`（`onlyAppException` 付き）で捕捉し、
  `AsyncValue.error` に `AppException` が載る
- UI は `switch` で `AppException` を**網羅的に**分岐し、メッセージと再試行の出し分けを行う
  （sealed なので分岐漏れはコンパイル時に検出される）

### 機能ごとの出し方（ADR-0008 方針B）

| 機能 | 失敗の見せ方 |
|---|---|
| 書籍検索（F-01） | `AsyncValue` の error を `AppErrorView` で表示（エラー設計の主役） |
| レビュー保存・削除（F-02） | 書き込み完了まで待ち、失敗時は一覧を変えず `AppException.message` を SnackBar 等で通知する。**楽観的更新・ロールバックは行わない** |

### catch は `on Exception` で受け、`Error` は伝播させる

**catch の既定は `on Exception`。`Error` は捕まえず、グローバルハンドラまで伝播させる。**

| 失敗の性質 | 型 | 扱い |
|---|---|---|
| 起こりうる失敗（通信断・不正な入力・破損した保存データ） | `Exception` | infrastructure の境界で `AppException` に型付けし、UI で見せる |
| コードのバグ（型の取り違え・null 参照・同梱漏れ） | `Error` | 捕まえない。[グローバルハンドラ](../../lib/src/core/error/global_error_handler.dart)まで運び、修正対象として残す |

これを成り立たせるには「`Error` が飛ぶのはバグのときだけ」という状態が必要になる。素の
`as` キャストは外部データの型不一致を `TypeError`（`Error` 系）にしてしまい、API の
レスポンスや端末の保存値が想定と違うだけでバグと区別できなくなるため、次の2つで
**外部入力起因の失敗を `Exception` 側へ寄せる**。

- DTO は json_serializable の `checked: true`（[build.yaml](../../build.yaml)）で生成し、
  `fromJson` の失敗を `CheckedFromJsonException`（`Exception` 系）にする
- 手書きのキャストは書かず、`jsonDecode` の結果や `SharedPreferences` の値は型を確かめて
  `FormatException` を送出する（[`ReviewLocalStore.read()`](../../lib/src/features/reviews/infrastructure/review_local_store.dart)）

`AsyncValue.guard` は既定で `Object` を捕まえるため、そのままでは `Error` も
`AsyncValue.error` に載ってしまう。[`onlyAppException`](../../lib/src/core/error/guard_policy.dart)
を `test` に渡し、`AppException` 以外は rethrow させる。

### 捕捉されなかった失敗をどこに集めるか（Crashlytics は未実装）

伝播した `Error` の受け口を [`installGlobalErrorHandlers()`](../../lib/src/core/error/global_error_handler.dart)
に集約し、[`bootstrap()`](../../lib/bootstrap.dart) で `runApp` より前に配線する。

- `FlutterError.onError`: build / layout などフレームワークが捕捉した失敗
- `PlatformDispatcher.instance.onError`: root isolate の未処理の非同期エラー
  （`AsyncValue.guard` が rethrow した `Error` はここへ来る）
- `ProviderObserver.providerDidFail`: Riverpod は Provider の `build` 失敗を
  フレームワーク側で `AsyncError` に変えて伝播を止めるため、この経路だけは
  [`UncaughtProviderErrorObserver`](../../lib/src/core/error/global_error_handler.dart)
  で `Exception` でない失敗を拾い、同じ出口へ合流させる

**本来はこの出口から Firebase Crashlytics へ送るが、本 Repo では実装しない。** Firebase の
プロジェクト作成・iOS/Android 双方の設定ファイル・dSYM アップロードまで実装範囲が広がり、
このリポジトリで示したい「設計上の判断」から焦点がぶれるためである。代わりに
**送信の1行を足す場所を1箇所に限定する**ところまでを設計として示し、未導入であることを
README（監視・クラッシュ収集）にも明記する。

### Riverpod 3 の自動リトライを無効化する（Issue #9）

Riverpod 3 は Provider の `build`（初期化）中に例外が投げられると、指数バックオフ
（200ms → 最大6.4s、最大10回）で**自動リトライ**する（Riverpod 2 には無かった挙動）。
この既定は、失敗を型で運び `AppErrorView`（`onRetry` 付き）で**決定論的に**見せる本アプリの
設計（本 ADR / ADR-0008）と干渉する。

**決定: [`ProviderScope`](../../lib/bootstrap.dart) に
[`noRetry`](../../lib/src/core/riverpod/retry_policy.dart) を渡し、全 Provider の自動リトライを無効化する。**

- `build` で throw するのは [`reviewById`](../../lib/src/features/reviews/presentation/review_list_controller.dart)
  のローカル `NotFoundException` のみで、変化しないローカルの保存データへのリトライは無意味
  （ユーザーには待たされた末に同じエラーが出るだけ）。
- 書籍検索は `search()` メソッド内の `AsyncValue.guard` で失敗を捕捉するため、そもそも
  `build` 失敗ではなくリトライ対象外。レビュー一覧はローカル読みのみで throw しない。
- よって現状、自動リトライで恩恵を受ける Provider は無く、無効化により失敗が即座に
  `AsyncValue.error` へ載り、`AppErrorView` の手動再試行に一本化できる。

将来 `build` で実ネットワークを叩く Provider を追加し、そこだけ自動リトライさせたい場合は、
個別 Provider の `@Riverpod(retry: ...)` で上書きする。

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

### e. すべての失敗を `on Object` で受けて `AppException` に型付けする（旧方針）
「生の例外を上位に漏らさない」ことは徹底できるが、`on Object` は実質 on 句なしの catch で、
バグ（`Error`）まで `UnknownException`＝「予期しないエラーが発生しました。」に化ける。
ユーザーは復旧できず、開発者にも痕跡が残らない（最も直したい失敗が最も見えなくなる）。
外部入力の型不一致を `Exception` 側へ寄せれば「漏らさない」は `on Exception` でも保てるため却下。

### f. Crashlytics を導入して送信まで実装する
本来あるべき姿だが、Firebase プロジェクトと各プラットフォームの設定が必要で、
題材（アーキテクチャと状態設計）に対して周辺作業の比重が大きくなる。
**出口を1箇所に集約するところまで**を範囲とし、送信は未実装のままにする。

## 結果（トレードオフ）

- 得たもの: 型で運ばれる失敗、UI での網羅的分岐、握りつぶしの防止。検索とレビューで失敗の見せ方を役割分担できる
- 得たもの: `Exception`（見せる失敗）と `Error`（直す失敗）の分離。バグがユーザー向けメッセージに埋もれず、収集の差し込み位置も1箇所に定まる
- 諦めたもの: Result monad による関数型スタイルの連鎖、レビュー操作の楽観的更新による即時感
- 諦めたもの: `Error` が起きた画面の後始末。検索中なら `AsyncLoading` のまま（スピナー継続）、
  レビューフォームなら保存中フラグが戻らない。**バグを UI で取り繕わない**代わりに、
  そのままでは操作できない状態が残る（収集を入れるまでは検知が開発者の手元に限られる）
- 諦めたもの: デモモードの同梱アセット欠落時のメッセージ表示。`FlutterError`（`Error` 系）は
  捕まえないため、ビルドの不備は起動時に落として気づかせる側に倒した

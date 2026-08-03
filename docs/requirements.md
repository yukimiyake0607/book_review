# ブックレビュー管理アプリ 要件定義書

| 項目 | 内容 |
|---|---|
| ドキュメント種別 | 要件定義書（docs/requirements.md） |
| バージョン | 1.5 |
| 作成日 | 2026-07-27 |
| 更新日 | 2026-08-03 |
| 作成者 | Yuki Miyake（[@yukimiyake0607](https://github.com/yukimiyake0607)） |
| ステータス | 実装・`.cursor/rules` と同期済み |

---

## 0. このリポジトリの位置づけ

**本リポジトリは、機能の多さやリリースを目的としたプロダクトではなく、設計判断とその根拠を提示することを目的とした技術デモである。**

読書記録という平易な題材を選んだのは、題材理解にコストをかけず、**アーキテクチャ・状態設計・エラーハンドリング・テストといった「どう作るか」に読み手の注意を集中させる**ためである。したがって機能はあえて少数に絞り、その代わり各機能をドメイン層からUI層まで一貫して作り込む。設計上の意思決定はすべて [`docs/adr/`](adr/) に記録している。

当初は OpenAPI スキーマ駆動（swagger_parser + Prism）を主眼のひとつとしていたが、公開書籍 API ＋ローカル永続化へ移行した（[ADR-0006](adr/0006-schema-driven.md) Superseded / [ADR-0008](adr/0008-book-search-api.md)）。「スキーマ合意の再現」より、**実ネットワーク・DTO/mapper・sealed エラー・ローカル SoT** の一貫した実装を見せる方針に更新している。

さらに、既定のエントリポイントを **APIキー不要のデモモード**（`Flavor.demo`）とした（[ADR-0009](adr/0009-demo-mode.md)）。設計を読んでもらうためのリポジトリで、Google Cloud でのキー発行が入口の摩擦になっていては目的と矛盾するためである。デモモードでは書籍検索のみを同梱データで動かし、**差し替えは `bookRepositoryProvider` の中だけで完結する**。application / presentation はどちらの実装が供給されるかを知らない。この構成自体が §3 の依存性逆転の実演を兼ねている。

読む順序の推奨：本書 → [`docs/adr/`](adr/) → 1つの機能フロー（書籍検索→レビュー登録）を presentation〜infrastructure まで縦に読む。

## 1. 背景・目的

読んだ本の記録・評価・振り返りを、シンプルに一元管理する。外部の書籍データベース（Google Books）から書籍を検索して登録し、自分のレビュー（評価・感想・読了日）を端末内に記録する。

題材としての狙いは §0 の通りで、以下の設計要素を自然に含むように要件を設計している。

- **外部API連携**（書籍検索）— 手書き dio クライアント、DTO↔domain mapper、失敗・ローディング・空状態の設計
- **ローカル CRUD**（レビュー）— `shared_preferences` を単一の情報源とし、書き込み完了後に一覧へ反映
- **一覧・詳細**という頻出UIパターンにおける状態管理（`AsyncValue`）

## 2. スコープ

### 2.1 Must（コア）

| ID | 機能 | 概要 |
|---|---|---|
| F-01 | 書籍検索 | キーワードで書籍を検索する。Google Books API を手書きの dio クライアントで呼び出し、結果一覧を表示。ローディング/エラー/空/成功の各状態を明示的に扱う。既定のデモモードでは同梱データを返す `DemoBookRepository` に差し替わるが、DTO / mapper / Controller / UI は実 API 経路と共通（[ADR-0009](adr/0009-demo-mode.md)） |
| F-02 | レビュー登録・編集・削除 | 検索結果から書籍を選び、評価（★1〜5）・感想・読了日を登録。`shared_preferences` へ永続化（CRUD）。書き込み完了後に一覧へ反映し、失敗時は一覧を変えずユーザーに通知する（楽観的更新は行わない） |
| F-03 | レビュー一覧・詳細 | 登録済みレビューの一覧表示（新着順）と詳細表示。プルリフレッシュで再読み込み |

### 2.2 Should（余力がある場合のみ）

| ID | 機能 | 概要 |
|---|---|---|
| F-04 | フィルタ・ソート | 評価・読了日での絞り込みと並び替え |
| F-05 | 統計 | 月別読了数、評価分布の簡易可視化 |

### 2.3 スコープ外

- ユーザー登録・認証（本デモでは単一ユーザー前提。認証を入れる場合の設計方針のみ [ADR-0010](adr/0010-auth-strategy.md) に記述する）
- 複数端末同期・サーバ上のレビュー共有
- SNS共有、他ユーザーとの交流
- 課金・広告・プッシュ通知
- タグ・シリーズ管理などの拡張メタデータ
- 検索結果のページネーション（1リクエスト20件固定。1画面分で題材として十分であり、使わない拡張ポイントをインターフェースに残さない。必要になった時点で `BookRepository` の契約を拡張する）

## 3. アーキテクチャ方針

レイヤードアーキテクチャ（＋依存性逆転）を採用し、フィーチャーファーストでフォルダを構成する。依存の向きを一方向に統一し、ドメイン層を外部技術から独立させる。

```
presentation  ── application ── domain ◄── infrastructure
   （UI/状態）      （ユースケース）  （中核）      （API/ローカル実装）
                                    ▲──────────────┘
                              依存性逆転（domainのinterfaceをinfraが実装）
```

- **presentation**：画面・Widget・Riverpodプロバイダ。UIの状態（loading/error/data）を表現する
- **application**：ユースケース。「レビューを保存する」など、分岐や意図の集約が必要な操作単位（単純な委譲は置かない）
- **domain**：エンティティ・値オブジェクト・リポジトリインターフェース。他層に依存しない
- **infrastructure**：手書き dio クライアント、DTO、mapper、SharedPreferences、リポジトリ実装

判断の根拠は [ADR-0002](adr/0002-layered-architecture.md) に記述する。過剰設計を避け、この題材の規模に見合う層構成にとどめる方針、および feature-first を選んだ理由も同ADRで明示する。

## 4. データ層方針（公開 API ＋ ローカル永続化）

| 領域 | 方針 | ADR |
|---|---|---|
| 書籍検索 | Google Books API。手書き dio + Freezed DTO + `toDomain()` | [ADR-0008](adr/0008-book-search-api.md) |
| デモモード | 既定の `lib/main.dart` は同梱データ（`assets/demo/`）を返す `DemoBookRepository` を供給する。差し替えは `bookRepositoryProvider` 内のみで行い、DTO / mapper / UI は実 API と共通 | [ADR-0009](adr/0009-demo-mode.md) |
| APIキー | 実 API 経路（`main_dev.dart` / `main_prod.dart`）でのみ使う。`dart-define-from-file` で注入し、リポジトリに直書きしない。未指定時は `key` クエリを付けずに呼ぶ（キーの有無を分岐で持たない） | [ADR-0008](adr/0008-book-search-api.md)、[ADR-0009](adr/0009-demo-mode.md) |
| レビュー | `shared_preferences` に DTO の JSON 配列として保存し、これを単一の情報源（SoT）とする。デモモードでも本物を使う（ローカル完結でキーも不要なため、偽装する理由がない）。取得口は `fetchAll()` ひとつで、強制再取得やキャッシュ用の引数・メソッドは契約に持たない（読む先が1つしかないため） | [ADR-0003](adr/0003-local-cache.md)、[ADR-0008](adr/0008-book-search-api.md) |

OpenAPI / swagger_parser / Prism は採用後に廃止した。経緯は [ADR-0006](adr/0006-schema-driven.md)（Superseded）と [ADR-0008](adr/0008-book-search-api.md) を参照。

## 5. 状態・エラーハンドリング設計

- 非同期状態は Riverpod の `AsyncValue`（loading/error/data）で統一的に表現する
- 失敗は sealed class（`AppException`）で型として扱う。例外の握りつぶしを禁止する
- **F-01（検索）**：`AsyncValue` の error を画面で表示する（エラー設計の主役）
- **F-02（レビュー保存・削除）**：永続化完了まで待ち、成功後に一覧へ反映。失敗時は一覧を変えず `AppException.message` を通知する（**楽観的更新・ロールバックは行わない**／ADR-0008 方針B）

### 「見せる失敗」と「直す失敗」を分ける

catch は `on Exception` で受け、**`Error`（コードのバグ）は捕まえずグローバルハンドラまで伝播させる**。`Error` をユーザー向けメッセージに変換すると、最も直したい失敗が「予期しないエラー」の陰に隠れるためである。これを成立させるために、外部入力（API レスポンス・端末の保存値・同梱アセット）の型不一致は素のキャスト（`TypeError`）ではなく `Exception`（`CheckedFromJsonException` / `FormatException`）として表す。伝播した `Error` の受け口は `installGlobalErrorHandlers()` に集約する。**送信先（Firebase Crashlytics）は意図的に未導入**で、差し込む位置を1箇所に定めるところまでを範囲とする。根拠は [ADR-0007](adr/0007-error-handling.md)。

### 握りつぶし禁止の唯一の例外

**破損した永続データの読み込みのみ、失敗を握りつぶして空として扱う**（`ReviewLocalStore.read()`）。保存済み JSON が壊れている状態はユーザー操作では復旧できず、エラーを出し続けてもアプリを使えなくするだけであるため、該当キーごと削除して空リストから再開する。握りつぶす範囲は **FormatException と ValidationException だけ**（DTO の CheckedFromJsonException は FormatException に揃えてから受ける）。それ以外の Exception はキーを消さず上位へ伝え、Error は伝播させる。逆に**書き込みの失敗は握りつぶさない**（`setString` が false を返したら `UnknownException` を送出する）。成功扱いにすると、再起動時に初めてレビューの消失が発覚するためである。根拠は [ADR-0003](adr/0003-local-cache.md)。

### フレームワークによる暗黙の再試行を無効化する

Riverpod 3 は Provider の build 失敗を既定で自動リトライする。本アプリはこれを `ProviderScope(retry: noRetry)` で全体無効化する（`lib/bootstrap.dart`）。失敗は `AsyncValue.error` として画面に出し、**再試行するかどうかはユーザーが `AppErrorView` の再試行ボタンで決める**設計であり、裏で暗黙に再送されると「エラー表示のまま通信が走り続ける」状態になるためである。根拠は [ADR-0007](adr/0007-error-handling.md)。

判断の根拠は [ADR-0007](adr/0007-error-handling.md) / [ADR-0008](adr/0008-book-search-api.md) に記述する。

## 6. データモデル（概要）

```text
Book        … id, title, authors, thumbnailUrl
              （検索結果。外部API由来。domain では DTO と分離）
Review      … id, bookId, bookTitle, rating(1-5), comment?,
              finishedOn?, bookThumbnailUrl?, createdAt, updatedAt
              （一覧表示用に書籍名・書影を非正規化して保持）
ReviewDraft … 新規・更新入力（id を持たない）
```

不変モデルとして freezed で定義する。ドメインの Review / Book と、API・ローカル保存用の DTO は分離し、infrastructure 境界でマッピングする。

## 7. 非機能要件

| 分類 | 要件 |
|---|---|
| 対応OS | iOS 13.0以上（Flutter 既定の deployment target を据え置き。iOS 16 以降でしか使えない API に依存しておらず、対象端末を狭める技術的理由がないため）。Android はビルド可能な状態を CI（debug APK）で維持 |
| パフォーマンス | 一覧は `ListView.separated` の遅延生成に載せ、行は `const` とプライベート `StatelessWidget` へ抽出して不要な rebuild を避ける（`_buildXxx` のようなビルダー関数にしない）。詳細画面は一覧全体ではなく `reviewById(id)` を購読する。端末内のレビュー件数に収まる小規模前提のため、`select` による購読の細分化までは行わない |
| テスト容易性 | ドメイン層をインターフェース越しに差し替え可能にし、ユースケースを外部依存なしでテストできること |
| 品質ゲート | CI ジョブ `analyze / format / test / build` を main の**必須ステータスチェック**に指定し、通過しないコードはmainにマージできない状態を設定側でも担保する。生成物（`*.g.dart` / `*.freezed.dart`）は git 管理外のため、CI は毎回 `build_runner` で再生成してから検査する（＝「再生成できること」自体を品質ゲートに含める） |
| 可読性 | `analysis_options.yaml` の厳格ルールと `riverpod_lint`（トップレベル `plugins` で登録し `flutter analyze` から実行）で規約を機械的に強制する。`strict-casts` / `strict-inference` / `strict-raw-types` を有効化する |
| セットアップ | clone 後 `flutter run` のみで全画面を確認できる（既定はデモモード。APIキーもネットワークも不要）。実 API を叩く場合のみ Google Books API キーをローカル配置する（キーは git 管理外）。手順は README に記載 |

## 8. 技術選定（サマリ）

各項目の選定理由・代替案・トレードオフは対応するADRに記述する。

| 領域 | 採用技術 | ADR |
|---|---|---|
| フレームワーク | Flutter / Dart（`mise` でバージョン固定） | [ADR-0001](adr/0001-state-management.md) |
| 状態管理 | Riverpod（`@riverpod` コード生成、AsyncValue中心） | [ADR-0001](adr/0001-state-management.md) |
| Widget ローカル状態 | flutter_hooks（`hooks_riverpod`）。画面内で完結する入力状態のみ担当し、共有・永続化される状態は Riverpod に置く | [ADR-0001](adr/0001-state-management.md) |
| アーキテクチャ | レイヤード＋依存性逆転（feature-first） | [ADR-0002](adr/0002-layered-architecture.md) |
| レビュー永続化 | shared_preferences（SoT） | [ADR-0003](adr/0003-local-cache.md) |
| ルーティング | go_router | [ADR-0004](adr/0004-routing.md) |
| モデル | freezed / json_serializable（DTO） | — |
| ネットワーク | dio（手書きクライアント）+ Google Books API | [ADR-0008](adr/0008-book-search-api.md) |
| デモモード | `Flavor.demo` + `DemoBookRepository`（同梱 JSON アセット） | [ADR-0009](adr/0009-demo-mode.md) |
| エラー設計 | sealed class（`AppException`） | [ADR-0007](adr/0007-error-handling.md) |
| CI | GitHub Actions（build_runner → analyze → format → test → build）を main の必須ステータスチェックに指定 | [ADR-0005](adr/0005-ci.md) |
| （未導入）認証 | スコープ外。導入する場合の置き場所（secure storage / `redirect` / dio Interceptor）のみ確定させてある | [ADR-0010](adr/0010-auth-strategy.md) Proposed |
| （廃止）APIスキーマ駆動 | OpenAPI + swagger_parser + Prism | [ADR-0006](adr/0006-schema-driven.md) Superseded |

## 9. テスト方針

「壊れると困る箇所」を狙って書く。カバレッジの数値ではなくテスト対象の選定意図を重視する。

| 種別 | 対象 |
|---|---|
| unit | ユースケース（保存の create/update 分岐）、ドメインロジック（`Rating`）、DTO⇄ドメインのマッピング、エラー分岐、レビュー CRUD のローカル永続化 |
| widget | 検索画面（loading / error / empty / success）、レビュー登録フォームのバリデーション、URL から直接開いたときの遷移（ディープリンク・未定義パス） |
| integration | 「検索 → レビュー登録 → 一覧反映」のコアフロー1本 |

外部 API はフェイクリポジトリに差し替え、ネットワークに依存せずテストする。レビューの Controller は「書き込み成功後に一覧反映／失敗時は一覧不変」を検証する（楽観的更新は対象外）。

## 10. 開発プロセス

- **PR駆動**：機能単位でブランチを切り、セルフレビューを経てマージする。PRテンプレートに「変更概要／設計上の判断／テスト観点」を含める
- **ADR**：技術的な意思決定は都度ADRとして記録する（状態管理・アーキテクチャ・永続化・ルーティング・CI・エラー設計・データ層移行など）
- **AI駆動開発**：AIコーディング支援を活用する。AIに委ねる範囲と人間が判断・検証する範囲をREADMEに明記し、レビューで採否を判断した痕跡をPRに残す

## 11. マイルストーン（実績メモ）

| 時期 | 内容 |
|---|---|
| 初期 | リポジトリ基盤：CI・flavor・アーキテクチャ骨格・analysis_options、ADR-0001/0002/0005 |
| 中盤 | OpenAPI + モックでの F-01/F-02 骨格（後に #12 で撤去） |
| #12 | OpenAPI / 生成クライアント撤去、スタブ化（地ならし） |
| #15 | Google Books 実装、レビューのローカル永続化、方針B（楽観的更新廃止）、ADR-0007/0008 更新 |
| #18 | Riverpod 3 の自動リトライを `noRetry` で全体無効化（ADR-0007 更新） |
| #19 | APIキー不要のデモモード（`Flavor.demo` / `DemoBookRepository`）、ADR-0009 |
| #20 | README のスクリーンショット・操作デモ整備 |
| 本書 v1.3 | 実装との乖離を解消（デモモード反映、対応OS・CI 記述の実態合わせ、認証方針を ADR-0010 化、未使用 `page` 引数の削除、mapper / CRUD / loading テストの追加） |
| 本書 v1.4 | `.cursor/rules` と実装の乖離を解消（レビュー契約の遺物 `forceRefresh` / `cachedReviews` と到達しないフォールバックの削除、infrastructure 境界での例外変換の徹底、永続データの `Rating.parse` 化、lib 内 import の相対統一、Provider 宣言位置を ADR-0002 に明文化） |
| 本書 v1.5 | ルート契約の是正（`extra` の生キャスト排除、編集画面を URL の `id` から復元、`errorBuilder` 追加、フォームの必須入力を `assert` から型へ、ADR-0004 に `extra` の使いどころを追記） |

> Should（F-04/F-05）は余力に応じて実施する。本書 v1.4 時点では未実装。

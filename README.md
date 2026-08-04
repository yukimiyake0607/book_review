# 読書レビュー管理アプリ（book_review）

![CI](https://github.com/yukimiyake0607/book_review/actions/workflows/ci.yml/badge.svg)
![Flutter](https://img.shields.io/badge/Flutter-stable-blue)

## アプリ概要

読んだ本を検索して登録し、評価・感想を記録する Flutter（iOS）アプリです。
要件定義はこちら：[docs/requirements.md](docs/requirements.md)

clone して `flutter run` するだけで全画面を触れます（書籍検索は同梱データで動くデモモードのため、APIキーは不要です）。詳しくは[セットアップ](#セットアップ)を参照してください。


### 機能

- **書籍検索** — [Google Books API](https://developers.google.com/books) を手書きの `dio` クライアントで呼び出し、キーワード検索
- **レビュー管理** — 評価（★）・感想・読了日を登録・編集・削除（端末内に永続化）
- **一覧 / 詳細** — 登録したレビューを一覧・詳細で表示（プルリフレッシュ対応）

### スクリーンショット

| マイレビュー | レビュー登録 |
| --- | --- |
| <img src="docs/screenshots/review_list.png" width="300" alt="マイレビュー画面"> | <img src="docs/screenshots/review_create.png" width="300" alt="レビュー登録画面"> |


| 初期 | 結果あり | 結果なし |
| --- | --- | --- |
| <img src="docs/screenshots/book_search_empty.png" width="270" alt="書籍検索画面（初期）"> | <img src="docs/screenshots/book_search_results.png" width="270" alt="書籍検索画面（結果あり）"> | <img src="docs/screenshots/book_search_no_results.png" width="270" alt="書籍検索画面（結果なし）"> |

#### 操作デモ（書籍検索〜レビュー登録）

<img src="docs/screenshots/search_to_review.gif" width="300" alt="書籍を検索してレビューを登録するまでの操作デモ">

## 設計方針

機能はシンプルですが、**規模拡大や複数人開発を見据えた構成・状態管理・エラー設計**に重点を置いています。
設計判断は [docs/adr/](docs/adr/) で管理しています。

### アーキテクチャ：レイヤード（依存性逆転）＋フィーチャーファースト

依存の向きを一方向に統一し、ドメイン層を外部技術から独立させています。機能単位でフォルダを切り、その中に4層（presentation / application / domain / infrastructure）を配置します。

```text
presentation ── application ── domain ◄── infrastructure
   UI/状態         ユースケース      中核         API/ローカル実装
                                  ▲──────────────┘
                            domain の interface を infra が実装
```

### データ層（外部API ＋ ローカル）


| 領域     | 方針                                                                         |
| ------ | -------------------------------------------------------------------------- |
| 書籍検索   | Google Books。Freezed DTO → `toDomain()` → domain の `Book`                   |
| レビュー   | `shared_preferences` を単一の情報源（SoT）。再起動後も残る                                  |
| APIキー  | リポジトリに含めない。`dart_defines.json`（gitignore）または `--dart-define-from-file` で注入 |
| デモモード  | キー未所持でも触れるよう、同梱データを返す実装に差し替える（DTO / mapper / UI は実 API と共通）                |

選定理由・代替案は [ADR-0008](docs/adr/0008-book-search-api.md) / [ADR-0009](docs/adr/0009-demo-mode.md) に記載。

### 状態・エラー設計


| 領域        | 方針                                                                   |
| --------- | -------------------------------------------------------------------- |
| 書籍検索      | `AsyncValue` で loading / error / data を扱い、`data` 内の空リストを空結果として表示する   |
| レビュー保存・削除 | 書き込み完了後に一覧へ反映。楽観的更新・ロールバックは行わない                                      |
| 失敗の型      | sealed class の `AppException`（網羅分岐）                                  |
| catch の範囲  | `on Exception` のみ。`Error`（コードのバグ）は捕まえずグローバルハンドラへ伝播させる（[ADR-0007](docs/adr/0007-error-handling.md)） |

## 技術スタック


| 領域      | 技術                                              |
| ------- | ----------------------------------------------- |
| フレームワーク | Flutter / Dart（`mise` でバージョン固定）                 |
| 状態管理    | Riverpod（`@riverpod` コード生成 / AsyncValue 中心）     |
| Widget ローカル状態 | flutter_hooks（画面内で完結する入力状態のみ。共有・永続化される状態は Riverpod） |
| ルーティング  | go_router                                       |
| モデル     | freezed / json_serializable（DTO）                |
| ネットワーク  | dio（手書き）+ Google Books API                      |
| ローカル保存  | shared_preferences                              |
| CI      | GitHub Actions（build_runner → analyze → format → test → build）。main の必須ステータスチェック |

## AI 活用の範囲

このリポジトリは AI コーディング支援を使って開発しています。何を AI に任せ、何を自分で判断・検証したかを明示します。

| 区分 | 内容 |
| --- | --- |
| AI に任せた | Widget のボイラープレート、DTO / mapper の定型実装、テストケースの洗い出し、命名や文章の推敲、機械的なリファクタの適用 |
| 自分で判断した | 層の切り方と依存の向き、パッケージ選定、`AppException` の型設計、SoT をどこに置くか、スコープに入れない機能の線引き |
| 自分で検証した | 生成されたコードをレビューして採否を決め、CI（analyze / format / test / build）と手動の動作確認を通す |

**AI の提案や自分の初期実装を撤回した判断**を、代替案・却下理由つきで [docs/adr/](docs/adr/) に残しています。設計判断が残っているかどうかが、このリポジトリで一番見てほしい部分です。

- **全操作に UseCase を置く構成をやめた** — 単純委譲の UseCase は層を1枚増やすだけだったため、意図の集約が必要な操作（保存の create / update 分岐）だけに限定した（[ADR-0002](docs/adr/0002-layered-architecture.md)）
- **楽観的更新を実装後に撤回した** — ロールバックの複雑さが、ローカル保存の速度で得られる体感差に見合わなかった（[ADR-0008](docs/adr/0008-book-search-api.md) 方針B）
- **OpenAPI スキーマ駆動を撤回した** — モックサーバ前提だと clone しても動かせず、デモとしての目的と衝突した（[ADR-0006](docs/adr/0006-schema-driven.md) Superseded → [ADR-0008](docs/adr/0008-book-search-api.md)）
- **Riverpod 3 の既定挙動を無効化した** — Provider の自動リトライが「ユーザーが再試行を決める」エラー設計と衝突するため、`ProviderScope(retry: noRetry)` で切った（[ADR-0007](docs/adr/0007-error-handling.md)）
- **`on Object` で全部の失敗を型付けする実装を撤回した** — 「生の例外を漏らさない」ためにバグ（`Error`）まで `UnknownException` に変換していたが、それはユーザーが復旧できない失敗を「予期しないエラー」に化かして痕跡を消す実装だった。外部入力の型不一致を `Exception` 側（`checked: true` / `FormatException`）へ寄せることで、`on Exception` でも漏れを防げると判断して切り替えた（[ADR-0007](docs/adr/0007-error-handling.md)）
- **CI の `custom_lint` ステップを廃止した** — `riverpod_lint` 3.1.0 が `analysis_server_plugin` へ移行しており、`custom_lint` 経由ではルールが 0 個しか登録されず「常に成功する空振りのステップ」になっていた。意図的な違反コードで検出されないことを確認したうえで、`analysis_options.yaml` の `plugins` 登録 + `flutter analyze` に一本化した（[ADR-0005](docs/adr/0005-ci.md)）

AI に一貫した実装をさせるため、アーキテクチャと層ごとの規約は [.cursor/rules/](.cursor/rules/) に明文化しています。PR には [テンプレート](.github/pull_request_template.md)の「AI活用メモ」欄で、提案の採否を都度残しています。

## テスト

ユースケース・値オブジェクトの境界値・エラー分岐・ローカル永続化など「壊れると困る箇所」を中心に、unit / widget / integration を用意しています。外部 API はフェイクリポジトリに差し替え、ネットワーク非依存で実行します。

```bash
flutter test
```

## スコープと非機能要件

デモとしての範囲を明確にするため、**意図的にスコープ外とした項目**も記載します。


| 項目         | 現状・方針                                                  |
| ---------- | ------------------------------------------------------ |
| 認証・認可      | スコープ外。導入する場合の置き場所（`flutter_secure_storage` / go_router の `redirect` / dio の Interceptor）は [ADR-0010](docs/adr/0010-auth-strategy.md) に記載 |
| 複数端末同期     | スコープ外。レビューは端末ローカルのみ                                    |
| 国際化（i18n）  | 日本語のみ。多言語化は ARB での対応を想定                                |
| アクセシビリティ   | Material 標準ウィジェットが持つセマンティクス（`Text` / `IconButton` の tooltip 等）に依存。明示的な `Semantics` の作り込みと WCAG 準拠は未対応 |
| 監視・クラッシュ収集 | 送信は未導入。`Error` を集約するグローバルハンドラ（`installGlobalErrorHandlers()`）までは配線済みで、Firebase Crashlytics へ送る1行を足す位置を1箇所に限定している（[ADR-0007](docs/adr/0007-error-handling.md)） |
| パフォーマンス    | 一覧は小規模前提。大規模化時はページング／リスト仮想化を検討                         |




## セットアップ

要件：[mise](https://mise.jdx.dev/)（`mise.toml` で Flutter / Dart を固定）/ Xcode

### 1. clone して起動する（APIキー不要）

```bash
git clone https://github.com/yukimiyake0607/book_review.git
cd book_review

# Flutter/Dart のバージョンは mise で固定
mise trust
mise install

flutter pub get
dart run build_runner build

flutter run
```

既定のエントリポイント `lib/main.dart` は**デモモード**で起動します。書籍検索は同梱データ（`assets/demo/`）を返すため、APIキーもネットワークも要りません。「flutter」「テスト」「リファクタリング」などで検索すると結果が出ます。

動作確認の目安:

1. キーワードで書籍を検索できる（ヒットしないキーワードでは空表示になる）
2. 書籍を選んでレビューを登録できる
3. 一覧に反映され、アプリ再起動後も残る

### 2. 実際の Google Books API を叩く（任意）

実ネットワークの挙動まで確認したい場合のみ、APIキーを用意します。

1. [Google Cloud Console](https://console.cloud.google.com/) でプロジェクトを作成（または既存を選択）
2. 「APIとサービス」→「ライブラリ」→ **Books API** を有効化
3. 「認証情報」→「認証情報を作成」→ **APIキー**
4. キーの用途を Books API のみに制限する

```bash
cp dart_defines.example.json dart_defines.json
# dart_defines.json を開き、GOOGLE_BOOKS_API_KEY に自分のキーを記入

flutter run -t lib/main_dev.dart --dart-define-from-file=dart_defines.json
```

Cursor / VS Code なら **dev (debug)** を選択（`launch.json` が `dart_defines.json` を読み込みます）。`dart_defines.json` は `.gitignore` 済みなので、**コミットしないでください。**

`--dart-define` で渡した値はビルド成果物に含まれます。配布用ビルドを作る場合は、ローカル開発用とは別に、Books API 専用かつ対象 iOS bundle ID に制限したキーを用意してください。

## コードの読み方

1. [docs/requirements.md](docs/requirements.md) でスコープを把握する
2. [docs/adr/](docs/adr/) で「なぜそう決めたか」を読む
3. 1本の動線を縦に読む: 検索 UI → Controller → Repository → DTO/mapper → Google Books / レビューなら SharedPreferences

## ライセンス

MIT License
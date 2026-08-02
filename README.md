# 読書レビュー管理アプリ（book_review）

![CI](https://github.com/yukimiyake0607/book_review/actions/workflows/ci.yml/badge.svg)
![Flutter](https://img.shields.io/badge/Flutter-stable-blue)

## アプリ概要

読んだ本を検索して登録し、評価・感想を記録する Flutter（iOS）アプリです。
要件定義はこちら：[docs/requirements.md](docs/requirements.md)


### 機能

- **書籍検索** — [Google Books API](https://developers.google.com/books) を手書きの `dio` クライアントで呼び出し、キーワード検索
- **レビュー管理** — 評価（★）・感想・読了日を登録・編集・削除（端末内に永続化）
- **一覧 / 詳細** — 登録したレビューを一覧・詳細で表示（プルリフレッシュ対応）

### スクリーンショット

| マイレビュー | 書籍検索（初期） | 書籍検索（結果） | レビュー登録 |
| --- | --- | --- | --- |
| <img src="docs/screenshots/review_list.png" width="300" alt="マイレビュー画面"> | <img src="docs/screenshots/book_search_empty.png" width="300" alt="書籍検索画面（初期）"> | <img src="docs/screenshots/book_search_results.png" width="300" alt="書籍検索画面（結果）"> | <img src="docs/screenshots/review_create.png" width="300" alt="レビュー登録画面"> |



## 設計方針

機能はシンプルですが、**規模拡大や複数人開発を見据えた構成・状態管理・エラー設計**に重点を置いています。
設計判断は `[docs/adr/](docs/adr/)` で管理しています。

### アーキテクチャ：レイヤード（依存性逆転）＋フィーチャーファースト

依存の向きを一方向に統一し、ドメイン層を外部技術から独立させています。機能単位でフォルダを切り、その中に4層（presentation / application / domain / infrastructure）を配置します。

```text
presentation ── application ── domain ◄── infrastructure
   UI/状態         ユースケース      中核         API/ローカル実装
                                  ▲──────────────┘
                            domain の interface を infra が実装
```

### データ層（外部API ＋ ローカル）


| 領域    | 方針                                                                         |
| ----- | -------------------------------------------------------------------------- |
| 書籍検索  | Google Books。Freezed DTO → `toDomain()` → domain の `Book`。|
| レビュー  | `shared_preferences` を単一の情報源（SoT）。再起動後も残る                                  |
| APIキー | リポジトリに含めない。`dart_defines.json`（gitignore）または `--dart-define-from-file` で注入 |


選定理由・代替案は [ADR-0008](docs/adr/0008-book-search-api.md) に記載。

### 状態・エラー設計


| 領域        | 方針                                                              |
| --------- | --------------------------------------------------------------- |
| 書籍検索      | `AsyncValue` で loading / error / empty / data をそのまま表示（エラー設計の主役） |
| レビュー保存・削除 | 書き込み完了後に一覧へ反映。楽観的更新・ロールバックは行わない                                 |
| 失敗の型      | sealed class の `AppException`（網羅分岐）                             |

## 技術スタック


| 領域      | 技術                                              |
| ------- | ----------------------------------------------- |
| フレームワーク | Flutter / Dart（`mise` でバージョン固定）                 |
| 状態管理    | Riverpod（`@riverpod` コード生成 / AsyncValue 中心）     |
| ルーティング  | go_router                                       |
| モデル     | freezed / json_serializable（DTO）                |
| ネットワーク  | dio（手書き）+ Google Books API                      |
| ローカル保存  | shared_preferences                              |
| CI      | GitHub Actions（analyze → format → test → build） |

## テスト

ユースケース・値オブジェクトの境界値・エラー分岐・ローカル永続化など「壊れると困る箇所」を中心に、unit / widget / integration を用意しています。外部 API はフェイクリポジトリに差し替え、ネットワーク非依存で実行します。

```bash
flutter test
```

## スコープと非機能要件

デモとしての範囲を明確にするため、**意図的にスコープ外とした項目**も記載します。


| 項目         | 現状・方針                                                  |
| ---------- | ------------------------------------------------------ |
| 認証・認可      | スコープ外。導入時はトークン管理＋`flutter_secure_storage` を想定し ADR 化予定 |
| 複数端末同期     | スコープ外。レビューは端末ローカルのみ                                    |
| 国際化（i18n）  | 日本語のみ。多言語化は ARB での対応を想定                                |
| アクセシビリティ   | 基本的な `Semantics` のみ。WCAG 準拠までは未対応                      |
| 監視・クラッシュ収集 | 未導入。導入時は Firebase Crashlytics を想定                      |
| パフォーマンス    | 一覧は小規模前提。大規模化時はページング／リスト仮想化を検討                         |




## セットアップ

**clone しただけでは書籍検索は動きません。** Google Books API は APIキー必須です（キー無しだと共有枠で 429 になります）。
キーはリポジトリに含めず、各自がローカルに置きます。

### 1. 依存関係

```bash
git clone https://github.com/yukimiyake0607/book_review.git
cd book_review

# Flutter/Dart のバージョンは mise で固定
mise trust
mise install

flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### 2. Google Books API キーを用意する

1. [Google Cloud Console](https://console.cloud.google.com/) でプロジェクトを作成（または既存を選択）
2. 「APIとサービス」→「ライブラリ」→ **Books API** を有効化
3. 「認証情報」→「認証情報を作成」→ **APIキー**
4. （推奨）キーを Books API のみに制限する

### 3. キーをローカルに配置する

```bash
cp dart_defines.example.json dart_defines.json
# dart_defines.json を開き、GOOGLE_BOOKS_API_KEY に自分のキーを記入
```

`dart_defines.json` は `.gitignore` 済みです。**コミットしないでください。**

### 4. 起動

Cursor / VS Code なら **dev (debug)** を選択（`launch.json` が `dart_defines.json` を読み込みます）。

ターミナルの場合:

```bash
flutter run -t lib/main_dev.dart --dart-define-from-file=dart_defines.json
```

### 5. 動作確認の目安

1. 「flutter」などで書籍を検索できる
2. 書籍を選んでレビューを登録できる
3. 一覧に反映され、アプリ再起動後も残る

要件：[mise](https://mise.jdx.dev/)（`mise.toml` で Flutter / Dart を固定）/ Xcode


1. [docs/requirements.md](docs/requirements.md) でスコープを把握する
2. [docs/adr/](docs/adr/) で「なぜそう決めたか」を読む
3. 1本の動線を縦に読む: 検索 UI → Controller → Repository → DTO/mapper → Google Books / レビューなら SharedPreferences

## ライセンス

MIT License
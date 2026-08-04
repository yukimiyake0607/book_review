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

## テスト

ユースケース・値オブジェクトの境界値・エラー分岐・ローカル永続化など「壊れると困る箇所」を中心に、unit / widget / integration を用意しています。外部 API はフェイクリポジトリに差し替え、ネットワーク非依存で実行します。

```bash
flutter test
```

## スコープと非機能要件

デモとしての範囲を明確にするため、**意図的にスコープ外とした項目**も記載します。


| 項目         | 現状・方針                                                  |
| ---------- | ------------------------------------------------------ |
| 認証・認可      | スコープ外。導入する場合の置き場所の候補は `flutter_secure_storage` / go_router の `redirect` / dio の Interceptor |
| 複数端末同期     | スコープ外。レビューは端末ローカルのみ                                    |
| 国際化（i18n）  | 日本語のみ。多言語化は ARB での対応を想定                                |
| アクセシビリティ   | Material 標準ウィジェットが持つセマンティクス（`Text` / `IconButton` の tooltip 等）に依存。明示的な `Semantics` の作り込みと WCAG 準拠は未対応 |
| 監視・クラッシュ収集 | 送信は未導入。`Error` を集約するグローバルハンドラ（`installGlobalErrorHandlers()`）までは配線済みで、Firebase Crashlytics へ送る1行を足す位置を1箇所に限定している |
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
2. 1本の動線を縦に読む: 検索 UI → Controller → Repository → DTO/mapper → Google Books / レビューなら SharedPreferences

## ライセンス

MIT License

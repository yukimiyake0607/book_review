# 📚 ブックレビュー管理アプリ

![CI](https://github.com/yukimiyake0607/book_review/actions/workflows/ci.yml/badge.svg)
![Flutter](https://img.shields.io/badge/Flutter-stable-blue)

読んだ本を検索して登録し、評価・感想を記録するiOSアプリです。

> **このリポジトリの目的**
> 機能の多さやリリースではなく、**「どのような設計をし、なぜその設計を選んだか」を示すこと**を目的にした技術デモです。題材（読書記録）はあえて平易にし、アーキテクチャ・状態設計・スキーマ駆動開発・エラーハンドリング・テストといった「どう作るか」に注目できるようにしています。
>
> **おすすめの読み方**：この README → [`docs/adr/`](docs/adr/)（設計判断の記録）→ 書籍検索〜レビュー登録の1フローを presentation〜infrastructure まで縦に読む。

<!-- スクリーンショット（任意）：検索 / 登録 / 一覧 -->

## 設計のハイライト

このリポジトリで特に見ていただきたい点です。

### 1. 判断の記録（ADR）
採用した技術と構成について、**採用理由だけでなく「検討した代替案」と「却下した理由」まで**記録しています。

- [ADR-0001 状態管理にRiverpodを採用する理由 / コード生成の可否](docs/adr/0001-state-management.md)
- [ADR-0002 レイヤードアーキテクチャとフィーチャーファースト構成](docs/adr/0002-layered-architecture.md)
- [ADR-0003 ローカルキャッシュに shared_preferences を採用する判断](docs/adr/0003-local-cache.md)
- [ADR-0004 ルーティングに go_router を採用する理由](docs/adr/0004-routing.md)
- [ADR-0005 GitHub Actions による品質ゲート](docs/adr/0005-ci.md)
- [ADR-0006 OpenAPIスキーマ駆動開発を採用する理由](docs/adr/0006-schema-driven.md)
- [ADR-0007 sealed classによるエラー設計](docs/adr/0007-error-handling.md)

### 2. レイヤードアーキテクチャ（依存性逆転）＋フィーチャーファースト
依存の向きを一方向に統一し、ドメイン層を外部技術から独立させています。機能単位でフォルダを切り、各機能の中に4層を配置することでスケーラビリティを確保しています（[ADR-0002](docs/adr/0002-layered-architecture.md)）。

```
presentation ── application ── domain ◄── infrastructure
   UI/状態         ユースケース      中核         API/DB実装
                                  ▲──────────────┘
                            domainのinterfaceをinfraが実装
```

```
lib/
└── src/
    ├── app.dart                # ProviderScope + go_router
    ├── core/                   # 全機能共通（error, network など）
    ├── routing/                # go_router 定義
    └── features/
        ├── book_search/        # F-01 書籍検索
        │   ├── presentation/   # 画面・Widget・Riverpod Notifier（@riverpod / AsyncValue）
        │   ├── application/    # ユースケース
        │   ├── domain/         # エンティティ・値オブジェクト・リポジトリIF
        │   └── infrastructure/ # 生成APIクライアント・DTO・リポジトリ実装
        └── reviews/            # F-02/F-03 レビューCRUD・一覧・詳細
            └── ...
```

### 3. OpenAPIスキーマ駆動開発
API仕様を [`api/openapi.yaml`](api/openapi.yaml) で定義し、そこから [`swagger_parser`](https://pub.dev/packages/swagger_parser) でDartクライアント（freezedモデル＋dio）を生成しています。**バックエンド本体は実装せず、モックサーバ（Prism）で開発・テストを回す構成**です。実務でバックエンドチームとOpenAPIスキーマを介して設計調整している経験を、個人リポジトリで再現しました（[ADR-0006](docs/adr/0006-schema-driven.md)）。

### 4. 状態とエラーの設計
非同期状態は `AsyncValue` で loading / error / data を統一的に扱い、失敗はドメイン層で **sealed class の型** として表現しています。レビュー保存は楽観的更新し、失敗時はロールバックします（[ADR-0007](docs/adr/0007-error-handling.md)）。

## 主な機能

- 書籍検索（外部書籍API連携）
- レビュー登録・編集・削除（サーバ同期・楽観的更新）
- レビュー一覧・詳細（プルリフレッシュ）

要件定義書：[`docs/requirements.md`](docs/requirements.md)

## 技術スタック

| 領域 | 技術 |
|---|---|
| フレームワーク | Flutter（`mise` でバージョン固定）/ Dart |
| 状態管理 | Riverpod（hooks_riverpod、AsyncValue中心）＋ `@riverpod` コード生成（riverpod_generator） |
| アーキテクチャ | レイヤード＋依存性逆転（フィーチャーファースト） |
| API定義 | OpenAPI + コード生成（swagger_parser）+ モックサーバ（Prism） |
| モデル | freezed / json_serializable（コード生成） |
| ルーティング | go_router |
| ローカルキャッシュ | shared_preferences |
| エラー設計 | sealed class による Result 表現 |
| CI | GitHub Actions（analyze → format → test → build） |
| Lint | analysis_options.yaml（型の厳格化＋可読性ルール）＋ riverpod_lint（custom_lint） |

## テスト

「壊れると困る箇所」を狙って書いています。

| 種別 | 対象 |
|---|---|
| unit | ユースケース、値オブジェクト（Rating）の境界値、エラー分岐、楽観的更新とロールバック |
| widget | 検索画面の4状態（loading/error/empty/success）、レビューフォームのバリデーション |
| integration | 検索 → レビュー登録 → 一覧反映のコアフロー1本 |

APIはインメモリのフェイクリポジトリに差し替え、ネットワークに依存せず実行します。CIでmainへのマージ条件にしています。

```bash
flutter test
```

## 開発プロセス

- **PR駆動開発** — 個人開発ですが、実務と同様に機能単位でPRを作成し、設計意図・テスト観点を記述してセルフレビューを経てマージしています → [Pull Requests](../../pulls)
- **ADRによる意思決定の記録** — 「なぜそうしたか」を将来の自分とレビュアーのために残しています

### AI活用の方針
実務同様、AIコーディング支援を活用しています。

- **AIに委ねる**：定型実装の下書き、テストの雛形、リファクタリング案の提示
- **人間（私）が担う**：要件定義、アーキテクチャ・技術選定の判断（ADRに記録）、生成コードのレビューと採否判断、テスト設計

AIの出力をそのまま採用せず、レビューして書き直した箇所はPRで確認できます。

## セットアップ

```bash
git clone https://github.com/yukimiyake0607/book_review.git
cd book_review

# Flutter/Node のバージョンは mise で固定している（fvm は不使用）
mise trust
mise install

flutter pub get
dart run build_runner build --delete-conflicting-outputs

# モックサーバ（別ターミナル）
npx @stoplight/prism-cli mock api/openapi.yaml

# 環境はエントリポイントで切り替える（dev / prod）
flutter run -t lib/main_dev.dart
```

要件：[mise](https://mise.jdx.dev/)（`mise.toml` で Flutter を固定）/ Xcode / Node.js（Prism 実行用）

> Riverpod のコード生成に必要なツールチェーン整合のため、`analyzer` 等を
> `dependency_overrides` で固定しています（理由は [ADR-0001](docs/adr/0001-state-management.md)）。

## ロードマップ

- [x] 書籍検索・レビューCRUD・一覧（コア）
- [ ] フィルタ・ソート、簡易統計
- [ ] 認証を導入する場合の設計方針をADR化
- [ ] （検討）実サーバ実装への差し替え

## ライセンス

MIT License

## 作者

Yuki Miyake — Flutter engineer（[@yukimiyake0607](https://github.com/yukimiyake0607)）

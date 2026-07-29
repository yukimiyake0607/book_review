# 📚 読書レビュー管理アプリ（book_review）

![CI](https://github.com/yukimiyake0607/book_review/actions/workflows/ci.yml/badge.svg)
![Flutter](https://img.shields.io/badge/Flutter-stable-blue)

読んだ本を検索して登録し、評価・感想を記録する Flutter（iOS）アプリです。

## 機能

- **書籍検索** — 外部書籍APIと連携し、キーワードで本を検索
- **レビュー管理** — 評価（★）と感想を登録・編集・削除
- **一覧 / 詳細** — 登録したレビューを一覧・詳細で表示（プルリフレッシュ対応）

## スクリーンショット

<!-- 検索 / 登録 / 一覧 の画面を後で貼る（例: <img src="docs/screenshots/search.png" width="240"> ） -->

_準備中_

## 設計方針

機能はシンプルですが、**規模拡大や複数人開発を見据えた構成・状態管理・エラー設計**に重点を置いています。設計判断の理由は [ADR](docs/adr/) に記録しています。

### アーキテクチャ：レイヤード（依存性逆転）＋フィーチャーファースト

依存の向きを一方向に統一し、ドメイン層を外部技術から独立させています。機能単位でフォルダを切り、その中に4層（presentation / application / domain / infrastructure）を配置します。

```
presentation ── application ── domain ◄── infrastructure
   UI/状態         ユースケース      中核         API/DB実装
                                  ▲──────────────┘
                            domain の interface を infra が実装
```

> 機能数に対しては過剰にも見えますが、**規模が大きくなっても破綻しない構成を意図的に選んでいます**（→ [ADR-0002](docs/adr/0002-layered-architecture.md)）。

### 状態・エラー設計

非同期状態は `AsyncValue` で loading / error / data を統一的に扱います。失敗はドメイン層で **sealed class の型**として表現しています。

> 単純なアプリなら try/catch でも足りますが、**実務での明示的・網羅的なエラーハンドリングを意識**してこの設計にしています（→ [ADR-0007](docs/adr/0007-error-handling.md)）。

## 設計判断の記録（ADR）

採用した技術・構成について、**採用理由だけでなく「検討した代替案」と「却下した理由」まで**残しています。

- [ADR-0002 レイヤードアーキテクチャとフィーチャーファースト構成](docs/adr/0002-layered-architecture.md)
- [ADR-0007 sealed class によるエラー設計](docs/adr/0007-error-handling.md)

その他の ADR は [`docs/adr/`](docs/adr/) を参照してください。

## 技術スタック

| 領域 | 技術 |
|---|---|
| フレームワーク | Flutter / Dart（`mise` でバージョン固定） |
| 状態管理 | Riverpod（`@riverpod` コード生成 / AsyncValue 中心） |
| ルーティング | go_router |
| モデル | freezed / json_serializable |
| ローカル保存 | shared_preferences |
| CI | GitHub Actions（analyze → format → test → build） |

## テスト

ユースケース・値オブジェクトの境界値・エラー分岐など「壊れると困る箇所」を中心に、unit / widget / integration を用意しています。API はフェイクに差し替え、ネットワーク非依存で実行します。

```bash
flutter test
```

## スコープと非機能要件

デモとしての範囲を明確にするため、**意図的にスコープ外とした項目**も記載します。
| 項目 | 現状・方針 |
|---|---|
| 認証・認可 | スコープ外。導入時はトークン管理＋`flutter_secure_storage` を想定し ADR 化予定 |
| 国際化（i18n） | 日本語のみ。多言語化は ARB での対応を想定 |
| アクセシビリティ | 基本的な `Semantics` のみ。WCAG 準拠までは未対応 |
| 監視・クラッシュ収集 | 未導入。導入時は Firebase Crashlytics を想定 |
| パフォーマンス | 一覧は小規模前提。大規模化時はページング／リスト仮想化を検討 |
| オフライン | 直近データを `shared_preferences` にキャッシュする簡易対応のみ |

## セットアップ

```bash
git clone https://github.com/yukimiyake0607/book_review.git
cd book_review

# Flutter/Dart のバージョンは mise で固定
mise trust
mise install

flutter pub get
dart run build_runner build --delete-conflicting-outputs

# 環境はエントリポイントで切り替え（dev / prod）
flutter run -t lib/main_dev.dart
```

要件：[mise](https://mise.jdx.dev/)（`mise.toml` で Flutter / Dart を固定）/ Xcode

## 作者

Yuki Miyake — Flutter engineer（[@yukimiyake0607](https://github.com/yukimiyake0607)）

## ライセンス

MIT License

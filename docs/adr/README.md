# Architecture Decision Records (ADR)

技術的な意思決定を、**採用理由だけでなく検討した代替案と却下理由まで**残すための記録。
フォーマットは軽量な [MADR](https://adr.github.io/madr/) 風で統一している。

| # | タイトル | ステータス |
|---|---|---|
| [0001](0001-state-management.md) | 状態管理に Riverpod を採用する / コード生成の可否 | Accepted |
| [0002](0002-layered-architecture.md) | レイヤードアーキテクチャ + フィーチャーファースト | Accepted |
| [0003](0003-local-cache.md) | レビュー永続化に shared_preferences | Accepted |
| [0004](0004-routing.md) | ルーティングに go_router | Accepted |
| [0005](0005-ci.md) | GitHub Actions による品質ゲート | Accepted |
| [0006](0006-schema-driven.md) | OpenAPI スキーマ駆動開発 | Superseded（0008） |
| [0007](0007-error-handling.md) | sealed class によるエラー設計 | Accepted |
| [0008](0008-book-search-api.md) | OpenAPI 廃止後の公開 API＋ローカル永続化 | Accepted |

## テンプレート

```md
# ADR-XXXX: タイトル

- ステータス: Proposed / Accepted / Superseded
- 日付: YYYY-MM-DD

## コンテキスト
（何を解決したいのか。前提・制約）

## 決定
（何を採用したか）

## 検討した代替案
（比較対象と、それを却下した理由）

## 結果（トレードオフ）
（この決定によって得たもの／諦めたもの）
```

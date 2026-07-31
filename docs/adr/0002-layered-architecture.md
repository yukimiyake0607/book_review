# ADR-0002: レイヤードアーキテクチャ + フィーチャーファースト

- ステータス: Accepted
- 日付: 2026-07-28

## コンテキスト

小規模な題材だが、「どう作るか」を示すことが目的のため、
**関心の分離**と**依存方向の一貫性**を明確に表現したい。
一方で、題材の規模に対して層を増やしすぎる過剰設計は避けたい。

## 決定

**4層のレイヤードアーキテクチャ（+ 依存性逆転）を、フィーチャーファーストで構成する。**

```
presentation ── application ── domain ◄── infrastructure
   UI/状態         ユースケース      中核         API/DB実装
                                  ▲──────────────┘
                            domain の interface を infrastructure が実装
```

- **presentation**: 画面・Widget・Riverpod プロバイダ。状態は `AsyncValue` で表現
- **application**: 分岐・複数ソース統合など**実質的な意図を持つ操作だけ**をユースケースにする（単純な委譲は置かず、presentation が repository を直接呼ぶ。例：「レビューを保存する」）
- **domain**: エンティティ・値オブジェクト・リポジトリ**インターフェース**。他層に依存しない
- **infrastructure**: API クライアント（生成コード）・キャッシュ・リポジトリ**実装**

依存は上位→下位の一方向。`infrastructure` は `domain` のインターフェースを実装することで、
矢印を逆転させ、`domain` を外部技術（dio / shared_preferences / 生成コード）から独立させる。

ディレクトリは**機能単位（feature-first）**で切り、各機能の中に上記4層を置く。

```
lib/src/features/<feature>/{presentation,application,domain,infrastructure}
```

## 検討した代替案

### a. レイヤーファースト（`lib/presentation`, `lib/application`, ...）
当初の要件定義書ではこの形だった。トップレベルを層で切る方式。
1機能の変更で複数のトップレベルディレクトリを横断することになり、
機能追加時の見通しとスケーラビリティで劣る。
[Code With Andrea の feature-first 推奨](https://codewithandrea.com/articles/flutter-project-structure/)
も踏まえ、feature-first に変更した。

### b. クリーンアーキテクチャ（UseCase を全操作で必須化・厳密な境界）
本題材の規模ではセレモニーが過剰。UseCase は「複数リポジトリの調整が必要な操作」や
「分岐など実質的な意図がある操作」に限定し、
単純な委譲では presentation が repository を直接呼ぶことも許容する（過剰設計の回避）。

具体例として、`reviews` の `SaveReviewUseCase`（`id` 有無で create/update を振り分ける）は
UseCase を置くが、`book_search` は単純な委譲のため UseCase を置かず、
`BookSearchController` が `BookRepository` を直接呼ぶ。

### 命名について
本アプリの `infrastructure` 層は、Code With Andrea の Riverpod Architecture でいう
**data 層**（repositories / data sources / DTO）に相当する。
「外部技術の実装が集まる層」であることを名前で明示したいため `infrastructure` を採用した。

## 結果（トレードオフ）

- 得たもの: 機能単位の高い凝集、`domain` の技術非依存、テスト時のリポジトリ差し替え容易性
- 諦めたもの: 小さな機能でも4ディレクトリを作る初期コスト
- 方針: 層はこの4つに固定し、これ以上増やさない（過剰設計の回避を明示）

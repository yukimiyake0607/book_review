# ブックレビュー管理アプリ 要件定義書

| 項目 | 内容 |
|---|---|
| ドキュメント種別 | 要件定義書（docs/requirements.md） |
| バージョン | 1.2 |
| 作成日 | 2026-07-27 |
| 更新日 | 2026-07-31 |
| 作成者 | Yuki Miyake（[@yukimiyake0607](https://github.com/yukimiyake0607)） |
| ステータス | スコープ確定（#12 / #15 反映済み） |

---

## 0. このリポジトリの位置づけ

**本リポジトリは、機能の多さやリリースを目的としたプロダクトではなく、設計判断とその根拠を提示することを目的とした技術デモである。**

読書記録という平易な題材を選んだのは、題材理解にコストをかけず、**アーキテクチャ・状態設計・エラーハンドリング・テストといった「どう作るか」に読み手の注意を集中させる**ためである。したがって機能はあえて少数に絞り、その代わり各機能をドメイン層からUI層まで一貫して作り込む。設計上の意思決定はすべて [`docs/adr/`](adr/) に記録している。

当初は OpenAPI スキーマ駆動（swagger_parser + Prism）を主眼のひとつとしていたが、公開書籍 API ＋ローカル永続化へ移行した（[ADR-0006](adr/0006-schema-driven.md) Superseded / [ADR-0008](adr/0008-book-search-api.md)）。「スキーマ合意の再現」より、**実ネットワーク・DTO/mapper・sealed エラー・ローカル SoT** の一貫した実装を見せる方針に更新している。

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
| F-01 | 書籍検索 | キーワードで書籍を検索する。Google Books API を手書きの dio クライアントで呼び出し、結果一覧を表示。ローディング/エラー/空/成功の各状態を明示的に扱う |
| F-02 | レビュー登録・編集・削除 | 検索結果から書籍を選び、評価（★1〜5）・感想・読了日を登録。`shared_preferences` へ永続化（CRUD）。書き込み完了後に一覧へ反映し、失敗時は一覧を変えずユーザーに通知する（楽観的更新は行わない） |
| F-03 | レビュー一覧・詳細 | 登録済みレビューの一覧表示（新着順）と詳細表示。プルリフレッシュで再読み込み |

### 2.2 Should（余力がある場合のみ）

| ID | 機能 | 概要 |
|---|---|---|
| F-04 | フィルタ・ソート | 評価・読了日での絞り込みと並び替え |
| F-05 | 統計 | 月別読了数、評価分布の簡易可視化 |

### 2.3 スコープ外

- ユーザー登録・認証（本デモでは単一ユーザー前提。認証を入れる場合の設計方針のみADRに記述する）
- 複数端末同期・サーバ上のレビュー共有
- SNS共有、他ユーザーとの交流
- 課金・広告・プッシュ通知
- タグ・シリーズ管理などの拡張メタデータ

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
| 書籍検索 | Google Books API。手書き dio + Freezed DTO + `toDomain()`。APIキーは `dart-define-from-file` で注入（リポジトリに直書きしない） | [ADR-0008](adr/0008-book-search-api.md) |
| レビュー | `shared_preferences` に DTO の JSON 配列として保存し、これを単一の情報源（SoT）とする | [ADR-0003](adr/0003-local-cache.md)、[ADR-0008](adr/0008-book-search-api.md) |

OpenAPI / swagger_parser / Prism は採用後に廃止した。経緯は [ADR-0006](adr/0006-schema-driven.md)（Superseded）と [ADR-0008](adr/0008-book-search-api.md) を参照。

## 5. 状態・エラーハンドリング設計

- 非同期状態は Riverpod の `AsyncValue`（loading/error/data）で統一的に表現する
- 失敗は sealed class（`AppException`）で型として扱う。例外の握りつぶしを禁止する
- **F-01（検索）**：`AsyncValue` の error を画面で表示する（エラー設計の主役）
- **F-02（レビュー保存・削除）**：永続化完了まで待ち、成功後に一覧へ反映。失敗時は一覧を変えず `AppException.message` を通知する（**楽観的更新・ロールバックは行わない**／ADR-0008 方針B）

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
| 対応OS | iOS 16以上（開発者アカウント保有）。Androidはビルド可能な状態を維持 |
| パフォーマンス | 一覧のスクロールで不要なrebuildを起こさない（const・キー・プロバイダ粒度で最適化） |
| テスト容易性 | ドメイン層をインターフェース越しに差し替え可能にし、ユースケースを外部依存なしでテストできること |
| 品質ゲート | CI（analyze / format / test）を通過しないコードはmainにマージしない |
| 可読性 | custom_lint / riverpod_lint（analysis_options.yaml）で規約を機械的に強制する |
| セットアップ | clone 後は Google Books API キーのローカル配置が必要（キーは git 管理外）。手順は README に記載 |

## 8. 技術選定（サマリ）

各項目の選定理由・代替案・トレードオフは対応するADRに記述する。

| 領域 | 採用技術 | ADR |
|---|---|---|
| フレームワーク | Flutter（stable）/ Dart | — |
| 状態管理 | Riverpod（`@riverpod` コード生成、AsyncValue中心） | [ADR-0001](adr/0001-state-management.md) |
| アーキテクチャ | レイヤード＋依存性逆転（feature-first） | [ADR-0002](adr/0002-layered-architecture.md) |
| レビュー永続化 | shared_preferences（SoT） | [ADR-0003](adr/0003-local-cache.md) |
| ルーティング | go_router | [ADR-0004](adr/0004-routing.md) |
| モデル | freezed / json_serializable（DTO） | — |
| ネットワーク | dio（手書きクライアント）+ Google Books API | [ADR-0008](adr/0008-book-search-api.md) |
| エラー設計 | sealed class（`AppException`） | [ADR-0007](adr/0007-error-handling.md) |
| CI | GitHub Actions（analyze → format → test → build） | [ADR-0005](adr/0005-ci.md) |
| （廃止）APIスキーマ駆動 | OpenAPI + swagger_parser + Prism | [ADR-0006](adr/0006-schema-driven.md) Superseded |

## 9. テスト方針

「壊れると困る箇所」を狙って書く。カバレッジの数値ではなくテスト対象の選定意図を重視する。

| 種別 | 対象 |
|---|---|
| unit | ユースケース（保存の create/update 分岐）、ドメインロジック（`Rating`）、DTO⇄ドメインのマッピング、エラー分岐、レビュー CRUD のローカル永続化 |
| widget | 検索画面（loading / error / empty / success）、レビュー登録フォームのバリデーション |
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

> Should（F-04/F-05）は余力に応じて実施する。

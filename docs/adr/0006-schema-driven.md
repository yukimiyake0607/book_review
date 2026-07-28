# ADR-0006: OpenAPI スキーマ駆動開発

- ステータス: Accepted
- 日付: 2026-07-28

## コンテキスト

実務ではバックエンドチームと OpenAPI を介して API 仕様を合意し、
その仕様からクライアントを生成して開発している。この経験を個人リポジトリで再現し、
「スキーマを起点にクライアントを組み立てる能力」を示したい。
ただしバックエンド本体の実装はスコープ外とする。

## 決定

**`api/openapi.yaml` を唯一の情報源（SSoT）とし、`swagger_parser` で Dart クライアント
（dio + retrofit のインターフェースと json_serializable の DTO）を生成する。
開発・テストは `Prism` のモックサーバに対して行う。**

- 生成: `dart pub global run swagger_parser`（設定は [swagger_parser.yaml](../../swagger_parser.yaml)）
- モック: `npx @stoplight/prism-cli mock api/openapi.yaml`（既定 `http://localhost:4010`）
- DTO は **json_serializable のプレーンクラス**として生成し、ドメインの freezed エンティティへは
  infrastructure 層でマッピングする（境界を明確化。ADR-0002）

### 生成物のコミット方針

- `swagger_parser` の出力（`lib/src/api/**.dart`）は **ソースとしてコミットする**。
  外部ツールの実行結果をレビュー可能な形で残し、CI に swagger_parser 実行を持ち込まないため。
- `build_runner` の生成物（`*.g.dart`）は **コミットしない**。CI で再生成する（ADR-0005）。

## 検討した代替案

### a. openapi-generator (CLI, dart-dio)
多言語対応で実績豊富だが、Java/Docker への依存が増える。
Dart ネイティブで完結し、freezed/json_serializable と親和性の高い `swagger_parser` を採用した。

### b. DTO も freezed で生成する
`swagger_parser` は freezed 出力も可能だが、本環境で固定している freezed 2.x と
生成器が想定する freezed バージョンの差異による破綻を避けるため、DTO は json_serializable とした。
不変性やコピーが必要なのは**ドメイン**エンティティであり、そこは freezed で表現する。

### c. バックエンドを実装する
本リポジトリの目的（設計の提示）から外れるため不要。Prism のモックで十分。

## 結果（トレードオフ）

- 得たもの: 仕様と実装の乖離を防ぐ SSoT、型安全なクライアント、バックエンド非依存の開発/テスト
- 諦めたもの: retrofit_generator と retrofit のバージョン整合を手当てする必要
  （`retrofit` を `4.6.0` に固定。理由は pubspec に明記）

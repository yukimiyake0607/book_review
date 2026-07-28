# ADR-0001: 状態管理に Riverpod（コード生成）を採用する

- ステータス: Accepted
- 日付: 2026-07-28

## コンテキスト

本アプリは「非同期データの取得と表示（書籍検索・レビュー同期）」が中心である。
そのため状態管理には、以下が求められる。

- 非同期状態（loading / error / data）を型として統一的に扱えること
- UI から独立した場所（application 層）にロジックを置き、テスト時に依存を差し替えられること
- 不要な再描画を抑えられる購読の粒度を持てること
- 実務の標準的な書き味（ボイラープレート削減・型安全な family / 依存解決）に沿うこと

## 決定

**Riverpod（`hooks_riverpod` 2.6 系）を、`@riverpod` コード生成（`riverpod_generator`）で採用する。**
非同期状態は `AsyncValue<T>` で表現し、Provider / `Notifier` / `AsyncNotifier` は
`@riverpod` アノテーションから生成する。あわせて `riverpod_lint`（`custom_lint` 経由）を
有効化し、Riverpod 固有の規約違反を機械的に検出する。
DI は Provider のオーバーライドで行い、テスト時にリポジトリをモックへ差し替える。

実務の多くのプロジェクトはコード生成方式を採用しているため、本リポジトリでもそれに揃える。

## ツールチェーンの固定（重要）

このリポジトリは `mise` で **Flutter を固定**している（`mise.toml`。`fvm` は使わず `mise` に一本化）。
固定している Dart は **3.11.5**（analyzer 8 = Dart 3.12 系より一つ手前）であり、
コード生成に必要なパッケージ群の最新版はこの SDK ではビルドできない。
そこで **build_runner のビルドスクリプトと `custom_lint` プラグインが analyzer 7.6 系で
正しくコンパイルできるよう、関連パッケージを固定**している（`pubspec.yaml` の `dependency_overrides`）。

| パッケージ | 固定値 | 理由 |
| --- | --- | --- |
| `analyzer` | `7.6.0` | Dart 3.11 で導入可能な最新の 7.x（6.9〜7.2 は削除済みの `_macros` に依存し不可） |
| `analyzer_plugin` | `0.13.4` | analyzer 7.5+ 向けAPI。既定の `0.13.11` は analyzer 8 前提でビルド不能 |
| `custom_lint_visitor` | `1.0.0+7.7.0` | analyzer 7.4.5〜7.7.0 向け。既定は analyzer 9 向けの `+9.0.0` |
| `dart_style` | `3.1.1` | analyzer `^7.5.2` 向け。既定の `3.1.12` は analyzer 13+ 前提でプラグイン起動が失敗 |
| `freezed` | `3.1.0` | analyzer 7.x 対応の最終系（3.2.x は analyzer 9 を要求） |

生成物（`*.g.dart` / `*.freezed.dart`）はコミットせず、ローカル / CI で
`dart run build_runner build` により再生成する（ADR-0006）。

## 検討した代替案

### a. Provider(package:provider) / setState
UIとロジックの分離や非同期状態の型表現が弱く、テスト容易性で劣るため却下。

### b. Provider を手書き（コード生成なし）
`analyzer_plugin` の非互換を避けられる利点はあるが、実務の標準（コード生成）から外れ、
`riverpod_lint` の恩恵も受けられない。上記のとおりバージョン固定で生成方式を成立させられたため却下。

### c. グローバルの Flutter/Dart を 3.12+ に上げる
`analyzer` 8 系に上げれば固定は最小化できるが、開発マシン全体へ影響する変更であり、
このリポジトリ単体の判断とは切り分けたい。プロジェクト側の `mise.toml` で SDK を固定し、
`dependency_overrides` で整合させる方式を採用した（環境非依存で再現可能）。

### d. Bloc
学習コストと本題材の規模に対する記述量が過剰で、Riverpod の `AsyncValue` の方が
非同期状態の表現に簡潔。却下。

## 結果（トレードオフ）

- 得たもの: 実務標準の `@riverpod` 生成方式、`riverpod_lint` による規約強制、型安全な DI、
  `mise` によるSDK固定で再現可能なビルド
- 諦めたもの: 依存の一部をピン留めする運用コスト（analyzer 8 / Dart 3.12 に上げれば解消）
- 将来: SDK を 3.12+ に上げられる環境では `dependency_overrides` を撤廃し、
  各パッケージを最新へ追従する（Provider を機能単位でファイル分割しているため移行は局所的）

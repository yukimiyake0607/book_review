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

**Riverpod 3 系を、`@riverpod` コード生成（`riverpod_generator`）で採用する。**
非同期状態は `AsyncValue<T>` で表現し、Provider / `Notifier` / `AsyncNotifier` は
`@riverpod` アノテーションから生成する。あわせて `riverpod_lint`（`custom_lint` 経由）を
有効化し、Riverpod 固有の規約違反を機械的に検出する。
DI は Provider のオーバーライドで行い、テスト時にリポジトリをモックへ差し替える。

実務の多くのプロジェクトはコード生成方式を採用しているため、本リポジトリでもそれに揃える。

## ツールチェーンの固定

このリポジトリは `mise` で **Flutter を固定**している（`mise.toml`。`fvm` は使わず `mise` に一本化）。
固定バージョンは **Flutter 3.41.7 / Dart 3.11.5**（stable）。
この SDK でも、Riverpod / freezed / analyzer などを**メジャー最新の同世代**へ揃えれば、
`dependency_overrides` なしで一貫して解決・ビルドできる（下表は解決結果の代表値）。

| パッケージ | バージョン |
| --- | --- |
| `hooks_riverpod` / `riverpod_annotation` | 3.x / 4.x |
| `riverpod_generator` / `riverpod_lint` | 4.x / 3.x |
| `freezed` / `freezed_annotation` | 3.2.x / 3.1.x |
| `analyzer` | 8.x |
| `custom_lint` | 0.8.x |

> 補足：各パッケージの「最新の最新（例: riverpod 3.4.x）」は Dart 3.12+ を要求するため、
> Dart 3.11.5 では**その一つ手前のメジャー最新**が選択される。実務上の最新機能は網羅できる。

生成物（`*.g.dart` / `*.freezed.dart`）はコミットせず、ローカル / CI で
`dart run build_runner build` により再生成する（ADR-0006）。

## Riverpod 2 → 3 での主な移行点（本コードで対応済み）

- 関数プロバイダの ref 型が `Ref` に統一（旧 `FooRef` 廃止）。`riverpod_annotation` が
  `Ref` / `AsyncValue` 等を再エクスポートするため、定義ファイルは `riverpod_annotation` のみで足りる。
- `AsyncValue.valueOrNull` は `value`（`T?`）に統一。
- `AsyncValue.copyWithPrevious` は内部APIになったため、`refresh()` では使用しない
  （loading 中の直前値保持はフレームワーク側で扱われ、スピナーは `RefreshIndicator` が担う）。

## 検討した代替案

### a. Provider(package:provider) / setState
UIとロジックの分離や非同期状態の型表現が弱く、テスト容易性で劣るため却下。

### b. Provider を手書き（コード生成なし）
実務の標準（コード生成）から外れ、`riverpod_lint` の恩恵も受けられない。
固定 SDK でも生成方式が問題なく成立するため却下。

### c. Bloc
学習コストと本題材の規模に対する記述量が過剰で、Riverpod の `AsyncValue` の方が
非同期状態の表現に簡潔。却下。

## 結果（トレードオフ）

- 得たもの: 実務標準の `@riverpod` 生成方式、`riverpod_lint` による規約強制、型安全な DI、
  `mise` によるSDK固定で再現可能なビルド、`dependency_overrides` に頼らない素直な依存グラフ
- 諦めたもの: 各パッケージの絶対最新（Dart 3.12+ 要求）への追従は、SDK 更新時まで見送り
- 将来: `mise` で Dart 3.12+ の stable に上げられる時点で、`flutter pub upgrade --major-versions`
  により最新へ追従する（機能単位でファイル分割しているため移行は局所的）

# ADR-0010: 認証を導入する場合の設計方針

- ステータス: Proposed（本リポジトリでは未実装。導入時に従う方針を先に確定させるための記録）
- 日付: 2026-08-03
- 関連: ADR-0002（レイヤードアーキテクチャ）、ADR-0003（shared_preferences を SoT とする）、ADR-0004（go_router）、ADR-0007（sealed エラー）、ADR-0008（データ層方針）

## コンテキスト

本アプリは単一ユーザー前提であり、認証は明確にスコープ外である（[requirements.md](../requirements.md) §2.3）。
一方で「認証が無いから考えていない」のと「入れないと決めたうえで、入れる場合の置き場所は決まっている」のは別である。
認証は **層の責務・SoT・エラー設計** のすべてに触れるため、後から入れる際に既存の設計判断（ADR-0002 / 0003 / 0007）と
矛盾しないかを、実装前に確認しておく価値がある。

このADRは実装を伴わない。**導入するとしたら、どの層の、どのファイルに、何を足すのか**を確定させることが目的である。

## 決定

認証を導入する場合、以下の 4 点に従う。既存の層構成（ADR-0002）は変更しない。

### 1. トークンの保管先は `flutter_secure_storage`（`shared_preferences` に置かない）

`shared_preferences` は iOS では平文の plist、Android では平文の XML に書かれる。
レビュー本文は漏れても被害が限定的だが、アクセストークンは他人が API を叩ける資格情報そのものであり、
同じ置き場所を使ってはならない。`flutter_secure_storage` は iOS Keychain / Android Keystore を使い、
OS のロック解除とアプリのサンドボックスに保護を委ねられる。

**保存するデータの機密度で保存先を分ける**という線引きにするため、レビューの SoT（ADR-0003）は
`shared_preferences` のまま変えない。「全部 secure storage にする」はしない。secure storage は
Keychain / Keystore アクセスのぶん低速で、一覧のたびに読む用途には向かないためである。

### 2. 認可の適用点は `goRouter` の `redirect` 1箇所に集約する

[`app_router.dart`](../../lib/src/routing/app_router.dart) の `goRouterProvider` はすでに Riverpod 管理下にあり、
ADR-0004 で「将来 `redirect` に認証状態の Provider を差し込める」ことを拡張余地として確保してある。
ここを具体化する。

- 認証状態の**契約**を domain 層に `AuthSession` として置く（現在のトークンの有無を表す
  `Stream<AuthState>` と、`signOut()` を持つインターフェース）
- 認証状態を `@riverpod` の `AuthController`（`AsyncValue<AuthState>`）で表現し、
  `AuthSession` の `Stream` を購読して自身の state を更新する
- `goRouter` は `ref.watch(authControllerProvider)` を読み、`redirect` で未認証なら `/sign-in` へ飛ばす
- `refreshListenable` に認証状態の変化を接続し、サインアウト時に現在の画面から自動的に退避させる

各画面の `build` で個別にログイン判定を書かない。判定が散ると「1画面だけガードを書き忘れる」が起きるうえ、
presentation 層が認証という横断関心を知ることになり、依存の向きが濁る。

### 3. トークン付与とリフレッシュは dio の `Interceptor`（infrastructure 境界）に閉じる

[`dio_provider.dart`](../../lib/src/core/network/dio_provider.dart) に `Interceptor` を追加し、
`onRequest` で `Authorization` ヘッダを付与、`onError` で 401 を捕捉してリフレッシュ → 元リクエスト再送を行う。

- リフレッシュの同時多発は 1 本にまとめる（複数リクエストが同時に 401 を受けた場合、リフレッシュは1回だけ走らせて他は待たせる）
- Interceptor が処理しきれなかった 401 は `mapDioException` で `AppException` へ写像する。
  ADR-0007 の「生の `DioException` を上位へ漏らさない」を守るため、`UnauthorizedException` を
  `AppException` の `final class` として追加する（enum ではなく sealed のバリアントを増やす）

repository 実装（`BookRepositoryImpl` 等）は認証を一切知らない。トークンの有無・期限は
すべて Interceptor の内側で完結させる。

#### 再送の再入条件を先に決めておく

`Interceptor` は全リクエストに掛かるため、条件を決めずに「401 ならリフレッシュして再送」と書くと
リフレッシュ自身の 401 がまたリフレッシュを呼び、無限ループになる。以下を決定に含める。

| 条件 | 決定 |
| --- | --- |
| リフレッシュ用リクエスト | 401 リフレッシュ処理の対象から除外する。専用の `Dio` インスタンス（Interceptor 未装着）で発行し、経路自体を分ける |
| 元リクエストの再送回数 | 1 回まで。再送後にまた 401 なら、リフレッシュしても解決しない失敗として扱い `UnauthorizedException` へ写像する |
| リフレッシュ失敗時の待機解放 | サインアウトへ倒す**前に**、進行中のリフレッシュを待っている全リクエストを失敗として解放する。解放し忘れると、待たせたリクエストが永久に完了せず画面が loading のまま止まる |

#### サインアウトへの遷移は `AuthSession` 経由にする（Interceptor から `AuthController` を触らない）

リフレッシュに失敗したら、トークンを破棄してサインアウト状態へ倒す。
ただしこの遷移を **Interceptor が `AuthController` を直接書き換える形で実装してはならない**。
`AuthController` は presentation 層であり、infrastructure 層の Interceptor がそれを更新すると
`presentation → application → domain ← infrastructure` の一方向依存（ADR-0002）が逆流する。

Interceptor は決定 2 の `AuthSession`（domain のインターフェース）に対して
「認証が失効した」ことだけを通知する。`AuthController` は `AuthSession` の `Stream` を
購読しているので、通知を受けて自分で state をサインアウトへ倒す。
`redirect` はその state 変化で発火し、UI 側は「どこで失敗したか」を知らないまま正しい画面へ移動する。

Interceptor が知るのは「失効を通知する口」だけで、その先に画面遷移があることも
Riverpod があることも知らない。テスト時も `AuthSession` のフェイクを渡せば、
Interceptor 単体で「リフレッシュ失敗 → 失効通知」を検証できる。

### 4. SoT の扱いは「ローカル SoT を維持する」を出発点にする

サーバ側にレビューを持たせる場合でも、`shared_preferences` をローカル SoT とする現在の構造（ADR-0008）は崩さず、
**サーバを同期先として後ろに足す**。オフラインでも一覧が開ける性質を失わずに済むためである。

ただしこの選択は「同期の衝突解決を自前で持つ」コストと引き換えになる。同期を本格的に導入する時点で、
ローカル SoT を維持するか、サーバを SoT にしてローカルはキャッシュへ格下げするかを、
別ADRとして比較し直す。本ADRではその判断を先送りすることを明示しておく。

#### ローカル SoT はユーザー単位で分離する

現在の `ReviewRepositoryImpl` は `shared_preferences` の**単一キー**にレビュー全件を書いている。
これは単一ユーザー前提だから成立している設計であり、認証を入れた瞬間に前提が壊れる。
サインアウトして別アカウントでサインインすると、前のユーザーのレビューがそのまま一覧に出る。
`shared_preferences` はアプリのアンインストールまで残るため、端末を共有した場合は他人のデータが見える。

- 保存キーをユーザー ID で名前空間化する（例: `reviews` → `reviews:<userId>`）。
  リポジトリはサインイン中のユーザー ID を受け取り、そのキーだけを読み書きする
- サインアウト時は該当ユーザーのキーを**消さない**（再サインインでオフラインでも一覧が開ける利点を残すため）。
  ただし「この端末からデータを消す」導線を設定画面に用意し、明示的な削除をユーザーが選べるようにする
- 認証導入以前に書かれた名前空間なしのキーは、初回サインイン時にそのユーザーのキーへ 1 度だけ移行し、
  移行後に旧キーを削除する。移行を省くと、既存ユーザーの記録が消えたように見える

## 検討した代替案

### a. Firebase Authentication を使う

サインイン UI・トークン更新・プロバイダ連携を自前で書かずに済み、実装量は最小になる。
一方で本リポジトリの主題は「層の分け方と依存の向き」であり、Firebase SDK を入れると
認証の設計判断の大半が SDK 側に隠れて、見せたいもの（境界の引き方）が残らない。
また、Firebase は presentation から直接呼べてしまうため、意識しないと層を貫通した実装になりやすい。
実務では有力な選択肢だが、このリポジトリの目的には合わないため却下する。

### b. トークンをメモリのみに保持する（永続化しない）

漏洩リスクは最小だが、アプリを再起動するたびにサインインが必要になる。
読書記録のような日常的に開くアプリでは体験が成立しないため却下する。

### c. `shared_preferences` にトークンを保存する

依存を増やさずに済むが、決定 1 のとおり平文保存となり、資格情報の置き場所として不適格。却下する。

### d. 各画面の `build` でログイン状態を判定してガードする

導入は簡単だが、判定が画面数だけ増えて書き忘れが起きる。
また、遷移してから弾くため一瞬保護対象の画面が描画される。決定 2 の `redirect` に一本化する。

### e. Interceptor から `AuthController` を直接サインアウトさせる

`ref.read(authControllerProvider.notifier).signOut()` を Interceptor の中で呼べば、
`AuthSession` という中間の契約を作らずに済み、記述量は明らかに少ない。
しかしこれは infrastructure 層が presentation 層の型を知るということであり、
ADR-0002 の依存方向に逆らう。層の分け方を主題にしているリポジトリで、
「認証だけは例外」を作ると、境界が守られているという主張自体が弱くなる。
Interceptor のテストにも Riverpod のコンテナが必要になるため、却下する。

## 結果（トレードオフ）

- 得たもの: 認証を追加する際に既存の層構成を変えなくてよいことの確認。
  presentation / application の既存コードは無変更で、追加は
  「secure storage」「domain の `AuthSession` インターフェース」「`AuthController`」
  「`redirect` への1行」「dio の Interceptor」「`UnauthorizedException`」に限定される
- 諦めたもの: `AuthSession` という間接層のぶん、Interceptor からサインアウトまでの
  経路が1段増える。依存方向を守る代償として受け入れる。
  また、レビューの保存キーをユーザー単位に変えるため、`ReviewRepositoryImpl` と
  そのキー設計には手が入る（domain の `ReviewRepository` の契約は変えない）
- 保留したもの: サーバ同期時の SoT の再検討（決定 4）。認証単体では判断材料が足りないため、
  同期を実装する時点で別ADRとして扱う。
  実装がないため、リフレッシュの同時実行制御は机上の方針にとどまる。
  導入時に本ADRを Accepted へ更新し、実装で判明した差分を追記する

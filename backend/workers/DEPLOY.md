# Cloudflare Workers デプロイ手順

## 1. セットアップ

### Wrangler CLIのインストール

```bash
npm install -g wrangler
# または
npm install wrangler --save-dev
```

### Cloudflareアカウントの認証

```bash
wrangler login
```

ブラウザが開き、Cloudflareアカウントでログインします。

## 2. 環境変数の設定

### 開発環境（.dev.vars）

`.dev.vars.example`をコピー

```bash
cp .dev.vars.example .dev.vars
```

`.dev.vars`を編集して、実際の値を設定

```env
GITHUB_APP_ID=YOUR_GITHUB_APP_ID
GITHUB_APP_PRIVATE_KEY="-----BEGIN RSA PRIVATE KEY-----
YOUR_PRIVATE_KEY_CONTENT_HERE
-----END RSA PRIVATE KEY-----"
```

重要: 秘密鍵は改行を含むため、引用符で囲む必要があります。

### 本番環境（Wrangler Secrets）

本番環境の環境変数は`wrangler secret put`コマンドで設定

```bash
# GitHub App IDを設定
wrangler secret put GITHUB_APP_ID
# プロンプトが表示されたら、App IDを入力（例: 1234567890）

# 秘密鍵を設定
wrangler secret put GITHUB_APP_PRIVATE_KEY
# プロンプトが表示されたら、秘密鍵の内容を貼り付け（改行を含む）
```

## 3. ローカル開発

```bash
npm install
npm run dev
```

開発サーバーが起動します（通常は `http://localhost:8787`）。

## 4. デプロイ

```bash
npm run deploy
```

デプロイ後、以下のようなURLが表示されます
```
https://github-app-backend.your-subdomain.workers.dev
```

実際のURLの確認方法
- `your-subdomain` は、Cloudflareアカウント/プロジェクトに割り当てられた実際のサブドメインです
- デプロイコマンド（`npm run deploy` または `wrangler publish`）の出力に、実際のURLが表示されます
- Cloudflareダッシュボードでも確認できます:
  - **Workers & Pages** → あなたのサービス名を選択 → **Overview** または **Triggers** タブ
  - または **Workers & Pages** → **Workers.dev** サブドメイン一覧

## 5. Flutterアプリの設定更新

デプロイ後、**Flutterフロントエンドリポジトリ**（この`backend/workers`リポジトリとは別のリポジトリ）で、`lib/config/app_config.dart`を開き、`_defaultBackendBaseUrl`をデプロイしたWorkers URLに変更してください。

```dart
// デプロイしたWorkersのURLに変更
static const String _defaultBackendBaseUrl = 'https://github-app-backend.your-subdomain.workers.dev';
```

**注意**: Flutterフロントエンドリポジトリの場所や詳細な設定方法については、フロントエンドリポジトリのREADMEを参照してください。

## トラブルシューティング

### jsonwebtokenが動作しない場合

Workersの`nodejs_compat`フラグが有効になっているか確認

```toml
# wrangler.toml
compatibility_flags = ["nodejs_compat"]
```

### 秘密鍵の設定エラー

- 秘密鍵に改行が含まれていることを確認
- `.dev.vars`ファイルでは引用符で囲む
- `wrangler secret put`では改行を含めて貼り付け

### CORSエラー

WorkersのコードでCORSヘッダーが正しく設定されているか確認してください。

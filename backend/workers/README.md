# GitHub App Backend (Cloudflare Workers)

GitHub App認証用のCloudflare Workers実装です。

## セットアップ

### 1. 依存関係のインストール

```bash
npm install
```

### 2. Wrangler CLIのインストール（グローバル、オプション）

```bash
npm install -g wrangler
```

### 3. Cloudflareアカウントの認証

```bash
wrangler login
```

### 4. 環境変数の設定

`.dev.vars.example`をコピーして`.dev.vars`を作成：

```bash
cp .dev.vars.example .dev.vars
```

`.dev.vars`ファイルを編集：

```env
GITHUB_APP_ID=2587071
GITHUB_APP_PRIVATE_KEY="-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA...
（秘密鍵の内容をそのまま貼り付け）
...
-----END RSA PRIVATE KEY-----"
```

**重要**: 秘密鍵は改行を含むため、引用符で囲む必要があります。

### 5. ローカル開発

```bash
npm run dev
```

開発サーバーが起動します（通常は `http://localhost:8787`）。

### 6. デプロイ

#### 環境変数を設定

本番環境の環境変数を設定：

```bash
# GitHub App IDを設定
wrangler secret put GITHUB_APP_ID
# プロンプトが表示されたら、App IDを入力

# 秘密鍵を設定
wrangler secret put GITHUB_APP_PRIVATE_KEY
# プロンプトが表示されたら、秘密鍵の内容を貼り付け（改行を含む）
```

#### デプロイ実行

```bash
npm run deploy
```

デプロイ後、以下のようなURLが表示されます：
```
https://github-app-backend.your-subdomain.workers.dev
```

## API エンドポイント

### GET /health

ヘルスチェック

**レスポンス**:
```json
{
  "status": "ok",
  "timestamp": "2024-01-04T00:00:00.000Z"
}
```

### POST /api/github/installation-token

Installation Access Tokenを取得

**リクエストボディ**:
```json
{
  "installationId": "12345678"
}
```

**レスポンス**:
```json
{
  "token": "ghs_xxxxxxxxxxxx",
  "expiresAt": "2024-01-04T01:00:00.000Z"
}
```

### GET /api/github/installations

インストール一覧を取得

**レスポンス**:
```json
{
  "installations": [
    {
      "id": 12345678,
      "account": {
        "login": "username",
        "type": "User"
      },
      "target_type": "User"
    }
  ]
}
```

## Flutterアプリの設定

デプロイ後、Flutterアプリの`app_config.dart`を更新：

```dart
// デプロイしたWorkersのURLに変更
static const String _defaultBackendBaseUrl = 'https://github-app-backend.your-subdomain.workers.dev';
```

## トラブルシューティング

### 秘密鍵の設定エラー

秘密鍵に改行が含まれていることを確認してください。`.dev.vars`ファイルでは引用符で囲む必要があります。

### JWT生成エラー

- 秘密鍵の形式が正しいか確認（PEM形式）
- 環境変数が正しく設定されているか確認

### CORSエラー

WorkersのコードでCORSヘッダーが設定されていることを確認してください。

## 参考リンク

- [Cloudflare Workers ドキュメント](https://developers.cloudflare.com/workers/)
- [Wrangler CLI ドキュメント](https://developers.cloudflare.com/workers/wrangler/)


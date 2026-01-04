# GitHub App Backend API

GitHub App認証用のバックエンドAPIサーバーです。

## 機能

- GitHub App JWT生成
- Installation Access Token取得
- インストール一覧取得

## セットアップ

### 1. 依存関係のインストール

```bash
npm install
```

### 2. 環境変数の設定

`.env.example`をコピーして`.env`を作成し、以下の値を設定してください：

```bash
cp .env.example .env
```

`.env`ファイルを編集：

```
GITHUB_APP_ID=your_app_id_here
GITHUB_APP_PRIVATE_KEY_PATH=./private-key.pem
PORT=3000
```

### 3. GitHub App秘密鍵の配置

GitHub Developer Settingsでダウンロードした秘密鍵（`.pem`ファイル）を`backend`ディレクトリに配置してください。

**重要**: `.gitignore`に`private-key.pem`と`.env`を追加してください。

### 4. サーバー起動

```bash
npm start
```

開発モード（自動リロード）:

```bash
npm run dev
```

## API エンドポイント

### GET /health

ヘルスチェック

**レスポンス**:
```json
{
  "status": "ok",
  "timestamp": "2024-01-01T00:00:00.000Z"
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
  "expiresAt": "2024-01-01T01:00:00.000Z"
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

## セキュリティ注意事項

- **秘密鍵は絶対にGitにコミットしないでください**
- `.env`ファイルもGitにコミットしないでください
- 本番環境では環境変数やSecrets Managerを使用してください
- CORS設定を本番環境に合わせて調整してください

## デプロイ

### Heroku

```bash
heroku create your-app-name
heroku config:set GITHUB_APP_ID=your_app_id
heroku config:set GITHUB_APP_PRIVATE_KEY="$(cat private-key.pem)"
heroku config:set PORT=3000
git push heroku main
```

### Vercel / Netlify Functions

サーバーレス関数としてデプロイすることも可能です。


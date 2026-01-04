# Cloudflare Workers テスト手順

## 1. ヘルスチェック

```bash
curl http://localhost:8787/health
```

期待されるレスポンス:
```json
{
  "status": "ok",
  "timestamp": "2024-01-04T..."
}
```

## 2. インストール一覧の取得

```bash
curl http://localhost:8787/api/github/installations
```

期待されるレスポンス:
```json
{
  "installations": [
    {
      "id": 123456789,
      "account": {
        "login": "sekinet813",
        "type": "User"
      }
    }
  ]
}
```

## 3. Installation Access Tokenの取得

```bash
curl -X POST http://localhost:8787/api/github/installation-token \
  -H "Content-Type: application/json" \
  -d '{"installationId": "123456789"}'
```

期待されるレスポンス:
```json
{
  "token": "ghs_xxxxxxxxxxxx",
  "expiresAt": "2024-01-04T..."
}
```

## 4. Flutterアプリの設定

`lib/config/app_config.dart`を確認:

```dart
// ローカル開発の場合
static const String _defaultBackendBaseUrl = 'http://localhost:8787';

// デプロイ後はWorkersのURLに変更
// static const String _defaultBackendBaseUrl = 'https://github-app-backend.your-subdomain.workers.dev';

// Installation ID
static const String _defaultInstallationId = '123456789';
```

## 5. デプロイ後の設定

デプロイ後、Flutterアプリの`app_config.dart`を更新:

```dart
static const String _defaultBackendBaseUrl = 'https://github-app-backend.your-subdomain.workers.dev';
```


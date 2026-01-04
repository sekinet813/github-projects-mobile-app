# GitHub Projects Mobile

GitHub Projects（new / Projects v2）を TODOアプリ感覚で扱うFlutterモバイルアプリです。
カンバン操作・期限管理・リマインドに特化し、  「モバイルだとGitHub Projectsが使いづらい」という課題を解決します。

## ✨ Features

- 📋 Kanban board view for GitHub Projects
- ✅ Use GitHub Projects like a TODO app
- 🔄 Drag & drop to update task status
- ⏰ Deadline reminders (push notifications)
- 📅 Calendar integration (Google / Apple Calendar)
- 📱 iOS & Android support (Flutter)

## 🎯 Motivation

GitHub公式モバイルアプリでは、以下の課題があります。

- カンバン操作ができない
- TODOアプリ的に使えない
- 期限やリマインド機能がない

本アプリは 「GitHub Projects × モバイルタスク管理」 に特化し、  
日常的に使える体験を提供することを目的としています。

## 🛠 Tech Stack

- Flutter
- Dart
- GitHub GraphQL API v4
- Riverpod (State Management)
- SQLite (Local cache)
- Firebase Cloud Messaging (Push notifications)

## 🚧 Status

This project is currently under active development.

Planned MVP features:
- GitHub OAuth login
- GitHub Projects Kanban view
- Task status update via drag & drop
- Deadline reminders

## 📌 Scope

- Supports GitHub Projects (Projects v2 only)
- Personal use (single user)
- Not intended to replace full project management tools

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (stable channel)
- Dart SDK (>=3.0.0)
- iOS development: Xcode
- Android development: Android Studio
- Node.js (バックエンドAPI用、v18以上推奨)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/sekinet813/github-projects-mobile-app.git
cd github-projects-mobile-app
```

2. Install dependencies:
```bash
# Flutter dependencies
flutter pub get

# Backend dependencies
cd backend
npm install
cd ..
```

3. Set up environment variables:
   
   プロジェクトルートに `.env` ファイルを作成し、以下の内容を追加してください：
   
   **ヒント**: `env.example` ファイルをコピーして `.env` ファイルを作成することもできます：
   ```bash
   cp env.example .env
   ```
   
   その後、`.env` ファイルを編集して実際の値を設定してください：
   ```env
   # バックエンドAPIのベースURL
   # 開発環境: http://localhost:3000
   # 本番環境: デプロイしたバックエンドのURL
   BACKEND_BASE_URL=http://localhost:3000
   
   # GitHub App Installation ID
   # バックエンドの /api/github/installations エンドポイントで取得可能
   # または、GitHub Appのインストール時に取得
   GITHUB_INSTALLATION_ID=your_installation_id_here
   ```
   
   **注意**: `.env` ファイルは `.gitignore` に含まれているため、リポジトリにコミットされません。
   本番環境では、環境変数として設定するか、CI/CDパイプラインで設定してください。
   
   **⚠️ 環境変数の移行について（既存のデプロイメント向け）**:
   
   以前のバージョンでは `GITHUB_REDIRECT_URL` という環境変数名を使用していましたが、現在は `GITHUB_REDIRECT_URI` に変更されています。
   
   既存のデプロイメントを更新する場合は、以下の手順を実行してください：
   
   1. `.env` ファイル（または環境変数設定）で `GITHUB_REDIRECT_URL` を `GITHUB_REDIRECT_URI` に変更：
      ```env
      # 変更前
      GITHUB_REDIRECT_URL=github-projects-mobile://callback
      
      # 変更後
      GITHUB_REDIRECT_URI=github-projects-mobile://callback
      ```
   
   2. CI/CDパイプラインやインフラ設定（Docker、Kubernetes、CloudFormation、Terraform など）でも同様に環境変数名を更新
   
   3. アプリケーションを再起動または再デプロイして変更を反映
   
   4. OAuth認証が正常に動作することを確認
   
   **注意**: この変更を行わないと、OAuth認証が失敗する可能性があります。
   
   **GitHub App の設定方法**:
   
   ⚠️ **重要**: このアプリは **GitHub App** を使用します。OAuth App ではありません。
   
   1. [GitHub Developer Settings](https://github.com/settings/developers) にアクセス
   2. "New GitHub App" をクリック（**"New OAuth App" ではない**）
   3. 以下の情報を入力：
      - **GitHub App name**: GitHub Projects Mobile（任意）
      - **Homepage URL**: 任意のURL（例: `https://github.com/your-username`）
      - **Webhook URL**: **空欄のまま**（未設定でOK）
      - **Organization permissions**:
        - **Projects**: Read-only 以上（ProjectV2にアクセスするために必要）
      - **Repository permissions**:
        - **Metadata**: Read-only（自動で設定されます）
        - **Projects**: Read-only 以上（リポジトリProjectにアクセスする場合）
      - **Where can this GitHub App be installed?**: 
        - "Only on this account" または "Any account" を選択
   4. "Create GitHub App" をクリック
   5. 生成された **App ID** をメモ
   6. **秘密鍵をダウンロード**:
      - "Generate a private key" をクリック
      - ダウンロードした `.pem` ファイルを `backend` ディレクトリに配置
   7. **GitHub Appをインストール**:
      - "Install App" をクリック
      - 自分のアカウントまたはOrganizationにインストール
      - インストール後のページで **Installation ID** をメモ

4. Set up Backend:
   
   ```bash
   cd backend
   ```
   
   `.env` ファイルを作成:
   ```env
   GITHUB_APP_ID=your_app_id_here
   GITHUB_APP_PRIVATE_KEY_PATH=./private-key.pem
   PORT=3000
   ```
   
   バックエンドサーバーを起動:
   ```bash
   npm start
   ```
   
   開発モード（自動リロード）:
   ```bash
   npm run dev
   ```

5. Configure Flutter App:
   
   **注意**: モバイルエミュレータ/シミュレータから `localhost` にアクセスする場合:
   - Android Emulator: `.env` ファイルで `BACKEND_BASE_URL=http://10.0.2.2:3000` を設定
   - iOS Simulator: `http://localhost:3000` でOK
   - 実機: バックエンドをデプロイするか、同じネットワーク内のIPアドレスを使用（例: `http://192.168.1.100:3000`）

6. Run the app:
```bash
flutter run
```

## 📁 Project Structure

```
lib/
├── config/          # アプリ設定（ルーティング、環境変数など）
├── screens/         # 画面（Splash, Login, Home, InstallationSetup）
├── widgets/         # 再利用可能なウィジェット
├── services/        # APIサービス層
│   ├── github_app_service.dart      # GitHub App認証サービス
│   ├── github_graphql_client.dart  # GraphQL APIクライアント
│   └── github_api_service.dart      # GitHub APIサービス
├── repositories/    # データリポジトリ層
│   ├── github_auth_repository.dart  # 認証リポジトリ
│   └── github_repository.dart       # GitHubデータリポジトリ
├── models/          # データモデル
├── providers/       # Riverpodプロバイダー
└── theme/           # テーマ定義

backend/
├── server.js        # Express.jsサーバー
├── package.json     # Node.js依存関係
└── .env             # 環境変数（.gitignoreに含まれる）
```

## 🔐 Authentication Flow

このアプリは **GitHub App** の認証フローを使用します：

1. **JWT生成** (バックエンド):
   - GitHub Appの秘密鍵を使用してJWTを生成
   - JWTは10分間有効

2. **Installation Access Token取得** (バックエンド):
   - JWTを使用してInstallation Access Tokenを取得
   - トークンは1時間有効

3. **GraphQL API呼び出し** (Flutter):
   - Installation Access Tokenを使用してGitHub GraphQL APIを呼び出し
   - ProjectV2データを取得

**セキュリティ**:
- 秘密鍵はバックエンドでのみ管理（Flutterアプリには含まれない）
- Installation Access TokenはSecureStorageに保存
- トークンは1時間で期限切れ（必要に応じて自動リフレッシュ）

## 📄 License

MIT License

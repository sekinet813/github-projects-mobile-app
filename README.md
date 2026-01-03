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

### Installation

1. Clone the repository:
```bash
git clone https://github.com/sekinet813/github-projects-mobile-app.git
cd github-projects-mobile-app
```

2. Install dependencies:
```bash
flutter pub get
```

3. Set up environment variables:
   
   プロジェクトルートに `.env` ファイルを作成し、以下の内容を追加してください：
   
   **ヒント**: `.env.example` ファイルをコピーして `.env` ファイルを作成することもできます：
   ```bash
   cp .env.example .env
   ```
   
   その後、`.env` ファイルを編集して実際の値を設定してください：
   ```env
   # GitHub OAuth Configuration
   GITHUB_CLIENT_ID=your_github_client_id_here
   GITHUB_REDIRECT_URI=github-projects-mobile://callback
   
   # GitHub API (Optional)
   GITHUB_API_BASE_URL=https://api.github.com/graphql
   ```
   
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
   
   **GitHub App の設定方法（Device Flow）**:
   
   ⚠️ **重要**: このアプリは **GitHub App** を使用します。OAuth App ではありません。
   
   1. [GitHub Developer Settings](https://github.com/settings/developers) にアクセス
   2. "New GitHub App" をクリック（**"New OAuth App" ではない**）
   3. 以下の情報を入力：
      - **GitHub App name**: GitHub Projects Mobile（任意）
      - **Homepage URL**: 任意のURL（例: `https://github.com/your-username`）
      - **Webhook URL**: **空欄のまま**（未設定でOK）
        - Device Flowでの認証のみを使用するため、Webhookは不要です
        - 将来的にリアルタイム通知が必要になった場合のみ設定してください
      - **Repository permissions**:
        - **Metadata**: Read-only（自動で設定されます）
        - **Contents**: Read-only（必要に応じて）
        - **Projects**: Read & write（プロジェクト管理に必要）
      - **Where can this GitHub App be installed?**: 
        - "Only on this account" または "Any account" を選択
   4. "Create GitHub App" をクリック
   5. 生成された **Client ID** を `lib/config/app_config.dart` の `_defaultClientId` に設定
   6. **Device Flow を有効化**:
      - GitHub App の設定ページで "Device Flow" セクションを確認
      - Device Flow はデフォルトで有効になっているはずです
   
   **注意**: 
   - Device Flow を使用するため、Client Secret は不要です
   - Redirect URL の設定は不要です（Device Flow では使用されません）
   - **Webhook URL は未設定のまま**で問題ありません
   - カスタムURIスキームの設定は不要です（Device Flow では使用されません）
   - ユーザーは別のデバイス（PCなど）で認証コードを入力して認証を完了します
   
   **Webhook URL について**:
   
   現在の実装では、Webhook URL は**未設定のまま**で問題ありません。
   
   Webhook が必要になる可能性があるのは以下の場合です：
   - リアルタイムでプロジェクトの変更を検知したい場合
   - GitHub からのイベント通知を受け取りたい場合
   - サーバーサイドの処理が必要な場合
   
   ただし、このアプリはモバイルアプリで、プッシュ通知には Firebase Cloud Messaging を使用予定のため、
   GitHub Webhook は通常不要です。必要になった場合のみ、後から設定を追加できます。
   
   **`.env.example` ファイルについて**:
   
   プロジェクトルートに `.env.example` ファイルを作成し、以下の内容を保存してください（このファイルはバージョン管理に含まれます）：
   ```env
   # GitHub OAuth Configuration
   GITHUB_CLIENT_ID=your_github_client_id_here
   GITHUB_REDIRECT_URI=github-projects-mobile://callback
   
   # GitHub API (Optional)
   GITHUB_API_BASE_URL=https://api.github.com/graphql
   ```
   
   このファイルをコピーして `.env` ファイルを作成し、実際の値を設定してください。

4. Run the app:
```bash
flutter run
```

## 📁 Project Structure

```
lib/
├── config/          # アプリ設定（ルーティング、環境変数など）
├── screens/         # 画面（Splash, Login, Home）
├── widgets/         # 再利用可能なウィジェット
├── services/        # APIサービス層
├── repositories/    # データリポジトリ層
├── models/          # データモデル
├── providers/       # Riverpodプロバイダー
└── theme/           # テーマ定義
```

## 📄 License

MIT License

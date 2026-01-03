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
   ```env
   # GitHub OAuth Configuration
   GITHUB_CLIENT_ID=your_github_client_id_here
   GITHUB_REDIRECT_URL=your_redirect_url_here
   
   # GitHub API
   GITHUB_API_BASE_URL=https://api.github.com/graphql
   ```
   
   **注意**: `.env` ファイルは `.gitignore` に含まれているため、Gitにはコミットされません。

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

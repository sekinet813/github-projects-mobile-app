import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// アプリケーション全体の設定を管理するクラス
class AppConfig {
  static const _storage = FlutterSecureStorage();

  // バックエンドAPIのベースURL
  // 環境変数または.envファイルから読み込む
  // 優先順位: 環境変数 > .envファイル > デフォルト値（開発環境用）
  static String get _defaultBackendBaseUrl {
    // 環境変数から読み込み
    final envUrl = Platform.environment['BACKEND_BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl;
    }

    // .envファイルから読み込み
    final dotenvUrl = dotenv.env['BACKEND_BASE_URL'];
    if (dotenvUrl != null && dotenvUrl.isNotEmpty) {
      return dotenvUrl;
    }

    // デフォルト値（開発環境用）
    if (kDebugMode) {
      return 'http://localhost:3000';
    }

    // 本番環境で値が設定されていない場合はエラー
    throw Exception('BACKEND_BASE_URL is not set. '
        'Please set it in .env file or as an environment variable.');
  }

  // GitHub App Installation ID
  // 環境変数または.envファイルから読み込む
  // 優先順位: 環境変数 > .envファイル > デフォルト値（開発環境用）
  static String get _defaultInstallationId {
    // 環境変数から読み込み
    final envId = Platform.environment['GITHUB_INSTALLATION_ID'];
    if (envId != null && envId.isNotEmpty) {
      return envId;
    }

    // .envファイルから読み込み
    final dotenvId = dotenv.env['GITHUB_INSTALLATION_ID'];
    if (dotenvId != null && dotenvId.isNotEmpty) {
      return dotenvId;
    }

    // デフォルト値（開発環境用）
    if (kDebugMode) {
      return ''; // 開発環境では空文字列を許可
    }

    // 本番環境で値が設定されていない場合はエラー
    throw Exception('GITHUB_INSTALLATION_ID is not set. '
        'Please set it in .env file or as an environment variable.');
  }

  // GitHub API設定
  static String get githubApiBaseUrl => 'https://api.github.com/graphql';

  // バックエンドAPIのベースURL
  static String get backendBaseUrl => _defaultBackendBaseUrl;

  // GitHub App Installation ID
  // SecureStorageから読み込む。なければデフォルト値を使用
  static Future<String> get installationId async {
    final stored = await _storage.read(key: 'github_installation_id');
    return stored ?? _defaultInstallationId;
  }

  /// Installation IDを保存
  static Future<void> saveInstallationId(String installationId) async {
    await _storage.write(key: 'github_installation_id', value: installationId);
  }

  /// Installation IDを削除
  static Future<void> deleteInstallationId() async {
    await _storage.delete(key: 'github_installation_id');
  }

  /// アプリケーションの初期化処理
  static Future<void> initialize() async {
    // .envファイルを読み込む
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      // .envファイルが存在しない場合は無視（環境変数を使用）
      if (kDebugMode) {
        debugPrint(
            'Warning: .env file not found. Using environment variables or defaults.');
      }
    }
  }

  /// アクセストークンを保存
  static Future<void> saveAccessToken(String token) async {
    await _storage.write(key: 'github_access_token', value: token);
  }

  /// アクセストークンを取得
  static Future<String?> getAccessToken() async {
    return await _storage.read(key: 'github_access_token');
  }

  /// アクセストークンを削除
  static Future<void> deleteAccessToken() async {
    await _storage.delete(key: 'github_access_token');
    await _storage.delete(key: 'github_token_expires_at');
  }

  /// トークンの有効期限を保存
  static Future<void> saveTokenExpiresAt(DateTime expiresAt) async {
    await _storage.write(
      key: 'github_token_expires_at',
      value: expiresAt.toIso8601String(),
    );
  }

  /// トークンの有効期限を取得
  static Future<DateTime?> getTokenExpiresAt() async {
    final expiresAtString = await _storage.read(key: 'github_token_expires_at');
    if (expiresAtString == null || expiresAtString.isEmpty) {
      return null;
    }
    try {
      return DateTime.parse(expiresAtString);
    } catch (e) {
      return null;
    }
  }

  // ===== OAuth App 用メソッド =====

  /// OAuth state を保存
  static Future<void> saveOAuthState(String state) async {
    await _storage.write(key: 'github_oauth_state', value: state);
  }

  /// OAuth state を取得
  static Future<String?> getOAuthState() async {
    return await _storage.read(key: 'github_oauth_state');
  }

  /// OAuth state を削除
  static Future<void> deleteOAuthState() async {
    await _storage.delete(key: 'github_oauth_state');
  }

  /// OAuth access token を保存
  static Future<void> saveOAuthAccessToken(String token) async {
    await _storage.write(key: 'github_oauth_access_token', value: token);
  }

  /// OAuth access token を取得
  static Future<String?> getOAuthAccessToken() async {
    return await _storage.read(key: 'github_oauth_access_token');
  }

  /// OAuth access token を削除
  static Future<void> deleteOAuthAccessToken() async {
    await _storage.delete(key: 'github_oauth_access_token');
  }

  /// すべての認証情報を削除（ログアウト用）
  static Future<void> clearAllAuthData() async {
    // OAuth token を削除
    await deleteOAuthAccessToken();
    // OAuth state を削除
    await deleteOAuthState();
    // Installation Access Token を削除（後方互換性）
    await deleteAccessToken();
    // Installation ID を削除（後方互換性）
    await deleteInstallationId();
  }
}

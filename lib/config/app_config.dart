import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// アプリケーション全体の設定を管理するクラス
class AppConfig {
  static const _storage = FlutterSecureStorage();

  // アプリ開発者が作成した共有OAuth AppのClient ID
  // GitHub Developer SettingsでOAuth Appを作成し、取得したClient IDをここに設定してください
  static const String _defaultClientId = 'Iv23li32BwxqZFvZADW6';
  // Client Secret
  // 注意: Client Secretは機密情報です。本番環境では適切に保護してください
  static const String _defaultClientSecret =
      '0811e64d10b8269f1f852bff1b1ba47e3411c270';
  static const String _defaultRedirectUrl = 'github-projects-mobile://callback';

  // GitHub OAuth設定（OAuth2 Authorization Code Flow）
  static String get githubClientId => _defaultClientId;

  static String get githubClientSecret => _defaultClientSecret;

  static String get githubRedirectUrl => _defaultRedirectUrl;

  // GitHub API設定
  static String get githubApiBaseUrl => 'https://api.github.com/graphql';

  /// アプリケーションの初期化処理
  static Future<void> initialize() async {
    // 必要に応じて初期化処理を追加
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
  }
}

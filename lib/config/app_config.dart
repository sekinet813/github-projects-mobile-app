import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// アプリケーション全体の設定を管理するクラス
class AppConfig {
  static const _storage = FlutterSecureStorage();
  
  // GitHub OAuth設定
  static String get githubClientId => 
      dotenv.env['GITHUB_CLIENT_ID'] ?? '';
  
  static String get githubRedirectUrl => 
      dotenv.env['GITHUB_REDIRECT_URL'] ?? '';
  
  // GitHub API設定
  static String get githubApiBaseUrl => 
      dotenv.env['GITHUB_API_BASE_URL'] ?? 'https://api.github.com/graphql';
  
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


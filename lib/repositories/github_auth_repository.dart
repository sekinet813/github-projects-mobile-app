import '../config/app_config.dart';

/// GitHub 認証を管理するリポジトリクラス
class GitHubAuthRepository {
  /// アクセストークンを取得
  ///
  /// 戻り値: アクセストークン（取得できない場合は null）
  Future<String?> getAccessToken() async {
    return await AppConfig.getAccessToken();
  }

  /// アクセストークンを保存
  ///
  /// [token] 保存するアクセストークン
  Future<void> saveAccessToken(String token) async {
    await AppConfig.saveAccessToken(token);
  }

  /// アクセストークンを削除
  Future<void> deleteAccessToken() async {
    await AppConfig.deleteAccessToken();
  }

  /// アクセストークンが存在するか確認
  ///
  /// 戻り値: トークンが存在する場合は true
  Future<bool> hasAccessToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}

import 'dart:developer' as developer;
import '../config/app_config.dart';
import '../services/github_app_service.dart';

/// GitHub 認証を管理するリポジトリクラス
///
/// GitHub AppのInstallation Access Tokenを管理します
class GitHubAuthRepository {
  final GitHubAppService _appService;

  GitHubAuthRepository({GitHubAppService? appService})
      : _appService = appService ?? GitHubAppService();

  /// アクセストークン（Installation Access Token）を取得
  ///
  /// 保存されているトークンがない場合、またはトークンが無効な場合、
  /// バックエンドAPIから新しいトークンを取得します。
  ///
  /// 戻り値: アクセストークン（取得できない場合は null）
  Future<String?> getAccessToken() async {
    final savedToken = await AppConfig.getAccessToken();

    // 保存されているトークンがある場合、有効期限をチェック
    if (savedToken != null && savedToken.isNotEmpty) {
      final expiresAt = await AppConfig.getTokenExpiresAt();
      final now = DateTime.now();

      // 有効期限が設定されており、まだ有効な場合は保存されているトークンを返す
      if (expiresAt != null && now.isBefore(expiresAt)) {
        return savedToken;
      }

      // 有効期限が切れている、または有効期限が設定されていない場合は新しいトークンを取得
    }

    // トークンがない場合、または有効期限が切れている場合は、Installation IDから取得を試みる
    final installationId = await AppConfig.installationId;
    if (installationId.isEmpty) {
      return null;
    }

    try {
      final response =
          await _appService.getInstallationAccessToken(installationId);
      final token = response['token'] as String?;
      final expiresAtString = response['expiresAt'] as String?;

      if (token == null || token.isEmpty) {
        return null;
      }

      // 有効期限を取得（レスポンスに含まれている場合は使用、なければ1時間後を設定）
      DateTime expiresAt;
      if (expiresAtString != null && expiresAtString.isNotEmpty) {
        try {
          expiresAt = DateTime.parse(expiresAtString);
        } catch (e) {
          // パースに失敗した場合は1時間後を設定
          expiresAt = DateTime.now().add(const Duration(hours: 1));
        }
      } else {
        // レスポンスに有効期限が含まれていない場合は1時間後を設定
        expiresAt = DateTime.now().add(const Duration(hours: 1));
      }

      // トークンと有効期限を保存
      await AppConfig.saveAccessToken(token);
      await AppConfig.saveTokenExpiresAt(expiresAt);

      return token;
    } catch (e, stackTrace) {
      // エラーが発生した場合はログを出力してnullを返す
      developer.log(
        'Installation Access Tokenの取得に失敗しました',
        name: 'GitHubAuthRepository.getAccessToken',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Installation Access Tokenを取得して保存
  ///
  /// [installationId] GitHub App Installation ID
  ///
  /// 戻り値: 取得したアクセストークン（取得できない場合は null）
  Future<String?> fetchAndSaveInstallationToken(String installationId) async {
    try {
      final response =
          await _appService.getInstallationAccessToken(installationId);
      final token = response['token'] as String?;
      final expiresAtString = response['expiresAt'] as String?;

      if (token == null || token.isEmpty) {
        return null;
      }

      // 有効期限を取得（レスポンスに含まれている場合は使用、なければ1時間後を設定）
      DateTime expiresAt;
      if (expiresAtString != null && expiresAtString.isNotEmpty) {
        try {
          expiresAt = DateTime.parse(expiresAtString);
        } catch (e) {
          // パースに失敗した場合は1時間後を設定
          expiresAt = DateTime.now().add(const Duration(hours: 1));
        }
      } else {
        // レスポンスに有効期限が含まれていない場合は1時間後を設定
        expiresAt = DateTime.now().add(const Duration(hours: 1));
      }

      // トークンと有効期限を保存
      await AppConfig.saveAccessToken(token);
      await AppConfig.saveTokenExpiresAt(expiresAt);

      return token;
    } catch (e, stackTrace) {
      // エラーが発生した場合はログを出力してnullを返す
      developer.log(
        'Installation Access Tokenの取得に失敗しました',
        name: 'GitHubAuthRepository.fetchAndSaveInstallationToken',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
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

  /// インストール一覧を取得
  ///
  /// 戻り値: インストール情報のリスト
  Future<List<Map<String, dynamic>>> getInstallations() async {
    return await _appService.getInstallations();
  }
}

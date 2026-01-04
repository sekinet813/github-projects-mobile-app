import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../exceptions/github_api_exception.dart';

/// GitHub App認証サービス
///
/// バックエンドAPIを呼び出してInstallation Access Tokenを取得します
class GitHubAppService {
  /// Installation Access Tokenを取得
  ///
  /// [installationId] GitHub App Installation ID
  ///
  /// 戻り値: Installation Access Tokenと有効期限を含むMap
  ///   - token: Installation Access Token
  ///   - expiresAt: 有効期限（ISO 8601形式の文字列、またはnull）
  ///
  /// 例外: GitHubApiException をスロー
  Future<Map<String, dynamic>> getInstallationAccessToken(
      String installationId) async {
    final backendBaseUrl = AppConfig.backendBaseUrl;

    if (backendBaseUrl.isEmpty) {
      throw GitHubApiException.networkError(
        'バックエンドURLが設定されていません。\n'
        'app_config.dartのbackendBaseUrlを設定してください。',
      );
    }

    try {
      final response = await http
          .post(
        Uri.parse('$backendBaseUrl/api/github/installation-token'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'installationId': installationId,
        }),
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw GitHubApiException.networkError('リクエストがタイムアウトしました');
        },
      );

      if (response.statusCode != 200) {
        final errorBody = response.body;
        Map<String, dynamic>? errorData;
        try {
          errorData = jsonDecode(errorBody) as Map<String, dynamic>?;
        } catch (_) {
          // JSONパースに失敗した場合はそのまま使用
        }

        final errorMessage = errorData?['error'] as String? ??
            'トークン取得に失敗しました: ${response.statusCode}';

        throw GitHubApiException.httpError(
          response.statusCode,
          errorMessage,
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final token = data['token'] as String?;

      if (token == null || token.isEmpty) {
        throw GitHubApiException.networkError('トークンが取得できませんでした');
      }

      // 有効期限を取得（レスポンスに含まれている場合）
      final expiresAt = data['expiresAt'] as String?;

      return {
        'token': token,
        'expiresAt': expiresAt,
      };
    } on GitHubApiException {
      rethrow;
    } on FormatException catch (e) {
      throw GitHubApiException.networkError(
        'レスポンスのパースに失敗しました: ${e.message}',
      );
    } catch (e) {
      throw GitHubApiException.networkError(
        '予期しないエラーが発生しました: ${e.toString()}',
      );
    }
  }

  /// インストール一覧を取得
  ///
  /// 戻り値: インストール情報のリスト
  ///
  /// 例外: GitHubApiException をスロー
  Future<List<Map<String, dynamic>>> getInstallations() async {
    final backendBaseUrl = AppConfig.backendBaseUrl;

    if (backendBaseUrl.isEmpty) {
      throw GitHubApiException.networkError(
        'バックエンドURLが設定されていません。\n'
        'app_config.dartのbackendBaseUrlを設定してください。',
      );
    }

    try {
      final response = await http.get(
        Uri.parse('$backendBaseUrl/api/github/installations'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw GitHubApiException.networkError('リクエストがタイムアウトしました');
        },
      );

      if (response.statusCode != 200) {
        final errorBody = response.body;
        Map<String, dynamic>? errorData;
        try {
          errorData = jsonDecode(errorBody) as Map<String, dynamic>?;
        } catch (_) {
          // JSONパースに失敗した場合はそのまま使用
        }

        final errorMessage = errorData?['error'] as String? ??
            'インストール一覧の取得に失敗しました: ${response.statusCode}';

        throw GitHubApiException.httpError(
          response.statusCode,
          errorMessage,
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final installations = data['installations'] as List<dynamic>?;

      if (installations == null) {
        return [];
      }

      return installations.map((item) => item as Map<String, dynamic>).toList();
    } on GitHubApiException {
      rethrow;
    } on FormatException catch (e) {
      throw GitHubApiException.networkError(
        'レスポンスのパースに失敗しました: ${e.message}',
      );
    } catch (e) {
      throw GitHubApiException.networkError(
        '予期しないエラーが発生しました: ${e.toString()}',
      );
    }
  }
}

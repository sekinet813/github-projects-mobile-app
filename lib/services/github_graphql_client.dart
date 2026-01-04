import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../repositories/github_auth_repository.dart';
import '../exceptions/github_api_exception.dart';

/// GitHub GraphQL API v4 クライアント
///
/// GraphQL query / mutation を実行するための共通クライアントレイヤー
class GitHubGraphQLClient {
  final String baseUrl = AppConfig.githubApiBaseUrl;
  final GitHubAuthRepository _authRepository;

  GitHubGraphQLClient({GitHubAuthRepository? authRepository})
      : _authRepository = authRepository ?? GitHubAuthRepository();

  /// GraphQL query / mutation を実行
  ///
  /// [document] GraphQL query または mutation 文字列
  /// [variables] クエリ変数（オプション）
  ///
  /// 戻り値: APIレスポンスのJSONマップ
  ///
  /// 例外: GitHubApiException をスロー
  Future<Map<String, dynamic>> execute({
    required String document,
    Map<String, dynamic>? variables,
  }) async {
    // アクセストークンを取得
    final token = await _authRepository.getAccessToken();
    if (token == null || token.isEmpty) {
      throw GitHubApiException.tokenNotFound();
    }

    try {
      // GraphQL リクエストを送信
      final response = await http
          .post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'query': document,
          if (variables != null) 'variables': variables,
        }),
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw GitHubApiException.networkError('リクエストがタイムアウトしました');
        },
      );

      // HTTP エラーのチェック
      if (response.statusCode != 200) {
        throw GitHubApiException.httpError(
          response.statusCode,
          response.body,
        );
      }

      // JSON レスポンスをパース
      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;

      // GraphQL エラーのチェック
      if (jsonResponse.containsKey('errors')) {
        final errors = jsonResponse['errors'] as List<dynamic>;
        final errorMessages = errors
            .map((e) => e is Map<String, dynamic> ? e['message'] : e.toString())
            .join(', ');

        throw GitHubApiException.graphQLError(
          errorMessages,
          {'errors': errors},
        );
      }

      return jsonResponse;
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

  /// GraphQL query を実行
  ///
  /// [query] GraphQL query 文字列
  /// [variables] クエリ変数（オプション）
  ///
  /// 戻り値: APIレスポンスのJSONマップ
  Future<Map<String, dynamic>> query({
    required String query,
    Map<String, dynamic>? variables,
  }) async {
    return execute(document: query, variables: variables);
  }

  /// GraphQL mutation を実行
  ///
  /// [mutation] GraphQL mutation 文字列
  /// [variables] ミューテーション変数（オプション）
  ///
  /// 戻り値: APIレスポンスのJSONマップ
  Future<Map<String, dynamic>> mutation({
    required String mutation,
    Map<String, dynamic>? variables,
  }) async {
    return execute(document: mutation, variables: variables);
  }
}

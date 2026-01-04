import 'github_graphql_client.dart';
import '../repositories/github_auth_repository.dart';

/// GitHub GraphQL API を扱うサービスクラス
///
/// 後方互換性のため、既存のメソッドを提供。
/// 内部では GitHubGraphQLClient を使用。
class GitHubApiService {
  final GitHubGraphQLClient _graphQLClient;

  GitHubApiService({GitHubAuthRepository? authRepository})
      : _graphQLClient = GitHubGraphQLClient(authRepository: authRepository);

  /// GraphQLクエリを実行
  ///
  /// [query] GraphQLクエリ文字列
  /// [variables] クエリ変数（オプション）
  ///
  /// 戻り値: APIレスポンスのJSONマップ
  Future<Map<String, dynamic>> executeQuery(
    String query, {
    Map<String, dynamic>? variables,
  }) async {
    return _graphQLClient.query(query: query, variables: variables);
  }

  /// GraphQLミューテーションを実行
  ///
  /// [mutation] GraphQLミューテーション文字列
  /// [variables] ミューテーション変数（オプション）
  ///
  /// 戻り値: APIレスポンスのJSONマップ
  Future<Map<String, dynamic>> executeMutation(
    String mutation, {
    Map<String, dynamic>? variables,
  }) async {
    return _graphQLClient.mutation(mutation: mutation, variables: variables);
  }

  /// ダミーデータを返す（開発用）
  /// 実際の実装は次フェーズで行う
  Future<Map<String, dynamic>> getProjects() async {
    // TODO: 実際のGraphQLクエリを実装
    await Future.delayed(const Duration(milliseconds: 500));
    return {
      'data': {
        'viewer': {
          'projectsV2': {
            'nodes': [],
          },
        },
      },
    };
  }
}

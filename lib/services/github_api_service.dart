import 'github_graphql_client.dart';
import '../repositories/github_auth_repository.dart';
import '../repositories/github_oauth_repository.dart';

/// GitHub GraphQL API を扱うサービスクラス
///
/// 後方互換性のため、既存のメソッドを提供。
/// 内部では GitHubGraphQLClient を使用。
class GitHubApiService {
  final GitHubGraphQLClient _graphQLClient;

  GitHubApiService({
    GitHubAuthRepository? authRepository,
    GitHubOAuthRepository? oauthRepository,
  }) : _graphQLClient = GitHubGraphQLClient(
          authRepository: authRepository,
          oauthRepository: oauthRepository,
        );

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

  /// Organization の ProjectV2 一覧を取得
  ///
  /// [orgLogin] Organization のログイン名
  ///
  /// 戻り値: APIレスポンスのJSONマップ
  Future<Map<String, dynamic>> getOrganizationProjects({
    required String orgLogin,
  }) async {
    const query = '''
      query OrganizationProjects(\$login: String!) {
        organization(login: \$login) {
          login
          id
          projectsV2(first: 20) {
            totalCount
            nodes {
              id
              title
              shortDescription
              number
              public
              closed
              owner {
                __typename
                ... on Organization {
                  id
                  login
                }
              }
            }
          }
        }
      }
    ''';

    return await _graphQLClient.query(
      query: query,
      variables: {'login': orgLogin},
    );
  }

  /// ユーザーが所属する Organization の一覧を取得
  ///
  /// 戻り値: APIレスポンスのJSONマップ
  Future<Map<String, dynamic>> getOrganizations() async {
    const query = '''
      query ViewerOrganizations {
        viewer {
          organizations(first: 20) {
            totalCount
            nodes {
              id
              login
              name
            }
          }
        }
      }
    ''';

    return await _graphQLClient.query(query: query);
  }

  /// 個人と Organization のプロジェクトを統合して取得
  ///
  /// 戻り値: APIレスポンスのJSONマップ（個人 + Organization のプロジェクト）
  Future<Map<String, dynamic>> getAllProjects() async {
    const query = '''
      query AllProjects {
        viewer {
          login
          id
          projectsV2(first: 20) {
            totalCount
            nodes {
              id
              title
              shortDescription
              number
              public
              closed
              owner {
                __typename
                ... on User {
                  id
                  login
                }
                ... on Organization {
                  id
                  login
                }
              }
            }
          }
          organizations(first: 20) {
            nodes {
              login
              id
              projectsV2(first: 20) {
                totalCount
                nodes {
                  id
                  title
                  shortDescription
                  number
                  public
                  closed
                  owner {
                    __typename
                    ... on Organization {
                      id
                      login
                    }
                  }
                }
              }
            }
          }
        }
      }
    ''';

    return await _graphQLClient.query(query: query);
  }

  /// GitHub Projects (Projects v2) 一覧を取得
  ///
  /// Installation Access Tokenを使用する場合、viewerはbotアカウントを指すため、
  /// インストールされたアカウント（User/Organization）のプロジェクトを直接クエリする必要がある
  ///
  /// 戻り値: APIレスポンスのJSONマップ
  Future<Map<String, dynamic>> getProjects({String? userLogin}) async {
    // userLoginが指定されている場合、そのユーザーのプロジェクトを取得
    // 指定されていない場合、viewerのプロジェクトを取得（OAuthトークンの場合）
    if (userLogin != null && userLogin.isNotEmpty) {
      // ユーザーアカウントのプロジェクトを直接クエリ
      // デバッグ用に、ユーザー情報も取得
      const query = '''
        query UserProjects(\$login: String!) {
          user(login: \$login) {
            login
            id
            projectsV2(first: 20) {
              totalCount
              nodes {
                id
                title
                shortDescription
                number
                public
                closed
                owner {
                  __typename
                  ... on User {
                    id
                    login
                  }
                  ... on Organization {
                    id
                    login
                  }
                }
              }
            }
          }
        }
      ''';

      return await _graphQLClient.query(
        query: query,
        variables: {'login': userLogin},
      );
    } else {
      // viewerのプロジェクトを取得（OAuthトークンの場合）
      const query = '''
        query ViewerProjects {
          viewer {
            login
            projectsV2(first: 20) {
              totalCount
              nodes {
                id
                title
                shortDescription
                number
                public
                closed
                owner {
                  __typename
                  ... on User {
                    id
                    login
                  }
                  ... on Organization {
                    id
                    login
                  }
                }
              }
            }
          }
        }
      ''';

      return await _graphQLClient.query(query: query);
    }
  }
}

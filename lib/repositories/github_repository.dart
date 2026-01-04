import '../services/github_api_service.dart';
import '../models/project.dart';
import '../models/project_detail.dart';
import '../exceptions/github_api_exception.dart';
import 'github_auth_repository.dart';
import 'github_oauth_repository.dart';

/// GitHub API とのやり取りを管理するリポジトリクラス
class GitHubRepository {
  final GitHubApiService _apiService;

  GitHubRepository({GitHubApiService? apiService})
      : _apiService = apiService ?? GitHubApiService();

  /// プロジェクト一覧を取得（個人 + Organization のプロジェクトを統合）
  ///
  /// 戻り値: プロジェクトのリスト
  Future<List<Project>> getProjects() async {
    try {
      // OAuth token が存在するかどうかを確認
      // 注意: プロバイダーから取得するべきだが、後方互換性のため直接インスタンス化
      final oauthRepository = GitHubOAuthRepository();
      final hasOAuthToken = await oauthRepository.hasAccessToken();

      // OAuth token を使用している場合、個人と Organization のプロジェクトを統合して取得
      // Installation Access Token を使用している場合の後方互換性も維持
      Map<String, dynamic> response;
      if (hasOAuthToken) {
        // OAuth token が存在する場合: viewer クエリを使用（個人 + Organization のプロジェクトを統合取得）
        response = await _apiService.getAllProjects();
      } else {
        // OAuth token が存在しない場合: Installation Access Token を使用
        String? userLogin;
        try {
          final authRepository = GitHubAuthRepository();
          final installations = await authRepository.getInstallations();
          if (installations.isNotEmpty) {
            final account =
                installations[0]['account'] as Map<String, dynamic>?;
            userLogin = account?['login'] as String?;
          }
        } catch (e) {
          // Installation 情報の取得に失敗した場合は無視
        }

        if (userLogin != null) {
          response = await _apiService.getProjects(userLogin: userLogin);
        } else {
          throw ReauthRequiredException('認証情報が取得できません。ログインしてください。');
        }
      }

      // GraphQLエラーのチェック（dataがnullでもerrorsが含まれる可能性がある）
      if (response.containsKey('errors')) {
        final errors = response['errors'] as List<dynamic>;
        final errorMessages = errors.map((e) {
          if (e is Map<String, dynamic>) {
            return e['message'] as String? ?? e.toString();
          }
          return e.toString();
        }).toList();

        final errorMessage = errorMessages.join(', ');

        // "Resource not accessible by integration" エラーを検出
        if (errorMessage.contains('Resource not accessible by integration') ||
            errorMessage.contains('not accessible by integration')) {
          throw ReauthRequiredException('プロジェクトにアクセスできません。\n\n'
              '【原因】\n'
              'OAuth App のスコープが不足しているか、Organization のプロジェクトにアクセスする権限がありません。\n\n'
              '【解決方法】\n'
              '1. 個人のプロジェクトの場合:\n'
              '   - アプリでログアウトして再ログイン（read:user, read:project スコープで認証）\n\n'
              '2. Organization のプロジェクトの場合:\n'
              '   - Organization の設定で OAuth App を承認:\n'
              '     https://github.com/organizations/{org-name}/settings/applications\n'
              '   - アプリでログアウトして再ログイン（read:org スコープも含めて認証）\n\n'
              'エラー詳細: $errorMessage');
        }

        // スコープ不足のエラーを検出
        if (errorMessage.contains('permission') ||
            errorMessage.contains('scope') ||
            errorMessage.contains('authorization')) {
          throw ReauthRequiredException('アクセス権限が不足しています。\n\n'
              '【必要なスコープ】\n'
              '- read:user（ユーザー情報の読み取り）\n'
              '- read:project（ProjectV2 の読み取り）\n'
              '- read:org（Organization のプロジェクトにアクセスする場合）\n\n'
              '【解決方法】\n'
              '1. アプリでログアウト\n'
              '2. 再度ログイン（新しいスコープで認証）\n'
              '3. Organization のプロジェクトにアクセスする場合、Organization の設定で OAuth App を承認\n\n'
              'エラー詳細: $errorMessage');
        }

        throw Exception('GraphQLエラー: $errorMessage');
      }

      // レスポンスのパース
      final data = response['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('レスポンスにdataが含まれていません');
      }

      // プロジェクトを統合して取得
      final projects = <Project>[];

      // 個人のプロジェクトを取得
      Map<String, dynamic>? accountData;
      if (data.containsKey('user')) {
        // Installation Access Token モードの場合
        accountData = data['user'] as Map<String, dynamic>?;
      } else if (data.containsKey('viewer')) {
        // OAuth token モードの場合
        accountData = data['viewer'] as Map<String, dynamic>?;
      }

      if (accountData != null) {
        final projectsV2 = accountData['projectsV2'] as Map<String, dynamic>?;
        if (projectsV2 != null) {
          final nodes = projectsV2['nodes'] as List<dynamic>?;
          if (nodes != null) {
            for (final node in nodes) {
              if (node != null) {
                try {
                  final projectJson = node as Map<String, dynamic>;
                  final ownerJson =
                      projectJson['owner'] as Map<String, dynamic>?;

                  if (ownerJson != null) {
                    final project = Project.fromJson({
                      'id': projectJson['id'],
                      'title': projectJson['title'],
                      'shortDescription': projectJson['shortDescription'],
                      'number': projectJson['number'],
                      'owner': ownerJson,
                    });
                    projects.add(project);
                  }
                } catch (e) {
                  // パースエラーは無視して続行
                }
              }
            }
          }
        }
      }

      // Organization のプロジェクトを取得（OAuth token の場合）
      if (data.containsKey('viewer')) {
        final viewer = data['viewer'] as Map<String, dynamic>?;
        final organizations = viewer?['organizations'] as Map<String, dynamic>?;
        final orgNodes = organizations?['nodes'] as List<dynamic>?;

        if (orgNodes != null) {
          for (final orgNode in orgNodes) {
            if (orgNode != null) {
              try {
                final orgJson = orgNode as Map<String, dynamic>;
                final orgProjectsV2 =
                    orgJson['projectsV2'] as Map<String, dynamic>?;
                final orgProjectNodes =
                    orgProjectsV2?['nodes'] as List<dynamic>?;

                if (orgProjectNodes != null) {
                  for (final orgProjectNode in orgProjectNodes) {
                    if (orgProjectNode != null) {
                      try {
                        final projectJson =
                            orgProjectNode as Map<String, dynamic>;
                        final ownerJson =
                            projectJson['owner'] as Map<String, dynamic>?;

                        if (ownerJson != null) {
                          final project = Project.fromJson({
                            'id': projectJson['id'],
                            'title': projectJson['title'],
                            'shortDescription': projectJson['shortDescription'],
                            'number': projectJson['number'],
                            'owner': ownerJson,
                          });
                          projects.add(project);
                        }
                      } catch (e) {
                        // パースエラーは無視して続行
                      }
                    }
                  }
                }
              } catch (e) {
                // パースエラーは無視して続行
              }
            }
          }
        }
      }

      if (projects.isEmpty && hasOAuthToken) {
        // OAuth token の場合、viewer が存在しない場合はエラー
        if (!data.containsKey('viewer')) {
          throw ReauthRequiredException('レスポンスにviewerが含まれていません。\n\n'
              '【考えられる原因】\n'
              '1. OAuth token が無効または期限切れ\n'
              '2. 必要なスコープが不足している\n'
              '3. GitHub API のエラー\n\n'
              '【解決方法】\n'
              '1. アプリでログアウトして再ログイン\n'
              '2. 必要なスコープ（read:user, read:project, read:org）で認証されているか確認');
        }
      }

      if (projects.isEmpty) {
        return [];
      }

      return projects;
    } catch (e) {
      // 既にExceptionの場合はそのまま再スロー
      if (e is Exception) {
        rethrow;
      }
      throw Exception('プロジェクトの取得に失敗しました: $e');
    }
  }

  /// プロジェクトの詳細を取得
  ///
  /// [projectId] プロジェクトID
  ///
  /// 戻り値: プロジェクトの詳細情報
  Future<ProjectDetail> getProjectDetails(String projectId) async {
    try {
      final response = await _apiService.getProjectDetail(projectId: projectId);

      // GraphQLエラーのチェック
      if (response.containsKey('errors')) {
        final errors = response['errors'] as List<dynamic>;
        final errorMessages = errors.map((e) {
          if (e is Map<String, dynamic>) {
            return e['message'] as String? ?? e.toString();
          }
          return e.toString();
        }).toList();

        final errorMessage = errorMessages.join(', ');

        // "Resource not accessible by integration" エラーを検出
        if (errorMessage.contains('Resource not accessible by integration') ||
            errorMessage.contains('not accessible by integration')) {
          throw ReauthRequiredException('プロジェクト詳細にアクセスできません。\n\n'
              '【原因】\n'
              'OAuth App のスコープが不足しているか、プロジェクトにアクセスする権限がありません。\n\n'
              '【解決方法】\n'
              '1. アプリでログアウトして再ログイン（read:user, read:project スコープで認証）\n'
              '2. Organization のプロジェクトの場合、Organization の設定で OAuth App を承認\n\n'
              'エラー詳細: $errorMessage');
        }

        // スコープ不足のエラーを検出
        if (errorMessage.contains('permission') ||
            errorMessage.contains('scope') ||
            errorMessage.contains('authorization')) {
          throw ReauthRequiredException('アクセス権限が不足しています。\n\n'
              '【必要なスコープ】\n'
              '- read:user（ユーザー情報の読み取り）\n'
              '- read:project（ProjectV2 の読み取り）\n'
              '- read:org（Organization のプロジェクトにアクセスする場合）\n\n'
              '【解決方法】\n'
              '1. アプリでログアウト\n'
              '2. 再度ログイン（新しいスコープで認証）\n\n'
              'エラー詳細: $errorMessage');
        }

        throw Exception('GraphQLエラー: $errorMessage');
      }

      // レスポンスのパース
      final data = response['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('レスポンスにdataが含まれていません');
      }

      final node = data['node'] as Map<String, dynamic>?;
      if (node == null) {
        throw Exception('プロジェクトが見つかりません');
      }

      // ProjectDetail を作成
      return ProjectDetail.fromJson(node);
    } on ReauthRequiredException {
      rethrow;
    } on FormatException catch (e) {
      throw Exception('プロジェクト詳細のパースに失敗しました: ${e.message}');
    } catch (e) {
      // 既にExceptionの場合はそのまま再スロー
      if (e is Exception) {
        rethrow;
      }
      throw Exception('プロジェクト詳細の取得に失敗しました: $e');
    }
  }
}

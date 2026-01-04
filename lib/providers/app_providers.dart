import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/github_repository.dart';
import '../repositories/github_auth_repository.dart';
import '../repositories/github_oauth_repository.dart';
import '../services/github_api_service.dart';
import '../services/github_graphql_client.dart';
import '../services/github_app_service.dart';
import '../models/project.dart';
import '../models/project_detail.dart';

/// GitHub App サービスのプロバイダー
final githubAppServiceProvider = Provider<GitHubAppService>((ref) {
  return GitHubAppService();
});

/// GitHub OAuth リポジトリのプロバイダー
final githubOAuthRepositoryProvider = Provider<GitHubOAuthRepository>((ref) {
  return GitHubOAuthRepository();
});

/// GitHub 認証リポジトリのプロバイダー
final githubAuthRepositoryProvider = Provider<GitHubAuthRepository>((ref) {
  final appService = ref.watch(githubAppServiceProvider);
  return GitHubAuthRepository(appService: appService);
});

/// GitHub GraphQL クライアントのプロバイダー
final githubGraphQLClientProvider = Provider<GitHubGraphQLClient>((ref) {
  final authRepository = ref.watch(githubAuthRepositoryProvider);
  final oauthRepository = ref.watch(githubOAuthRepositoryProvider);
  return GitHubGraphQLClient(
    authRepository: authRepository,
    oauthRepository: oauthRepository,
  );
});

/// GitHub API サービスのプロバイダー
final githubApiServiceProvider = Provider<GitHubApiService>((ref) {
  final authRepository = ref.watch(githubAuthRepositoryProvider);
  final oauthRepository = ref.watch(githubOAuthRepositoryProvider);
  return GitHubApiService(
    authRepository: authRepository,
    oauthRepository: oauthRepository,
  );
});

/// GitHub リポジトリのプロバイダー
final githubRepositoryProvider = Provider<GitHubRepository>((ref) {
  final apiService = ref.watch(githubApiServiceProvider);
  return GitHubRepository(apiService: apiService);
});

/// 認証状態を管理するプロバイダー
final authStateProvider = FutureProvider<bool>((ref) async {
  final authRepository = ref.watch(githubAuthRepositoryProvider);
  return await authRepository.hasAccessToken();
});

/// プロジェクト一覧を管理するプロバイダー
/// Loading / Success / Error の状態を自動的に管理
final projectsProvider = FutureProvider<List<Project>>((ref) async {
  final repository = ref.watch(githubRepositoryProvider);
  return await repository.getProjects();
});

/// プロジェクト詳細を管理するプロバイダー
/// Loading / Success / Error の状態を自動的に管理
///
/// [projectId] プロジェクトID
final projectDetailProvider = FutureProvider.family<ProjectDetail, String>(
  (ref, projectId) async {
    final repository = ref.watch(githubRepositoryProvider);
    return await repository.getProjectDetails(projectId);
  },
);

/// Status別に分類されたプロジェクトアイテムを管理するプロバイダー
/// Loading / Success / Error の状態を自動的に管理
///
/// [projectId] プロジェクトID
/// 戻り値: Status名をキー、そのStatusに属するitemsのリストを値とするMap
final projectItemsGroupedByStatusProvider =
    FutureProvider.family<Map<String, List<ProjectItem>>, String>(
  (ref, projectId) async {
    final projectDetail =
        await ref.watch(projectDetailProvider(projectId).future);
    return projectDetail.groupItemsByStatus();
  },
);

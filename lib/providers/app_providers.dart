import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/github_repository.dart';
import '../repositories/github_auth_repository.dart';
import '../services/github_api_service.dart';
import '../services/github_graphql_client.dart';
import '../services/github_oauth_service.dart';

/// GitHub 認証リポジトリのプロバイダー
final githubAuthRepositoryProvider = Provider<GitHubAuthRepository>((ref) {
  return GitHubAuthRepository();
});

/// GitHub GraphQL クライアントのプロバイダー
final githubGraphQLClientProvider = Provider<GitHubGraphQLClient>((ref) {
  final authRepository = ref.watch(githubAuthRepositoryProvider);
  return GitHubGraphQLClient(authRepository: authRepository);
});

/// GitHub OAuth サービスのプロバイダー
final githubOAuthServiceProvider = Provider<GitHubOAuthService>((ref) {
  return GitHubOAuthService();
});

/// GitHub API サービスのプロバイダー
final githubApiServiceProvider = Provider<GitHubApiService>((ref) {
  final authRepository = ref.watch(githubAuthRepositoryProvider);
  return GitHubApiService(authRepository: authRepository);
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

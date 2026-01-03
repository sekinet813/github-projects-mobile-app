import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/github_repository.dart';
import '../services/github_api_service.dart';
import '../services/github_oauth_service.dart';
import '../config/app_config.dart';

/// GitHub OAuth サービスのプロバイダー
final githubOAuthServiceProvider = Provider<GitHubOAuthService>((ref) {
  return GitHubOAuthService();
});

/// GitHub API サービスのプロバイダー
final githubApiServiceProvider = Provider<GitHubApiService>((ref) {
  return GitHubApiService();
});

/// GitHub リポジトリのプロバイダー
final githubRepositoryProvider = Provider<GitHubRepository>((ref) {
  final apiService = ref.watch(githubApiServiceProvider);
  return GitHubRepository(apiService: apiService);
});

/// 認証状態を管理するプロバイダー
final authStateProvider = FutureProvider<bool>((ref) async {
  final token = await AppConfig.getAccessToken();
  return token != null && token.isNotEmpty;
});

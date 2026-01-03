import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/github_repository.dart';
import '../services/github_api_service.dart';

/// GitHub API サービスのプロバイダー
final githubApiServiceProvider = Provider<GitHubApiService>((ref) {
  return GitHubApiService();
});

/// GitHub リポジトリのプロバイダー
final githubRepositoryProvider = Provider<GitHubRepository>((ref) {
  final apiService = ref.watch(githubApiServiceProvider);
  return GitHubRepository(apiService: apiService);
});


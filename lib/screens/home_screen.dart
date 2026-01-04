import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/app_config.dart';
import '../exceptions/github_api_exception.dart';
import '../providers/app_providers.dart';

/// ホーム画面
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  /// ログアウト処理
  static Future<void> _handleLogout(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      // OAuth token を削除
      final oauthRepository = ref.read(githubOAuthRepositoryProvider);
      await oauthRepository.logout();

      // すべての認証情報を削除
      await AppConfig.clearAllAuthData();

      // Riverpod プロバイダーのキャッシュをクリア
      ref.invalidate(projectsProvider);
      ref.invalidate(authStateProvider);
      ref.invalidate(githubRepositoryProvider);
      ref.invalidate(githubApiServiceProvider);
      ref.invalidate(githubGraphQLClientProvider);

      if (context.mounted) {
        context.go('/login');
      }
    } catch (e, stackTrace) {
      // エラーログを記録
      developer.log(
        'ログアウト処理中にエラーが発生しました',
        name: 'HomeScreen._handleLogout',
        error: e,
        stackTrace: stackTrace,
      );
      // エラーが発生してもログイン画面に遷移
      if (context.mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ホーム'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // ログアウト処理
              await _handleLogout(context, ref);
            },
            tooltip: 'ログアウト',
          ),
        ],
      ),
      body: projectsAsync.when(
        data: (projects) {
          if (projects.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.folder_open,
                      size: 80,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.5),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'プロジェクトが見つかりません',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'GitHub Projects (Projects v2) が\n存在しないか、アクセス権限がありません',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              final _ = await ref.refresh(projectsProvider.future);
            },
            child: ListView.builder(
              itemCount: projects.length,
              padding: const EdgeInsets.all(8.0),
              itemBuilder: (context, index) {
                final project = projects[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Icon(
                        Icons.folder,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    title: Text(
                      project.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (project.shortDescription != null &&
                            project.shortDescription!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              project.shortDescription!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        const SizedBox(height: 4.0),
                        Row(
                          children: [
                            Icon(
                              project.owner.isUser
                                  ? Icons.person
                                  : Icons.business,
                              size: 14,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                            const SizedBox(width: 4.0),
                            Text(
                              project.owner.login,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(width: 8.0),
                            Text(
                              '#${project.number}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // タップで次画面へ遷移（遷移先は空でOK）
                      // TODO: プロジェクト詳細画面への遷移を実装
                    },
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) {
          final errorMessage = error.toString().replaceAll('Exception: ', '');
          final needsReauth = error is ReauthRequiredException;

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 80,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'エラーが発生しました',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      errorMessage,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (needsReauth)
                    ElevatedButton.icon(
                      onPressed: () async {
                        // ログアウトして再ログイン
                        await HomeScreen._handleLogout(context, ref);
                      },
                      icon: const Icon(Icons.login),
                      label: const Text('再ログイン'),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: () {
                        ref.invalidate(projectsProvider);
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('再試行'),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

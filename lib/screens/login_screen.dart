import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../repositories/github_oauth_repository.dart';
import '../providers/app_providers.dart';

/// ログイン画面
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  late final GitHubOAuthRepository _oauthRepository;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _oauthRepository = GitHubOAuthRepository();

    // アプリ起動時に Deep Link で起動された場合の処理
    _handleInitialLink();

    // Deep Link の監視を開始（初期リンク処理後）
    _startListeningToDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  /// Deep Link の監視を開始
  void _startListeningToDeepLinks() {
    _linkSubscription = _oauthRepository.watchDeepLinks().listen(
      (uri) {
        _handleCallback(uri);
      },
      onError: (err) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Deep Link の処理中にエラーが発生しました: $err';
          });
        }
      },
    );
  }

  /// 初期 Deep Link を処理（アプリ起動時に Deep Link で起動された場合）
  Future<void> _handleInitialLink() async {
    try {
      final initialLink = await _oauthRepository.getInitialLink();
      if (initialLink != null) {
        _handleCallback(initialLink);
      }
    } catch (e) {
      // 予期しないエラーをログに記録
      // getInitialLink() は通常 null を返すが、プラットフォーム/パースエラーが発生する可能性がある
    }
  }

  /// OAuth コールバックを処理
  Future<void> _handleCallback(Uri uri) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final accessToken = await _oauthRepository.handleCallback(uri);

      if (accessToken.isEmpty) {
        throw Exception('トークンの取得に失敗しました');
      }

      if (!mounted) {
        return;
      }

      // プロジェクトプロバイダーを無効化して、新しいデータを取得するようにする
      ref.invalidate(projectsProvider);
      ref.invalidate(authStateProvider);
      ref.invalidate(githubRepositoryProvider);
      ref.invalidate(githubApiServiceProvider);
      ref.invalidate(githubGraphQLClientProvider);

      // ホーム画面へ遷移
      context.go('/home');
    } catch (e) {
      if (!mounted) {
        return;
      }

      final errorMessage = e.toString().replaceAll('Exception: ', '');

      // ログアウト後に古い Deep Link が来た場合は、エラーを表示せずに無視
      if (errorMessage.contains('認証セッションが無効になりました')) {
        setState(() {
          _isLoading = false;
          _errorMessage = null; // エラーを表示しない
        });
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = errorMessage;
      });
    }
  }

  Future<void> _handleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // ブラウザで認証を開始
      await _oauthRepository.launchAuth();

      // タイムアウト設定（例: 5分）
      Future.delayed(const Duration(minutes: 5), () {
        if (_isLoading && mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = '認証がタイムアウトしました。もう一度お試しください。';
          });
        }
      });

      // 注意: ここでは遷移しない
      // Deep Link のコールバックで _handleCallback が呼ばれる
      // ユーザーがブラウザで認証を完了するまで待機
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ログイン'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.login,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'GitHub Projects Mobile',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'GitHubアカウントでログインして\nプロジェクトを管理しましょう',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_isLoading) ...[
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    const Text(
                      'ブラウザで認証を完了してください...',
                      style: TextStyle(fontSize: 14),
                    ),
                  ] else ...[
                    ElevatedButton.icon(
                      onPressed: _handleSignIn,
                      icon: const Icon(Icons.login),
                      label: const Text('Sign in with GitHub'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

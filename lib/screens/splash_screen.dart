import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/app_config.dart';
import '../providers/app_providers.dart';

/// スプラッシュ画面
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // スプラッシュ表示のための待機時間
    await Future.delayed(const Duration(seconds: 2));
    
    // OAuth token を優先的に確認
    final oauthToken = await AppConfig.getOAuthAccessToken();
    
    // OAuth token がない場合、Installation Access Token を確認（後方互換性）
    final installationToken = oauthToken == null 
        ? await AppConfig.getAccessToken() 
        : null;
    
    if (!mounted) return;
    
    if ((oauthToken != null && oauthToken.isNotEmpty) ||
        (installationToken != null && installationToken.isNotEmpty)) {
      // トークンがある場合はホーム画面へ
      // プロジェクトプロバイダーを無効化して、新しいデータを取得するようにする
      ref.invalidate(projectsProvider);
      ref.invalidate(authStateProvider);
      
      if (!mounted) return;
      context.go('/home');
    } else {
      // トークンがない場合はログイン画面へ
      if (!mounted) return;
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // アプリロゴ（後で追加可能）
            Icon(
              Icons.code,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'GitHub Projects Mobile',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}



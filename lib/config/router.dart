import 'package:go_router/go_router.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';
import '../screens/installation_setup_screen.dart';

/// アプリケーションのルーティング設定
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      // カスタムURLスキーム（OAuth認証のリダイレクト）の場合は無視
      final uri = state.uri;
      if (uri.scheme == 'github-projects-mobile') {
        // カスタムURLスキームはflutter_web_auth_2プラグインが処理するため、
        // ここでは何もせずにnullを返す（現在のルートを維持）
        return null;
      }
      return null;
    },
    errorBuilder: (context, state) {
      // カスタムURLスキーム（OAuth認証のリダイレクト）の場合は無視
      final uri = state.uri;
      if (uri.scheme == 'github-projects-mobile') {
        // カスタムURLスキームはflutter_web_auth_2プラグインが処理するため、
        // ここではスプラッシュ画面に戻す
        return const SplashScreen();
      }
      // その他のエラーはスプラッシュ画面に戻す
      return const SplashScreen();
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/installation-setup',
        name: 'installation-setup',
        builder: (context, state) => const InstallationSetupScreen(),
      ),
    ],
  );
}

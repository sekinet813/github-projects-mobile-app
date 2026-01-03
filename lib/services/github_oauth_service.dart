import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

/// GitHub OAuth認証サービス（OAuth2 Authorization Code Flow対応）
class GitHubOAuthService {
  static const String _authorizationEndpoint =
      'https://github.com/login/oauth/authorize';
  static const String _tokenEndpoint =
      'https://github.com/login/oauth/access_token';
  static const List<String> _scopes = ['read:user', 'repo', 'project'];

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  String? _codeVerifier; // PKCE用のcode verifierを保存

  /// GitHub OAuth認証を開始
  ///
  /// Returns: アクセストークン
  /// Throws: Exception if authentication fails
  Future<String> authenticate() async {
    final clientId = AppConfig.githubClientId;
    final redirectUrl = Uri.parse(AppConfig.githubRedirectUrl);

    if (clientId.isEmpty) {
      throw Exception(
        'GitHub OAuth Client IDが設定されていません。\n'
        'app_config.dartの_defaultClientIdにClient IDを設定してください。\n'
        'GitHub Developer SettingsでOAuth Appを作成し、Client IDを取得してください。',
      );
    }

    try {
      // PKCE用のcode verifierとchallengeを生成
      _codeVerifier = _generateCodeVerifier();
      final codeChallenge = _generateCodeChallenge(_codeVerifier!);

      // 認証URLを構築（PKCEパラメータを含める）
      final authorizationUrl =
          Uri.parse(_authorizationEndpoint).replace(queryParameters: {
        'client_id': clientId,
        'redirect_uri': redirectUrl.toString(),
        'scope': _scopes.join(' '),
        'response_type': 'code',
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
      });

      // 外部ブラウザで認証URLを開く
      await _redirectToBrowser(authorizationUrl);

      // リダイレクトURLを受信
      final responseUrl = await _listenForAppLink();

      // 認証コードを取得
      final code = responseUrl.queryParameters['code'];
      if (code == null) {
        final error = responseUrl.queryParameters['error'];
        final errorDescription =
            responseUrl.queryParameters['error_description'];
        throw Exception(
          '認証コードが取得できませんでした。\n'
          'エラー: $error\n'
          '詳細: $errorDescription',
        );
      }

      // アクセストークンを取得（手動でHTTPリクエストを送信）
      final accessToken = await _exchangeCodeForToken(
        code: code,
        redirectUrl: redirectUrl,
        codeVerifier: _codeVerifier!,
      );

      return accessToken;
    } catch (e) {
      final errorMessage = e.toString();
      if (errorMessage.contains('User cancelled') ||
          errorMessage.contains('User canceled') ||
          errorMessage.contains('cancelled') ||
          errorMessage.contains('CANCELED')) {
        throw Exception('認証がキャンセルされました');
      }

      throw Exception('認証に失敗しました: $e');
    } finally {
      await _linkSubscription?.cancel();
      _linkSubscription = null;
    }
  }

  /// 外部ブラウザで認証URLを開く
  Future<void> _redirectToBrowser(Uri url) async {
    final launched = await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );

    if (!launched) {
      throw Exception('ブラウザを開くことができませんでした');
    }
  }

  /// リダイレクトURLを受信
  Future<Uri> _listenForAppLink() async {
    final completer = Completer<Uri>();

    try {
      // 初期リンクを確認（アプリが既に起動している場合）
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null &&
          initialLink.queryParameters.containsKey('code')) {
        completer.complete(initialLink);
        return completer.future;
      }
    } catch (e) {
      // 初期リンクの取得に失敗した場合はストリームで待機
    }

    // ストリームでリダイレクトURLを待機
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        if (!completer.isCompleted && uri.queryParameters.containsKey('code')) {
          completer.complete(uri);
        }
      },
      onError: (error) {
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      },
    );

    return completer.future;
  }

  /// PKCE用のcode verifierを生成
  String _generateCodeVerifier() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64UrlEncode(values).replaceAll('=', '');
  }

  /// PKCE用のcode challengeを生成（SHA256ハッシュ）
  String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }

  /// 認証コードをアクセストークンに交換（手動実装、PKCE対応）
  Future<String> _exchangeCodeForToken({
    required String code,
    required Uri redirectUrl,
    required String codeVerifier,
  }) async {
    final clientId = AppConfig.githubClientId;
    final clientSecret = AppConfig.githubClientSecret;

    final response = await http.post(
      Uri.parse(_tokenEndpoint),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'client_id': clientId,
        'client_secret': clientSecret,
        'code': code,
        'redirect_uri': redirectUrl.toString(),
        'code_verifier': codeVerifier, // PKCE用
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'トークン取得に失敗しました: ${response.statusCode} - ${response.body}',
      );
    }

    final data = json.decode(response.body) as Map<String, dynamic>;

    if (data.containsKey('error')) {
      final error = data['error'] as String;
      final errorDescription = data['error_description'] as String?;
      throw Exception(
        'トークン取得エラー: $error${errorDescription != null ? '\n詳細: $errorDescription' : ''}',
      );
    }

    final accessToken = data['access_token'] as String?;
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('アクセストークンが取得できませんでした');
    }

    return accessToken;
  }

  /// ログアウト（トークンを削除）
  Future<void> logout() async {
    await AppConfig.deleteAccessToken();
  }
}

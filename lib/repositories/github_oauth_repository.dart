import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';
import '../config/app_config.dart';

/// GitHub OAuth 認証を管理するリポジトリクラス
///
/// OAuth App を使用した認証フローを実装
class GitHubOAuthRepository {
  static const String _redirectUri = 'github-projects-mobile://callback';
  static const String _oauthScope = 'read:user read:project read:org';

  /// Client ID を Workers から取得
  Future<String> _getClientId() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.backendBaseUrl}/oauth/client-id'),
      );

      if (response.statusCode != 200) {
        throw Exception('Client ID の取得に失敗しました');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['client_id'] as String;
    } catch (e) {
      throw Exception('Client ID の取得に失敗しました: $e');
    }
  }

  /// State パラメータを生成（CSRF 対策）
  String _generateState() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  /// State を SecureStorage に保存
  Future<void> _saveState(String state) async {
    await AppConfig.saveOAuthState(state);
  }

  /// State を SecureStorage から取得
  Future<String?> _getState() async {
    return await AppConfig.getOAuthState();
  }

  /// State を削除
  Future<void> _deleteState() async {
    await AppConfig.deleteOAuthState();
  }

  /// PKCE code verifier を生成
  /// RFC 7636 に準拠: 43-128文字のランダムな文字列
  /// 確実に43文字以上になるように、33バイト（264ビット）を生成
  /// 33バイトをbase64urlエンコードすると、確実に44文字になる
  String _generateCodeVerifier() {
    final random = Random.secure();
    // 33バイト（264ビット）を生成
    // base64urlエンコードすると、確実に44文字以上になる
    // 33 * 8 = 264ビット、264 / 6 = 44文字
    final bytes = List<int>.generate(33, (_) => random.nextInt(256));
    final encoded = base64UrlEncode(bytes);

    // RFC 7636の要件を満たしているか確認
    if (encoded.length < 43 || encoded.length > 128) {
      throw Exception(
          'code_verifier length must be between 43 and 128, but got ${encoded.length}');
    }

    return encoded;
  }

  /// PKCE code challenge を生成
  /// code_verifier の SHA256 ハッシュを base64url エンコード（パディングなし）
  /// RFC 7636に準拠: 43文字の長さ（S256メソッド）
  String _generateCodeChallenge(String codeVerifier) {
    final bytes = utf8.encode(codeVerifier);
    final digest = sha256.convert(bytes);
    // base64urlエンコード（パディング=を削除）
    // SHA256は32バイトなので、base64urlエンコードすると43文字になる
    final base64String = base64.encode(digest.bytes);
    // base64url形式に変換（+ → -, / → _, = を削除）
    return base64String
        .replaceAll('+', '-')
        .replaceAll('/', '_')
        .replaceAll('=', '');
  }

  /// PKCE code verifier を SecureStorage に保存
  Future<void> _saveCodeVerifier(String codeVerifier) async {
    await AppConfig.savePKCECodeVerifier(codeVerifier);
  }

  /// PKCE code verifier を SecureStorage から取得
  Future<String?> _getCodeVerifier() async {
    return await AppConfig.getPKCECodeVerifier();
  }

  /// PKCE code verifier を削除
  Future<void> _deleteCodeVerifier() async {
    await AppConfig.deletePKCECodeVerifier();
  }

  /// 認可 URL を生成（PKCE対応）
  Future<Uri> generateAuthUrl() async {
    final clientId = await _getClientId();
    final state = _generateState();
    await _saveState(state);

    // PKCE code verifier と challenge を生成
    final codeVerifier = _generateCodeVerifier();
    final codeChallenge = _generateCodeChallenge(codeVerifier);
    await _saveCodeVerifier(codeVerifier);

    return Uri.https('github.com', '/login/oauth/authorize', {
      'client_id': clientId,
      'redirect_uri': _redirectUri,
      'scope': _oauthScope,
      'state': state,
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
    });
  }

  /// ブラウザで認証を開始
  Future<void> launchAuth() async {
    final authUrl = await generateAuthUrl();

    // 外部ブラウザで開く
    final launched = await launchUrl(
      authUrl,
      mode: LaunchMode.externalApplication,
    );

    if (!launched) {
      throw Exception('認証画面を開けませんでした');
    }
  }

  /// Deep Link のコールバックを処理
  ///
  /// [uri] Deep Link の URI
  /// 戻り値: 取得した access token
  Future<String> handleCallback(Uri uri) async {
    // URI の検証
    if (uri.scheme != 'github-projects-mobile' || uri.host != 'callback') {
      throw Exception('無効なリダイレクト URI です');
    }

    // エラーチェック
    final error = uri.queryParameters['error'];
    if (error != null) {
      final errorDescription = uri.queryParameters['error_description'] ?? '';
      throw Exception('認証エラー: $error - $errorDescription');
    }

    // code と state を取得
    final code = uri.queryParameters['code'];
    final state = uri.queryParameters['state'];

    if (code == null || code.isEmpty) {
      throw Exception('authorization code が取得できませんでした');
    }

    if (state == null || state.isEmpty) {
      throw Exception('state パラメータが取得できませんでした');
    }

    // state の検証（CSRF 対策）
    final savedState = await _getState();
    if (savedState == null) {
      // ログアウト後など、state が既に削除されている場合
      // 古い Deep Link の可能性があるため、エラーを表示せずに無視
      throw Exception('認証セッションが無効になりました。再度ログインしてください。');
    }
    if (state != savedState) {
      await _deleteState();
      throw Exception('state パラメータが一致しません。CSRF 攻撃の可能性があります。');
    }

    // state を削除（一度使用したら無効化）
    await _deleteState();

    // PKCE code verifier を取得
    final codeVerifier = await _getCodeVerifier();
    if (codeVerifier == null || codeVerifier.isEmpty) {
      throw Exception('PKCE code verifier が取得できませんでした');
    }

    // RFC 7636の要件を満たしているか確認
    if (codeVerifier.length < 43 || codeVerifier.length > 128) {
      throw Exception(
          'PKCE code verifier の長さが無効です: ${codeVerifier.length} (43-128文字である必要があります)');
    }

    // Token 交換
    final accessToken = await _exchangeCodeForToken(code, state, codeVerifier);

    // PKCE code verifier を削除（一度使用したら無効化）
    await _deleteCodeVerifier();

    // Token を保存
    await saveAccessToken(accessToken);

    return accessToken;
  }

  /// Authorization code を access token に交換（PKCE対応）
  Future<String> _exchangeCodeForToken(
      String code, String state, String codeVerifier) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.backendBaseUrl}/oauth/exchange'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'code': code,
          'state': state,
          'code_verifier': codeVerifier,
        }),
      );

      if (response.statusCode != 200) {
        final errorBody = response.body;
        throw Exception('Token 交換に失敗しました: ${response.statusCode} - $errorBody');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final accessToken = data['access_token'] as String?;

      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('access token が取得できませんでした');
      }

      return accessToken;
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Token 交換に失敗しました: $e');
    }
  }

  /// Access token を保存
  Future<void> saveAccessToken(String token) async {
    await AppConfig.saveOAuthAccessToken(token);
  }

  /// Access token を取得
  Future<String?> getAccessToken() async {
    return await AppConfig.getOAuthAccessToken();
  }

  /// Access token を削除
  Future<void> deleteAccessToken() async {
    await AppConfig.deleteOAuthAccessToken();
  }

  /// Access token が存在するか確認
  Future<bool> hasAccessToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Deep Link ストリームを監視
  ///
  /// アプリが起動中に Deep Link を受信した場合に使用
  Stream<Uri> watchDeepLinks() {
    final appLinks = AppLinks();
    return appLinks.uriLinkStream;
  }

  /// 初期 Deep Link を取得（アプリ起動時に Deep Link で起動された場合）
  Future<Uri?> getInitialLink() async {
    final appLinks = AppLinks();
    return await appLinks.getInitialLink();
  }

  /// すべての認証情報を削除（ログアウト用）
  Future<void> logout() async {
    await deleteAccessToken();
    await AppConfig.deleteOAuthState();
    await AppConfig.deletePKCECodeVerifier();
  }
}

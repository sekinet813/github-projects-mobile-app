/// GitHub API 関連の例外クラス
class GitHubApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? graphQLErrors;

  const GitHubApiException(
    this.message, {
    this.statusCode,
    this.graphQLErrors,
  });

  /// HTTP エラー用の例外
  factory GitHubApiException.httpError(int statusCode, String message) {
    return GitHubApiException(
      'HTTP エラー: $message',
      statusCode: statusCode,
    );
  }

  /// GraphQL エラー用の例外
  factory GitHubApiException.graphQLError(
    String message,
    Map<String, dynamic> errors,
  ) {
    return GitHubApiException(
      'GraphQL エラー: $message',
      graphQLErrors: errors,
    );
  }

  /// トークン未取得エラー用の例外
  factory GitHubApiException.tokenNotFound() {
    return const GitHubApiException(
      'アクセストークンが取得できませんでした。ログインが必要です。',
    );
  }

  /// ネットワークエラー用の例外
  factory GitHubApiException.networkError(String message) {
    return GitHubApiException('ネットワークエラー: $message');
  }

  @override
  String toString() => message;
}

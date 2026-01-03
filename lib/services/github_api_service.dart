import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

/// GitHub GraphQL API を扱うサービスクラス
class GitHubApiService {
  final String baseUrl = AppConfig.githubApiBaseUrl;
  
  /// GraphQLクエリを実行
  /// 
  /// [query] GraphQLクエリ文字列
  /// [variables] クエリ変数（オプション）
  /// 
  /// 戻り値: APIレスポンスのJSONマップ
  Future<Map<String, dynamic>> executeQuery(
    String query, {
    Map<String, dynamic>? variables,
  }) async {
    final token = await AppConfig.getAccessToken();
    
    if (token == null || token.isEmpty) {
      throw Exception('アクセストークンが設定されていません');
    }
    
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'query': query,
        if (variables != null) 'variables': variables,
      }),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(
        'APIリクエストが失敗しました: ${response.statusCode} - ${response.body}',
      );
    }
  }
  
  /// GraphQLミューテーションを実行
  /// 
  /// [mutation] GraphQLミューテーション文字列
  /// [variables] ミューテーション変数（オプション）
  /// 
  /// 戻り値: APIレスポンスのJSONマップ
  Future<Map<String, dynamic>> executeMutation(
    String mutation, {
    Map<String, dynamic>? variables,
  }) async {
    return executeQuery(mutation, variables: variables);
  }
  
  /// ダミーデータを返す（開発用）
  /// 実際の実装は次フェーズで行う
  Future<Map<String, dynamic>> getProjects() async {
    // TODO: 実際のGraphQLクエリを実装
    await Future.delayed(const Duration(milliseconds: 500));
    return {
      'data': {
        'viewer': {
          'projectsV2': {
            'nodes': [],
          },
        },
      },
    };
  }
}


import '../services/github_api_service.dart';

/// GitHub API とのやり取りを管理するリポジトリクラス
class GitHubRepository {
  final GitHubApiService _apiService;
  
  GitHubRepository({GitHubApiService? apiService})
      : _apiService = apiService ?? GitHubApiService();
  
  /// プロジェクト一覧を取得
  /// 
  /// 戻り値: プロジェクトのリスト（現在はダミー）
  Future<List<Map<String, dynamic>>> getProjects() async {
    try {
      await _apiService.getProjects();
      // TODO: 実際のレスポンスパース処理を実装
      return [];
    } catch (e) {
      throw Exception('プロジェクトの取得に失敗しました: $e');
    }
  }
  
  /// プロジェクトの詳細を取得
  /// 
  /// [projectId] プロジェクトID
  /// 
  /// 戻り値: プロジェクトの詳細情報（現在はダミー）
  Future<Map<String, dynamic>> getProjectDetails(String projectId) async {
    try {
      // TODO: 実際の実装を追加
      await Future.delayed(const Duration(milliseconds: 500));
      return {};
    } catch (e) {
      throw Exception('プロジェクト詳細の取得に失敗しました: $e');
    }
  }
}


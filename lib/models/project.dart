/// GitHub Project (Projects v2) のモデルクラス
class Project {
  /// プロジェクトID
  final String id;

  /// プロジェクトタイトル
  final String title;

  /// プロジェクトの短い説明
  final String? shortDescription;

  /// プロジェクト番号
  final int number;

  /// プロジェクトのオーナー（ユーザーまたは組織）
  final ProjectOwner owner;

  Project({
    required this.id,
    required this.title,
    this.shortDescription,
    required this.number,
    required this.owner,
  });

  /// JSONからProjectインスタンスを作成
  factory Project.fromJson(Map<String, dynamic> json) {
    if (json['id'] == null || json['id'] is! String) {
      throw const FormatException('Missing or invalid "id" field');
    }
    if (json['title'] == null || json['title'] is! String) {
      throw const FormatException('Missing or invalid "title" field');
    }
    if (json['number'] == null || json['number'] is! int) {
      throw const FormatException('Missing or invalid "number" field');
    }
    if (json['owner'] == null || json['owner'] is! Map<String, dynamic>) {
      throw const FormatException('Missing or invalid "owner" field');
    }
    return Project(
      id: json['id'] as String,
      title: json['title'] as String,
      shortDescription: json['shortDescription'] as String?,
      number: json['number'] as int,
      owner: ProjectOwner.fromJson(json['owner'] as Map<String, dynamic>),
    );
  }

  /// ProjectインスタンスをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'shortDescription': shortDescription,
      'number': number,
      'owner': owner.toJson(),
    };
  }
}

/// プロジェクトのオーナー（ユーザーまたは組織）
class ProjectOwner {
  /// オーナーのタイプ（User または Organization）
  final String type;

  /// オーナーのログイン名
  final String login;

  /// オーナーのID（取得できない場合は空文字）
  final String id;

  ProjectOwner({
    required this.type,
    required this.login,
    this.id = '',
  });

  /// JSONからProjectOwnerインスタンスを作成
  factory ProjectOwner.fromJson(Map<String, dynamic> json) {
    return ProjectOwner(
      type: json['__typename'] as String? ?? 'User',
      login: json['login'] as String? ?? '',
      id: json['id'] as String? ?? '',
    );
  }

  /// ProjectOwnerインスタンスをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      '__typename': type,
      'login': login,
      'id': id,
    };
  }

  /// ユーザーかどうか
  bool get isUser => type == 'User';

  /// 組織かどうか
  bool get isOrganization => type == 'Organization';
}

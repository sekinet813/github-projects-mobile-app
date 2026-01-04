/// GitHub Project (Projects v2) の詳細情報を表すモデルクラス
class ProjectDetail {
  /// プロジェクトID
  final String id;

  /// プロジェクトのフィールド一覧
  final List<ProjectField> fields;

  /// プロジェクトのアイテム一覧
  final List<ProjectItem> items;

  ProjectDetail({
    required this.id,
    required this.fields,
    required this.items,
  });

  /// JSONからProjectDetailインスタンスを作成
  factory ProjectDetail.fromJson(Map<String, dynamic> json) {
    if (json['id'] == null || json['id'] is! String) {
      throw const FormatException('Missing or invalid "id" field');
    }

    final fieldsJson = json['fields'] as Map<String, dynamic>?;
    final fields = <ProjectField>[];
    if (fieldsJson != null) {
      final nodes = fieldsJson['nodes'] as List<dynamic>?;
      if (nodes != null) {
        for (final node in nodes) {
          if (node != null) {
            try {
              fields.add(ProjectField.fromJson(node as Map<String, dynamic>));
            } catch (e) {
              // パースエラーは無視して続行
            }
          }
        }
      }
    }

    final itemsJson = json['items'] as Map<String, dynamic>?;
    final items = <ProjectItem>[];
    if (itemsJson != null) {
      final nodes = itemsJson['nodes'] as List<dynamic>?;
      if (nodes != null) {
        for (final node in nodes) {
          if (node != null) {
            try {
              items.add(ProjectItem.fromJson(node as Map<String, dynamic>));
            } catch (e) {
              // パースエラーは無視して続行
            }
          }
        }
      }
    }

    return ProjectDetail(
      id: json['id'] as String,
      fields: fields,
      items: items,
    );
  }

  /// ProjectDetailインスタンスをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fields': {
        'nodes': fields.map((f) => f.toJson()).toList(),
      },
      'items': {
        'nodes': items.map((i) => i.toJson()).toList(),
      },
    };
  }

  /// Statusフィールドを取得
  ProjectField? get statusField {
    try {
      return fields.firstWhere(
        (field) =>
            field.dataType == 'SINGLE_SELECT' &&
            (field.name.toLowerCase() == 'status' ||
                field.name.toLowerCase() == 'ステータス'),
      );
    } catch (e) {
      return null;
    }
  }

  /// Dateフィールドを取得
  ProjectField? get dateField {
    try {
      return fields.firstWhere(
        (field) =>
            field.dataType == 'DATE' &&
            (field.name.toLowerCase() == 'date' ||
                field.name.toLowerCase() == '日付'),
      );
    } catch (e) {
      return null;
    }
  }
}

/// プロジェクトのフィールド
class ProjectField {
  /// フィールドID
  final String id;

  /// フィールド名
  final String name;

  /// データタイプ（SINGLE_SELECT, DATE, TEXT など）
  final String dataType;

  /// オプション（Single Select フィールドの場合）
  final List<ProjectFieldOption>? options;

  ProjectField({
    required this.id,
    required this.name,
    required this.dataType,
    this.options,
  });

  /// JSONからProjectFieldインスタンスを作成
  factory ProjectField.fromJson(Map<String, dynamic> json) {
    if (json['id'] == null || json['id'] is! String) {
      throw const FormatException('Missing or invalid "id" field');
    }
    if (json['name'] == null || json['name'] is! String) {
      throw const FormatException('Missing or invalid "name" field');
    }
    if (json['dataType'] == null || json['dataType'] is! String) {
      throw const FormatException('Missing or invalid "dataType" field');
    }

    final options = <ProjectFieldOption>[];
    if (json['options'] != null) {
      final optionsJson = json['options'] as List<dynamic>?;
      if (optionsJson != null) {
        for (final optionJson in optionsJson) {
          if (optionJson != null) {
            try {
              options.add(ProjectFieldOption.fromJson(
                  optionJson as Map<String, dynamic>));
            } catch (e) {
              // パースエラーは無視して続行
            }
          }
        }
      }
    }

    return ProjectField(
      id: json['id'] as String,
      name: json['name'] as String,
      dataType: json['dataType'] as String,
      options: options.isNotEmpty ? options : null,
    );
  }

  /// ProjectFieldインスタンスをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dataType': dataType,
      if (options != null) 'options': options!.map((o) => o.toJson()).toList(),
    };
  }

  /// Single Select フィールドかどうか
  bool get isSingleSelect => dataType == 'SINGLE_SELECT';

  /// Date フィールドかどうか
  bool get isDate => dataType == 'DATE';
}

/// プロジェクトフィールドのオプション（Single Select 用）
class ProjectFieldOption {
  /// オプションID
  final String id;

  /// オプション名
  final String name;

  ProjectFieldOption({
    required this.id,
    required this.name,
  });

  /// JSONからProjectFieldOptionインスタンスを作成
  factory ProjectFieldOption.fromJson(Map<String, dynamic> json) {
    if (json['id'] == null || json['id'] is! String) {
      throw const FormatException('Missing or invalid "id" field');
    }
    if (json['name'] == null || json['name'] is! String) {
      throw const FormatException('Missing or invalid "name" field');
    }
    return ProjectFieldOption(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  /// ProjectFieldOptionインスタンスをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

/// プロジェクトのアイテム
class ProjectItem {
  /// アイテムID
  final String id;

  /// フィールド値の一覧
  final List<ProjectItemFieldValue> fieldValues;

  /// コンテンツ（Issue または Draft）
  final ProjectItemContent? content;

  ProjectItem({
    required this.id,
    required this.fieldValues,
    this.content,
  });

  /// JSONからProjectItemインスタンスを作成
  factory ProjectItem.fromJson(Map<String, dynamic> json) {
    if (json['id'] == null || json['id'] is! String) {
      throw const FormatException('Missing or invalid "id" field');
    }

    final fieldValues = <ProjectItemFieldValue>[];
    final fieldValuesJson = json['fieldValues'] as Map<String, dynamic>?;
    if (fieldValuesJson != null) {
      final nodes = fieldValuesJson['nodes'] as List<dynamic>?;
      if (nodes != null) {
        for (final node in nodes) {
          if (node != null) {
            try {
              fieldValues.add(
                  ProjectItemFieldValue.fromJson(node as Map<String, dynamic>));
            } catch (e) {
              // パースエラーは無視して続行
            }
          }
        }
      }
    }

    ProjectItemContent? content;
    final contentJson = json['content'] as Map<String, dynamic>?;
    if (contentJson != null) {
      try {
        content = ProjectItemContent.fromJson(contentJson);
      } catch (e) {
        // パースエラーは無視
      }
    }

    return ProjectItem(
      id: json['id'] as String,
      fieldValues: fieldValues,
      content: content,
    );
  }

  /// ProjectItemインスタンスをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fieldValues': {
        'nodes': fieldValues.map((fv) => fv.toJson()).toList(),
      },
      if (content != null) 'content': content!.toJson(),
    };
  }

  /// タイトルを取得
  String? get title => content?.title;

  /// Statusフィールドの値を取得
  String? getStatusValue() {
    for (final fieldValue in fieldValues) {
      final field = fieldValue.field;
      if (field != null) {
        final fieldName = field.name.toLowerCase();
        if (fieldName == 'status' || fieldName == 'ステータス') {
          return fieldValue.value;
        }
      }
    }
    return null;
  }

  /// Dateフィールドの値を取得
  String? getDateValue() {
    for (final fieldValue in fieldValues) {
      final field = fieldValue.field;
      if (field != null) {
        final fieldName = field.name.toLowerCase();
        if (fieldName == 'date' || fieldName == '日付') {
          return fieldValue.value;
        }
      }
    }
    return null;
  }
}

/// プロジェクトアイテムのフィールド値
class ProjectItemFieldValue {
  /// フィールド情報
  final ProjectField? field;

  /// 値（Single Select の場合は name、Date の場合は date）
  final String? value;

  ProjectItemFieldValue({
    this.field,
    this.value,
  });

  /// JSONからProjectItemFieldValueインスタンスを作成
  factory ProjectItemFieldValue.fromJson(Map<String, dynamic> json) {
    ProjectField? field;
    final fieldJson = json['field'] as Map<String, dynamic>?;
    if (fieldJson != null) {
      try {
        field = ProjectField.fromJson(fieldJson);
      } catch (e) {
        // パースエラーは無視
      }
    }

    String? value;
    // Single Select の場合
    if (json.containsKey('name') && json['name'] != null) {
      value = json['name'] as String?;
    }
    // Date の場合
    if (json.containsKey('date') && json['date'] != null) {
      value = json['date'] as String?;
    }

    return ProjectItemFieldValue(
      field: field,
      value: value,
    );
  }

  /// ProjectItemFieldValueインスタンスをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      if (field != null) 'field': field!.toJson(),
      if (value != null) 'value': value,
    };
  }
}

/// プロジェクトアイテムのコンテンツ（Issue または Draft）
class ProjectItemContent {
  /// タイトル
  final String? title;

  /// Issue の場合の番号
  final int? number;

  /// Issue の場合の状態（OPEN, CLOSED）
  final String? state;

  /// コンテンツタイプ（Issue または Draft）
  final String type;

  ProjectItemContent({
    this.title,
    this.number,
    this.state,
    required this.type,
  });

  /// JSONからProjectItemContentインスタンスを作成
  factory ProjectItemContent.fromJson(Map<String, dynamic> json) {
    // Issue の場合
    if (json.containsKey('number') || json.containsKey('state')) {
      return ProjectItemContent(
        title: json['title'] as String?,
        number: json['number'] as int?,
        state: json['state'] as String?,
        type: 'Issue',
      );
    }

    // Draft の場合（将来の拡張用）
    return ProjectItemContent(
      title: json['title'] as String?,
      type: 'Draft',
    );
  }

  /// ProjectItemContentインスタンスをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      if (title != null) 'title': title,
      if (number != null) 'number': number,
      if (state != null) 'state': state,
      'type': type,
    };
  }

  /// Issue かどうか
  bool get isIssue => type == 'Issue';

  /// Draft かどうか
  bool get isDraft => type == 'Draft';
}

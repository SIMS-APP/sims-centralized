class AppSetting {
  final String id;
  final String key;
  final dynamic value;
  final String? description;
  final DateTime updatedAt;

  AppSetting({
    required this.id,
    required this.key,
    required this.value,
    this.description,
    required this.updatedAt,
  });

  factory AppSetting.fromJson(Map<String, dynamic> json) {
    return AppSetting(
      id: json['id'] as String,
      key: json['key'] as String,
      value: json['value'],
      description: json['description'] as String?,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  String get stringValue {
    if (value is String) return value;
    return value.toString().replaceAll('"', '');
  }

  int get intValue => int.tryParse(stringValue) ?? 0;
  bool get boolValue => stringValue.toLowerCase() == 'true';
}

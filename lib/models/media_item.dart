class MediaItem {
  final String id;
  final String title;
  final String? description;
  final String type; // 'image' or 'video'
  final String url;
  final String bucketPath;
  final String? thumbnailUrl;
  final int durationSeconds;
  final int? fileSizeBytes;
  final String? mimeType;
  final bool isActive;
  final int displayOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  MediaItem({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    required this.url,
    required this.bucketPath,
    this.thumbnailUrl,
    this.durationSeconds = 10,
    this.fileSizeBytes,
    this.mimeType,
    this.isActive = true,
    this.displayOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isVideo => type == 'video';
  bool get isImage => type == 'image';

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      type: json['type'] as String,
      url: json['url'] as String,
      bucketPath: json['bucket_path'] as String? ?? '',
      thumbnailUrl: json['thumbnail_url'] as String?,
      durationSeconds: json['duration_seconds'] as int? ?? 10,
      fileSizeBytes: json['file_size_bytes'] as int?,
      mimeType: json['mime_type'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      displayOrder: json['display_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'url': url,
      'bucket_path': bucketPath,
      'thumbnail_url': thumbnailUrl,
      'duration_seconds': durationSeconds,
      'file_size_bytes': fileSizeBytes,
      'mime_type': mimeType,
      'is_active': isActive,
      'display_order': displayOrder,
    };
  }

  MediaItem copyWith({
    String? title,
    String? description,
    String? type,
    String? url,
    String? bucketPath,
    String? thumbnailUrl,
    int? durationSeconds,
    bool? isActive,
    int? displayOrder,
  }) {
    return MediaItem(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      url: url ?? this.url,
      bucketPath: bucketPath ?? this.bucketPath,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      fileSizeBytes: fileSizeBytes,
      mimeType: mimeType,
      isActive: isActive ?? this.isActive,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

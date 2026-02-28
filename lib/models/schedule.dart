class Schedule {
  final String id;
  final String mediaId;
  final String? name;
  final String startTime; // HH:mm format
  final String endTime;   // HH:mm format
  final List<int> daysOfWeek; // 0=Sun, 1=Mon, ...6=Sat
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Schedule({
    required this.id,
    required this.mediaId,
    this.name,
    required this.startTime,
    required this.endTime,
    this.daysOfWeek = const [0, 1, 2, 3, 4, 5, 6],
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'] as String,
      mediaId: json['media_id'] as String,
      name: json['name'] as String?,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      daysOfWeek: (json['days_of_week'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [0, 1, 2, 3, 4, 5, 6],
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'media_id': mediaId,
      'name': name,
      'start_time': startTime,
      'end_time': endTime,
      'days_of_week': daysOfWeek,
      'is_active': isActive,
    };
  }

  bool isActiveNow() {
    final now = DateTime.now();
    final currentDay = now.weekday % 7; // Convert to 0=Sun format
    if (!daysOfWeek.contains(currentDay)) return false;

    final nowMinutes = now.hour * 60 + now.minute;
    final startParts = startTime.split(':');
    final endParts = endTime.split(':');
    final startMinutes =
        int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

    return nowMinutes >= startMinutes && nowMinutes <= endMinutes;
  }
}

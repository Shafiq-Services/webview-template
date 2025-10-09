class NotificationModel {
  final String title;
  final String description;
  final DateTime receivedTime;

  NotificationModel({
    required this.title,
    required this.description,
    required this.receivedTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'receivedTime': receivedTime.toIso8601String(),
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      title: json['title'] ?? 'No Title',
      description: json['description'] ?? 'No Description',
      receivedTime: DateTime.parse(json['receivedTime'] ?? DateTime.now().toIso8601String()),
    );
  }
} 
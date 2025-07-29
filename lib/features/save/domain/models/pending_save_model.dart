class PendingSaveModel {
  final String id;
  final String url;
  final String? title;
  final String? text;
  final String? images; // Serialized list of images as JSON
  final String sourcePlatform;
  final String status; // pending, processing, completed, failed
  final String? errorMessage;
  final int retryCount;
  final DateTime createdAt;
  final DateTime? processedAt;

  PendingSaveModel({
    required this.id,
    required this.url,
    this.title,
    this.text,
    this.images,
    required this.sourcePlatform,
    required this.status,
    this.errorMessage,
    required this.retryCount,
    required this.createdAt,
    this.processedAt,
  });

  PendingSaveModel copyWith({
    String? id,
    String? url,
    String? title,
    String? text,
    String? images,
    String? sourcePlatform,
    String? status,
    String? errorMessage,
    int? retryCount,
    DateTime? createdAt,
    DateTime? processedAt,
  }) {
    return PendingSaveModel(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      text: text ?? this.text,
      images: images ?? this.images,
      sourcePlatform: sourcePlatform ?? this.sourcePlatform,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      retryCount: retryCount ?? this.retryCount,
      createdAt: createdAt ?? this.createdAt,
      processedAt: processedAt ?? this.processedAt,
    );
  }
}
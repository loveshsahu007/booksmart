class UserDocument {
  final int id;
  final String userId;
  final String name;
  final String fileUrl;
  final String? category;
  final String? taxYear;
  final int? fileSize; // bytes
  final String? mimeType;
  final DateTime createdAt;

  const UserDocument({
    required this.id,
    required this.userId,
    required this.name,
    required this.fileUrl,
    this.category,
    this.taxYear,
    this.fileSize,
    this.mimeType,
    required this.createdAt,
  });

  factory UserDocument.fromJson(Map<String, dynamic> json) {
    return UserDocument(
      id: json['id'] as int,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      fileUrl: json['file_url'] as String,
      category: json['category'] as String?,
      taxYear: json['tax_year'] as String?,
      fileSize: json['file_size'] as int?,
      mimeType: json['mime_type'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'name': name,
    'file_url': fileUrl,
    if (category != null) 'category': category,
    if (taxYear != null) 'tax_year': taxYear,
    if (fileSize != null) 'file_size': fileSize,
    if (mimeType != null) 'mime_type': mimeType,
  };

  /// Human-readable file size (e.g. "2.34 MB").
  String get fileSizeLabel {
    if (fileSize == null) return '';
    final kb = fileSize! / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(2)} MB';
  }
}

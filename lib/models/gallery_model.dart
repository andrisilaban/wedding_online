class GalleryModel {
  final int? id;
  final int? invitationId;
  final String? type;
  final String? filePath;
  final String? caption;
  final int? orderNumber;
  final String? deleteUrl; // Add this field to store ImgBB delete URL
  final DateTime? createdAt;
  final DateTime? updatedAt;

  GalleryModel({
    this.id,
    this.invitationId,
    this.type,
    this.filePath,
    this.caption,
    this.orderNumber,
    this.deleteUrl, // Add this parameter
    this.createdAt,
    this.updatedAt,
  });

  factory GalleryModel.fromJson(Map<String, dynamic> json) {
    return GalleryModel(
      id: _parseIntSafely(json['id']),
      invitationId: _parseIntSafely(json['invitation_id']),
      type: json['type']?.toString(),
      filePath: json['file_path']?.toString(),
      caption: json['caption']?.toString(),
      orderNumber: _parseIntSafely(json['order_number']),
      deleteUrl: json['delete_url']?.toString(), // Add this line
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  // Helper method to safely parse int values
  static int? _parseIntSafely(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invitation_id': invitationId,
      'type': type,
      'file_path': filePath,
      'caption': caption,
      'order_number': orderNumber,
      'delete_url': deleteUrl, // Add this line
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  GalleryModel copyWith({
    int? id,
    int? invitationId,
    String? type,
    String? filePath,
    String? caption,
    int? orderNumber,
    String? deleteUrl, // Add this parameter
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GalleryModel(
      id: id ?? this.id,
      invitationId: invitationId ?? this.invitationId,
      type: type ?? this.type,
      filePath: filePath ?? this.filePath,
      caption: caption ?? this.caption,
      orderNumber: orderNumber ?? this.orderNumber,
      deleteUrl: deleteUrl ?? this.deleteUrl, // Add this line
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Model untuk response ImgBB
class ImgBBResponse {
  final ImgBBData? data;
  final bool success;
  final int status;

  ImgBBResponse({this.data, required this.success, required this.status});

  factory ImgBBResponse.fromJson(Map<String, dynamic> json) {
    return ImgBBResponse(
      data: json['data'] != null ? ImgBBData.fromJson(json['data']) : null,
      success: json['success'] ?? false,
      status: json['status'] ?? 0,
    );
  }
}

class ImgBBData {
  final String? id;
  final String? title;
  final String? url;
  final String? urlViewer;

  final String? displayUrl;
  final String? deleteUrl;
  final ImgBBImage? image;
  final ImgBBImage? thumb;
  final ImgBBImage? medium;

  ImgBBData({
    this.id,
    this.title,
    this.url,
    this.urlViewer,
    this.displayUrl,
    this.deleteUrl,
    this.image,
    this.thumb,
    this.medium,
  });

  factory ImgBBData.fromJson(Map<String, dynamic> json) {
    return ImgBBData(
      id: json['id'],
      title: json['title'],
      url: json['url'],
      urlViewer: json['url_viewer'],
      displayUrl: json['display_url'],
      deleteUrl: json['delete_url'],
      image: json['image'] != null ? ImgBBImage.fromJson(json['image']) : null,
      thumb: json['thumb'] != null ? ImgBBImage.fromJson(json['thumb']) : null,
      medium: json['medium'] != null
          ? ImgBBImage.fromJson(json['medium'])
          : null,
    );
  }
}

class ImgBBImage {
  final String? filename;
  final String? name;
  final String? mime;
  final String? extension;
  final String? url;

  ImgBBImage({this.filename, this.name, this.mime, this.extension, this.url});

  factory ImgBBImage.fromJson(Map<String, dynamic> json) {
    return ImgBBImage(
      filename: json['filename'],
      name: json['name'],
      mime: json['mime'],
      extension: json['extension'],
      url: json['url'],
    );
  }
}

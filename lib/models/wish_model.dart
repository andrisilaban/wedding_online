class WishModel {
  final int? id;
  final int? invitationId;
  final int? guestId;
  final String? guestName;
  final String? attendanceStatus;
  final String? message;
  final bool? isDisplayed;
  final String? createdAt;
  final String? updatedAt;

  WishModel({
    this.id,
    this.invitationId,
    this.guestId,
    this.guestName,
    this.attendanceStatus,
    this.message,
    this.isDisplayed,
    this.createdAt,
    this.updatedAt,
  });

  factory WishModel.fromJson(Map<String, dynamic> json) {
    return WishModel(
      id: _parseIntSafely(json['id']),
      invitationId: _parseIntSafely(json['invitation_id']),
      guestId: _parseIntSafely(json['guest_id']),
      guestName: json['guest_name']?.toString(),
      attendanceStatus: json['attendance_status']?.toString(),
      message: json['message']?.toString(),
      isDisplayed: _parseBoolSafely(json['is_displayed']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  // Helper method untuk parsing int dengan aman
  static int? _parseIntSafely(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  // Helper method untuk parsing bool dengan aman
  static bool? _parseBoolSafely(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value.toLowerCase() == 't';
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invitation_id': invitationId,
      'guest_id': guestId,
      'guest_name': guestName,
      'attendance_status': attendanceStatus,
      'message': message,
      'is_displayed': isDisplayed,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  // Helper method to get formatted attendance status
  String get formattedAttendanceStatus {
    switch (attendanceStatus?.toLowerCase()) {
      case 'hadir':
        return 'Hadir';
      case 'tidak_hadir':
        return 'Tidak Hadir';
      case 'mungkin':
        return 'Mungkin';
      default:
        return 'Belum Konfirmasi';
    }
  }

  // Helper method to get attendance color
  String get attendanceColorType {
    switch (attendanceStatus?.toLowerCase()) {
      case 'hadir':
        return 'success';
      case 'tidak_hadir':
        return 'danger';
      case 'mungkin':
        return 'warning';
      default:
        return 'secondary';
    }
  }

  // Create a copy with updated values
  WishModel copyWith({
    int? id,
    int? invitationId,
    int? guestId,
    String? guestName,
    String? attendanceStatus,
    String? message,
    bool? isDisplayed,
    String? createdAt,
    String? updatedAt,
  }) {
    return WishModel(
      id: id ?? this.id,
      invitationId: invitationId ?? this.invitationId,
      guestId: guestId ?? this.guestId,
      guestName: guestName ?? this.guestName,
      attendanceStatus: attendanceStatus ?? this.attendanceStatus,
      message: message ?? this.message,
      isDisplayed: isDisplayed ?? this.isDisplayed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'WishModel(id: $id, guestName: $guestName, attendanceStatus: $attendanceStatus, message: $message)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WishModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

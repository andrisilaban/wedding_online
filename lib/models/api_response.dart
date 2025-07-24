class ApiResponse<T> {
  final int? status;
  final String? message;
  final Map<String, dynamic>? errors;
  final T? data;

  ApiResponse({this.status, this.message, this.errors, this.data});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json, {
    T Function(Map<String, dynamic>)? fromJsonData,
  }) {
    final hasData = json.containsKey('user') || json.containsKey('token');
    return ApiResponse(
      status: json['status'],
      message: json['message'],
      errors: json['errors'],
      data: hasData && fromJsonData != null
          ? fromJsonData({
              ...?json['user'],
              if (json.containsKey('token')) 'token': json['token'],
            })
          : null,
    );
  }
}

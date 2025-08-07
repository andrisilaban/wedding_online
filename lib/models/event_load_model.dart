class EventLoadModel {
  final String? id;
  final String? invitationId;
  final String? name;
  final String? venueName;
  final String? venueAddress;
  final String? date;
  final String? startTime;
  final String? endTime;
  final String? description;
  final String? orderNumber;

  EventLoadModel({
    this.id,
    this.invitationId,
    this.name,
    this.venueName,
    this.venueAddress,
    this.date,
    this.startTime,
    this.endTime,
    this.description,
    this.orderNumber,
  });

  factory EventLoadModel.fromJson(Map<String, dynamic> json) {
    return EventLoadModel(
      id: json['id'],
      invitationId: json['invitation_id'],
      name: json['name'],
      venueName: json['venue_name'],
      venueAddress: json['venue_address'],
      date: json['date'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      description: json['description'],
      orderNumber: json['order_number'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invitation_id': invitationId,
      'name': name,
      'venue_name': venueName,
      'venue_address': venueAddress,
      'date': date,
      'start_time': startTime,
      'end_time': endTime,
      'description': description,
      'order_number': orderNumber,
    };
  }
}

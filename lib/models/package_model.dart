class PackageModel {
  final String? id;
  final String? name;
  final String? description;
  final String? maxGuests;
  final String? validityPeriod;
  final String? price;
  final String? isActive;
  final String? createdAt;
  final String? updatedAt;

  PackageModel({
    this.id,
    this.name,
    this.description,
    this.maxGuests,
    this.validityPeriod,
    this.price,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory PackageModel.fromJson(Map<String, dynamic> json) {
    return PackageModel(
      id: json['id']?.toString(),
      name: json['name']?.toString(),
      description: json['description']?.toString(),
      maxGuests: json['max_guests']?.toString(),
      validityPeriod: json['validity_period']?.toString(),
      price: json['price']?.toString(),
      isActive: json['is_active']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'max_guests': maxGuests,
      'validity_period': validityPeriod,
      'price': price,
      'is_active': isActive,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  // Helper methods
  bool get isActivePackage =>
      isActive?.toLowerCase() == 't' || isActive?.toLowerCase() == 'true';

  double get priceAsDouble {
    try {
      return double.parse(price ?? '0');
    } catch (e) {
      return 0.0;
    }
  }

  int get maxGuestsAsInt {
    try {
      final guests = int.parse(maxGuests ?? '0');
      return guests == 0 ? -1 : guests; // -1 means unlimited
    } catch (e) {
      return 0;
    }
  }

  int get validityPeriodAsInt {
    try {
      return int.parse(validityPeriod ?? '30');
    } catch (e) {
      return 30;
    }
  }

  String get formattedPrice {
    try {
      final price = priceAsDouble;
      if (price >= 1000000) {
        return 'Rp ${(price / 1000000).toStringAsFixed(0)}jt';
      } else if (price >= 1000) {
        return 'Rp ${(price / 1000).toStringAsFixed(0)}rb';
      } else {
        return 'Rp ${price.toStringAsFixed(0)}';
      }
    } catch (e) {
      return 'Rp 0';
    }
  }

  String get guestsDisplay {
    final guests = maxGuestsAsInt;
    if (guests == -1) {
      return 'Unlimited';
    } else {
      return '$guests tamu';
    }
  }

  String get validityDisplay {
    final days = validityPeriodAsInt;
    if (days >= 30) {
      final months = (days / 30).floor();
      return '$months bulan';
    } else {
      return '$days hari';
    }
  }
}

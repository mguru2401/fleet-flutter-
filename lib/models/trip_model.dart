class Trip {
  final String? id;
  final String pickUpDate;
  final String pickUpTime;
  final double startKm;
  final double endKm;
  final String dropLocation;
  final double mileage;
  final double tripRate;
  final String category;
  final String? driverId;

  Trip({
    this.id,
    required this.pickUpDate,
    required this.pickUpTime,
    required this.startKm,
    required this.endKm,
    required this.dropLocation,
    required this.mileage,
    required this.tripRate,
    required this.category,
    this.driverId,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      pickUpDate: json['pick_up_date'] ?? '',
      pickUpTime: json['pick_up_time'] ?? '',
      startKm: (json['start_km'] ?? 0).toDouble(),
      endKm: (json['end_km'] ?? 0).toDouble(),
      dropLocation: json['drop_location'] ?? '',
      mileage: (json['mileage'] ?? 0).toDouble(),
      tripRate: (json['trip_rate'] ?? 0).toDouble(),
      category: json['category'] ?? '',
      driverId: json['driver_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pick_up_date': pickUpDate,
      'pick_up_time': pickUpTime,
      'start_km': startKm,
      'end_km': endKm,
      'drop_location': dropLocation,
      'mileage': mileage,
      'trip_rate': tripRate,
      'category': category,
    };
  }
}

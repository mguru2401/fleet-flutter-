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
  final String? carId;
  final double? commission;
  final double? netAmount;

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
    this.carId,
    this.commission,
    this.netAmount,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    final tripRate = (json['trip_rate'] ?? 0).toDouble();
    final commission = json['commission'] != null ? (json['commission'] as num).toDouble() : (json['commission_amount'] != null ? (json['commission_amount'] as num).toDouble() : null);
    final netAmount = json['net_amount'] != null ? (json['net_amount'] as num).toDouble() : (tripRate - (commission ?? 0));

    return Trip(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      pickUpDate: json['pick_up_date'] ?? '',
      pickUpTime: json['pick_up_time'] ?? '',
      startKm: (json['start_km'] ?? 0).toDouble(),
      endKm: (json['end_km'] ?? 0).toDouble(),
      dropLocation: json['drop_location'] ?? '',
      mileage: (json['mileage'] ?? 0).toDouble(),
      tripRate: tripRate,
      category: json['category'] ?? '',
      driverId: json['driver_id']?.toString(),
      carId: json['car_id']?.toString(),
      commission: commission,
      netAmount: netAmount,
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
      'car_id': carId,
      if (commission != null) 'commission': commission,
      if (netAmount != null) 'net_amount': netAmount,
    };
  }
}

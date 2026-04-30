class Advance {
  final String? id;
  final String driverId;
  final String? driverName;
  final String? carNo;
  final double amount;
  final String date;
  final String description;
  final String status;
  final String? createdAt;

  Advance({
    this.id,
    required this.driverId,
    this.driverName,
    this.carNo,
    required this.amount,
    required this.date,
    required this.description,
    this.status = 'unpaid',
    this.createdAt,
  });

  factory Advance.fromJson(Map<String, dynamic> json) {
    return Advance(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      driverId: json['driver_id']?.toString() ?? '',
      driverName: json['driver_name']?.toString(),
      carNo: json['car_no']?.toString(),
      amount: (json['amount'] ?? 0).toDouble(),
      date: json['date'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'unpaid',
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'driver_id': driverId,
      'amount': amount,
      'date': date,
      'description': description,
    };
  }
}

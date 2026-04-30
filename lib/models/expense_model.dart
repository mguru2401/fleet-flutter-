class Expense {
  final String? id;
  final String? driverId;
  final String? carNo;
  final String? driverName;
  final String date;
  final String reason;
  final String description;
  final double amount;
  final String status;
  final String? createdAt;

  Expense({
    this.id,
    this.driverId,
    this.carNo,
    this.driverName,
    required this.date,
    required this.reason,
    required this.description,
    required this.amount,
    this.status = 'pending',
    this.createdAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      driverId: json['driver_id']?.toString(),
      carNo: json['car_no']?.toString(),
      driverName: json['driver_name']?.toString(),
      date: json['date'] ?? '',
      reason: json['reason'] ?? '',
      description: json['description'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'reason': reason,
      'description': description,
      'amount': amount,
    };
  }
}

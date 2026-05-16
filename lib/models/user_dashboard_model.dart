import 'dart:convert';

class UserDashboardModel {
  final bool success;
  final UserDashboardData? data;

  UserDashboardModel({required this.success, this.data});

  factory UserDashboardModel.fromJson(Map<String, dynamic> json) {
    return UserDashboardModel(
      success: json['success'] ?? false,
      data: json['data'] != null ? UserDashboardData.fromJson(json['data']) : null,
    );
  }
}

class UserDashboardData {
  final int month;
  final int year;
  final double desiredSalary;
  final double soFarSalary;
  final double remainingToGoal;
  final double achievementPercentage;
  final double todaySalary;
  final double todayRevenue;
  final double todayTarget;
  final double targetRevenuePerDay;
  final double revenueVsTargetDiff;
  final SalaryDetails salaryDetails;
  final List<Trip> todayTrips;

  UserDashboardData({
    required this.month,
    required this.year,
    required this.desiredSalary,
    required this.soFarSalary,
    required this.remainingToGoal,
    required this.achievementPercentage,
    required this.todaySalary,
    required this.todayRevenue,
    required this.todayTarget,
    required this.targetRevenuePerDay,
    required this.revenueVsTargetDiff,
    required this.salaryDetails,
    required this.todayTrips,
  });

  factory UserDashboardData.fromJson(Map<String, dynamic> json) {
    final todayTarget = (json['today_target'] ?? (json['revenue_target_per_day'] ?? 0)).toDouble();
    final todayRevenue = (json['today_revenue'] ?? 0).toDouble();
    return UserDashboardData(
      month: json['month'] ?? 0,
      year: json['year'] ?? 0,
      desiredSalary: (json['desired_salary'] ?? 0).toDouble(),
      soFarSalary: (json['so_far_salary'] ?? 0).toDouble(),
      remainingToGoal: (json['remaining_to_goal'] ?? 0).toDouble(),
      achievementPercentage: (json['achievement_percentage'] ?? 0).toDouble(),
      todaySalary: (json['today_salary'] ?? 0).toDouble(),
      todayRevenue: todayRevenue,
      todayTarget: todayTarget,
      targetRevenuePerDay: (json['revenue_target_per_day'] ?? 0).toDouble(),
      revenueVsTargetDiff: (todayRevenue - todayTarget),
      salaryDetails: SalaryDetails.fromJson(json['salary_details'] ?? {}),
      todayTrips: (json['today_trips'] as List? ?? [])
          .map((i) => Trip.fromJson(i))
          .toList(),
    );
  }
}

class SalaryDetails {
  final double baseSalary;
  final double incentiveSalary;
  final double eligibleAmount;
  final double totalTodaySalary;

  SalaryDetails({
    required this.baseSalary,
    required this.incentiveSalary,
    required this.eligibleAmount,
    required this.totalTodaySalary,
  });

  factory SalaryDetails.fromJson(Map<String, dynamic> json) {
    return SalaryDetails(
      baseSalary: (json['base_salary'] ?? 0).toDouble(),
      incentiveSalary: (json['incentive_salary'] ?? 0).toDouble(),
      eligibleAmount: (json['eligible_amount'] ?? 0).toDouble(),
      totalTodaySalary: (json['total_earned_salary'] ?? (json['total_today_salary'] ?? 0)).toDouble(),
    );
  }
}

class Trip {
  final String id;
  final String driverId;
  final String carNo;
  final String driverName;
  final String pickUpDate;
  final String pickUpTime;
  final double startKm;
  final double endKm;
  final String dropLocation;
  final double mileage;
  final double tripRate;
  final String category;
  final String status;
  final String createdAt;
  final double netAmount;

  Trip({
    required this.id,
    required this.driverId,
    required this.carNo,
    required this.driverName,
    required this.pickUpDate,
    required this.pickUpTime,
    required this.startKm,
    required this.endKm,
    required this.dropLocation,
    required this.mileage,
    required this.tripRate,
    required this.category,
    required this.status,
    required this.createdAt,
    required this.netAmount,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] ?? '',
      driverId: json['driver_id'] ?? '',
      carNo: json['car_no'] ?? '',
      driverName: json['driver_name'] ?? '',
      pickUpDate: json['pick_up_date'] ?? '',
      pickUpTime: json['pick_up_time'] ?? '',
      startKm: (json['start_km'] ?? 0).toDouble(),
      endKm: (json['end_km'] ?? 0).toDouble(),
      dropLocation: json['drop_location'] ?? '',
      mileage: (json['mileage'] ?? 0).toDouble(),
      tripRate: (json['trip_rate'] ?? 0).toDouble(),
      category: json['category'] ?? '',
      status: json['status'] ?? '',
      createdAt: json['created_at'] ?? '',
      netAmount: (json['net_amount'] ?? 0).toDouble(),
    );
  }
}

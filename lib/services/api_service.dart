import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8000/api';
  static const String authBaseUrl = '$baseUrl/auth';
  static const String tripsBaseUrl = '$baseUrl/trips';
  static const String expensesBaseUrl = '$baseUrl/expenses';
  static const String carsBaseUrl = '$baseUrl/cars';
  static const String categoriesBaseUrl = '$baseUrl/categories';
  static const String advancesBaseUrl = '$baseUrl/advances';
  static const String salaryBaseUrl = '$baseUrl/salary';
  static const String dashboardBaseUrl = '$baseUrl/dashboard';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Helper for headers
  static Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Login
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$authBaseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // Logout
  static Future<Map<String, dynamic>> logout() async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$authBaseUrl/logout'),
        headers: headers,
      );
      await clearSession();
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Logout error: $e'};
    }
  }

  // Profile
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$authBaseUrl/profile'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error fetching profile: $e'};
    }
  }

  // Users CRUD
  static Future<Map<String, dynamic>> getUsers() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$authBaseUrl/users'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error fetching users: $e'};
    }
  }

  static Future<Map<String, dynamic>> createUser(Map<String, dynamic> userData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$authBaseUrl/users'),
        headers: headers,
        body: jsonEncode(userData),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error creating user: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateUser(String userId, Map<String, dynamic> userData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$authBaseUrl/users/$userId'),
        headers: headers,
        body: jsonEncode(userData),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error updating user: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteUser(String userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$authBaseUrl/users/$userId'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error deleting user: $e'};
    }
  }

  // Trips CRUD
  static Future<Map<String, dynamic>> getTrips({
    String? category, 
    int? month, 
    int? year,
    String? searchTerm,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final headers = await _getHeaders();
      Map<String, String> queryParams = {};
      if (category != null && category != 'all') queryParams['category'] = category;
      if (month != null) queryParams['month'] = month.toString();
      if (year != null) queryParams['year'] = year.toString();
      if (searchTerm != null && searchTerm.isNotEmpty) queryParams['search'] = searchTerm;
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;

      final uri = Uri.parse(tripsBaseUrl).replace(queryParameters: queryParams);
      
      final response = await http.get(uri, headers: headers);
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error fetching trips: $e'};
    }
  }

  static Future<Map<String, dynamic>> getTripById(String tripId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$tripsBaseUrl/$tripId'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error fetching trip: $e'};
    }
  }

  static Future<Map<String, dynamic>> getTripsByDriver(
    String driverId, {
    String? category, 
    int? month, 
    int? year,
    String? searchTerm,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final headers = await _getHeaders();
      Map<String, String> queryParams = {'driver_id': driverId};
      if (category != null && category != 'all') queryParams['category'] = category;
      if (month != null) queryParams['month'] = month.toString();
      if (year != null) queryParams['year'] = year.toString();
      if (searchTerm != null && searchTerm.isNotEmpty) queryParams['search'] = searchTerm;
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;

      final uri = Uri.parse('$tripsBaseUrl/driver/$driverId').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error fetching driver trips: $e'};
    }
  }

  static Future<Map<String, dynamic>> createTrip(Map<String, dynamic> tripData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(tripsBaseUrl),
        headers: headers,
        body: jsonEncode(tripData),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error creating trip: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateTrip(String tripId, Map<String, dynamic> tripData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$tripsBaseUrl/$tripId'),
        headers: headers,
        body: jsonEncode(tripData),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error updating trip: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteTrip(String tripId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$tripsBaseUrl/$tripId'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error deleting trip: $e'};
    }
  }

  // Expenses CRUD
  static Future<Map<String, dynamic>> getExpenses({String? status, String? driverId}) async {
    try {
      final headers = await _getHeaders();
      Map<String, String> queryParams = {};
      if (status != null && status != 'all') queryParams['status'] = status;
      if (driverId != null) queryParams['driver_id'] = driverId;

      final uri = Uri.parse(expensesBaseUrl).replace(queryParameters: queryParams);
      
      final response = await http.get(uri, headers: headers);
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error fetching expenses: $e'};
    }
  }

  static Future<Map<String, dynamic>> createExpense(Map<String, dynamic> expenseData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(expensesBaseUrl),
        headers: headers,
        body: jsonEncode(expenseData),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error creating expense: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateExpense(String expenseId, Map<String, dynamic> expenseData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$expensesBaseUrl/$expenseId'),
        headers: headers,
        body: jsonEncode(expenseData),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error updating expense: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteExpense(String expenseId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$expensesBaseUrl/$expenseId'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error deleting expense: $e'};
    }
  }

  // Statistics
  static Future<Map<String, dynamic>> getRevenueStats() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$tripsBaseUrl/stats/revenue'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error fetching revenue stats: $e'};
    }
  }

  static Future<Map<String, dynamic>> getExpenseBreakdown({int? month, int? year}) async {
    try {
      final headers = await _getHeaders();
      Map<String, String> queryParams = {};
      if (month != null) queryParams['month'] = month.toString();
      if (year != null) queryParams['year'] = year.toString();

      final uri = Uri.parse('$expensesBaseUrl/stats/breakdown').replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: headers);
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error fetching expense breakdown: $e'};
    }
  }

  // Salary Advances CRUD
  static Future<Map<String, dynamic>> getAdvances() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(advancesBaseUrl),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error fetching advances: $e'};
    }
  }

  static Future<Map<String, dynamic>> createAdvance(Map<String, dynamic> advanceData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(advancesBaseUrl),
        headers: headers,
        body: jsonEncode(advanceData),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error creating advance: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateAdvance(String advanceId, Map<String, dynamic> advanceData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$advancesBaseUrl/$advanceId'),
        headers: headers,
        body: jsonEncode(advanceData),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error updating advance: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateAdvanceStatus(String advanceId, String status) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$advancesBaseUrl/$advanceId'),
        headers: headers,
        body: jsonEncode({'status': status}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error updating advance status: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteAdvance(String advanceId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$advancesBaseUrl/$advanceId'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error deleting advance: $e'};
    }
  }

  // Cars CRUD
  static Future<Map<String, dynamic>> getCars() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(carsBaseUrl),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error fetching cars: $e'};
    }
  }

  static Future<Map<String, dynamic>> createCar(Map<String, dynamic> carData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(carsBaseUrl),
        headers: headers,
        body: jsonEncode(carData),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error creating car: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateCar(String carId, Map<String, dynamic> carData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$carsBaseUrl/$carId'),
        headers: headers,
        body: jsonEncode(carData),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error updating car: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteCar(String carId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$carsBaseUrl/$carId'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error deleting car: $e'};
    }
  }

  // Categories CRUD
  static Future<Map<String, dynamic>> getCategories() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(categoriesBaseUrl),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error fetching categories: $e'};
    }
  }

  static Future<Map<String, dynamic>> createCategory(Map<String, dynamic> data) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(categoriesBaseUrl),
        headers: headers,
        body: jsonEncode(data),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error creating category: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateCategory(String id, Map<String, dynamic> data) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$categoriesBaseUrl/$id'),
        headers: headers,
        body: jsonEncode(data),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error updating category: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteCategory(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$categoriesBaseUrl/$id'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error deleting category: $e'};
    }
  }

  // Salary
  static Future<Map<String, dynamic>> setDesiredSalary(double desiredSalary) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$salaryBaseUrl/set-desired-salary'),
        headers: headers,
        body: jsonEncode({'desired_salary': desiredSalary}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error setting desired salary: $e'};
    }
  }

  static Future<Map<String, dynamic>> getGoalStatus({int? month, int? year}) async {
    try {
      final headers = await _getHeaders();
      Map<String, String> queryParams = {};
      if (month != null) queryParams['month'] = month.toString();
      if (year != null) queryParams['year'] = year.toString();

      final uri = Uri.parse('$salaryBaseUrl/goal-status').replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: headers);
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error fetching goal status: $e'};
    }
  }

  // User Dashboard
  static Future<Map<String, dynamic>> getUserDashboard() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$dashboardBaseUrl/user'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error fetching dashboard: $e'};
    }
  }

  // Admin Dashboard
  static Future<Map<String, dynamic>> getAdminDashboard({int? month, int? year, String? search}) async {
    try {
      final headers = await _getHeaders();
      Map<String, String> queryParams = {};
      if (month != null) queryParams['month'] = month.toString();
      if (year != null) queryParams['year'] = year.toString();
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final uri = Uri.parse('$dashboardBaseUrl/admin').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error fetching admin dashboard: $e'};
    }
  }

  static Future<Map<String, dynamic>> getAdminSalaryDashboard({int? month, int? year}) async {
    try {
      final headers = await _getHeaders();
      Map<String, String> queryParams = {};
      if (month != null) queryParams['month'] = month.toString();
      if (year != null) queryParams['year'] = year.toString();

      final uri = Uri.parse('$dashboardBaseUrl/admin/salary').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error fetching admin salary dashboard: $e'};
    }
  }

  // User Salary Dashboard
  static Future<Map<String, dynamic>> getUserSalaryDashboard({int? month, int? year}) async {
    try {
      final headers = await _getHeaders();
      Map<String, String> queryParams = {};
      if (month != null) queryParams['month'] = month.toString();
      if (year != null) queryParams['year'] = year.toString();

      final uri = Uri.parse('$dashboardBaseUrl/user/salary').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error fetching user salary dashboard: $e'};
    }
  }

  static Future<Map<String, dynamic>> settleSalary(Map<String, dynamic> payload) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/salary/settle'),
        headers: headers,
        body: jsonEncode(payload),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error settling salary: $e'};
    }
  }
}

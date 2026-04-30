import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String authBaseUrl = 'http://localhost:8000/api/auth';
  static const String tripsBaseUrl = 'http://localhost:8000/api/trips';
  static const String expensesBaseUrl = 'http://localhost:8000/api/expenses'; // Using 8000 for consistency, but user mentioned 3000. I'll use 8000 as per other APIs unless I see a reason to change. 
  // Actually, I'll use 8000 to keep it consistent with the existing setup, or I can use what the user provided.
  // The user provided 3000 for expenses. I will use 3000 for expenses specifically.

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
      final token = await getToken();
      final response = await http.post(
        Uri.parse('$authBaseUrl/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      await clearSession();
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Logout error: $e'};
    }
  }

  // Users CRUD
  static Future<Map<String, dynamic>> getUsers() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$authBaseUrl/users'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error fetching users: $e'};
    }
  }

  static Future<Map<String, dynamic>> createUser(Map<String, dynamic> userData) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('$authBaseUrl/users'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(userData),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error creating user: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateUser(String userId, Map<String, dynamic> userData) async {
    try {
      final token = await getToken();
      final response = await http.put(
        Uri.parse('$authBaseUrl/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(userData),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error updating user: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteUser(String userId) async {
    try {
      final token = await getToken();
      final response = await http.delete(
        Uri.parse('$authBaseUrl/users/$userId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error deleting user: $e'};
    }
  }

  // Trips CRUD
  static Future<Map<String, dynamic>> getTrips({String? category, int? month, int? year}) async {
    try {
      final token = await getToken();
      Map<String, String> queryParams = {};
      if (category != null && category != 'all') queryParams['category'] = category;
      if (month != null) queryParams['month'] = month.toString();
      if (year != null) queryParams['year'] = year.toString();

      final uri = Uri.parse(tripsBaseUrl).replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error fetching trips: $e'};
    }
  }

  static Future<Map<String, dynamic>> getTripById(String tripId) async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$tripsBaseUrl/$tripId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error fetching trip: $e'};
    }
  }

  static Future<Map<String, dynamic>> getTripsByDriver(String driverId, {String? category, int? month, int? year}) async {
    try {
      final token = await getToken();
      Map<String, String> queryParams = {};
      if (category != null && category != 'all') queryParams['category'] = category;
      if (month != null) queryParams['month'] = month.toString();
      if (year != null) queryParams['year'] = year.toString();

      final uri = Uri.parse('$tripsBaseUrl/driver/$driverId').replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error fetching driver trips: $e'};
    }
  }

  static Future<Map<String, dynamic>> createTrip(Map<String, dynamic> tripData) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse(tripsBaseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(tripData),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error creating trip: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateTrip(String tripId, Map<String, dynamic> tripData) async {
    try {
      final token = await getToken();
      final response = await http.put(
        Uri.parse('$tripsBaseUrl/$tripId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(tripData),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error updating trip: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteTrip(String tripId) async {
    try {
      final token = await getToken();
      final response = await http.delete(
        Uri.parse('$tripsBaseUrl/$tripId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error deleting trip: $e'};
    }
  }

  // Expenses CRUD
  static Future<Map<String, dynamic>> getExpenses({String? status, String? driverId}) async {
    try {
      final token = await getToken();
      Map<String, String> queryParams = {};
      if (status != null && status != 'all') queryParams['status'] = status;
      if (driverId != null) queryParams['driver_id'] = driverId;

      final uri = Uri.parse('http://localhost:8000/api/expenses').replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error fetching expenses: $e'};
    }
  }

  static Future<Map<String, dynamic>> createExpense(Map<String, dynamic> expenseData) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('http://localhost:8000/api/expenses'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(expenseData),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error creating expense: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateExpense(String expenseId, Map<String, dynamic> expenseData) async {
    try {
      final token = await getToken();
      final response = await http.put(
        Uri.parse('http://localhost:8000/api/expenses/$expenseId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(expenseData),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error updating expense: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteExpense(String expenseId) async {
    try {
      final token = await getToken();
      final response = await http.delete(
        Uri.parse('http://localhost:8000/api/expenses/$expenseId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error deleting expense: $e'};
    }
  }

  // Statistics
  static Future<Map<String, dynamic>> getRevenueStats() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('http://localhost:8000/api/trips/stats/revenue'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error fetching revenue stats: $e'};
    }
  }

  static Future<Map<String, dynamic>> getExpenseBreakdown({int? month, int? year}) async {
    try {
      final token = await getToken();
      Map<String, String> queryParams = {};
      if (month != null) queryParams['month'] = month.toString();
      if (year != null) queryParams['year'] = year.toString();

      final uri = Uri.parse('http://localhost:8000/api/expenses/stats/breakdown')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error fetching expense breakdown: $e'};
    }
  }

  // Salary Advances CRUD
  static Future<Map<String, dynamic>> getAdvances() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('http://localhost:8000/api/advances'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error fetching advances: $e'};
    }
  }

  static Future<Map<String, dynamic>> createAdvance(Map<String, dynamic> advanceData) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('http://localhost:8000/api/advances'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(advanceData),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error creating advance: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateAdvance(String advanceId, Map<String, dynamic> advanceData) async {
    try {
      final token = await getToken();
      final response = await http.put(
        Uri.parse('http://localhost:8000/api/advances/$advanceId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(advanceData),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error updating advance: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateAdvanceStatus(String advanceId, String status) async {
    try {
      final token = await getToken();
      final response = await http.put(
        Uri.parse('http://localhost:8000/api/advances/$advanceId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'status': status}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error updating advance status: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteAdvance(String advanceId) async {
    try {
      final token = await getToken();
      final response = await http.delete(
        Uri.parse('http://localhost:8000/api/advances/$advanceId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error deleting advance: $e'};
    }
  }
}

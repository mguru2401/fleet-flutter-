import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'drivers_screen.dart';
import 'trips_screen.dart';
import 'expenses_screen.dart';
import 'admin_stats_screen.dart';
import 'advances_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  String _role = 'admin';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _role = prefs.getString('user_role') ?? 'admin';
      _isLoading = false;
    });
  }

  List<Widget> get _widgetOptions {
    if (_role == 'driver') {
      return [
        const TripsScreen(),
        const ExpensesScreen(),
        SettingsScreen(role: _role),
      ];
    }
    return [
      const AdminStatsScreen(),
      const DriversScreen(),
      const TripsScreen(),
      const ExpensesScreen(),
      const AdvancesScreen(),
      SettingsScreen(role: _role),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _handleLogout() async {
    final response = await ApiService.logout();
    if (response['success'] == true) {
      Fluttertoast.showToast(msg: "Logged out successfully");
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      Fluttertoast.showToast(msg: "Logout failed: ${response['message']}");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_role == 'admin' ? 'Fleet Admin' : 'Driver Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: _role == 'driver' 
          ? const <BottomNavigationBarItem>[
              BottomNavigationBarItem(icon: Icon(Icons.history), label: 'My Trips'),
              BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Expenses'),
              BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
            ]
          : const <BottomNavigationBarItem>[
              BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.directions_car), label: 'Drivers'),
              BottomNavigationBarItem(icon: Icon(Icons.history), label: 'All Trips'),
              BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Expenses'),
              BottomNavigationBarItem(icon: Icon(Icons.payments), label: 'Advances'),
              BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
            ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF2575FC),
        onTap: _onItemTapped,
      ),
    );
  }
}

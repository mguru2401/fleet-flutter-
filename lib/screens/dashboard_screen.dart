import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'drivers_screen.dart';
import 'trips_screen.dart';
import 'expenses_screen.dart';
import 'admin_earnings_screen.dart';
import 'earnings_screen.dart';
import 'advances_screen.dart';
import 'settings_screen.dart';
import '../widgets/app_background.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  String _role = 'admin';
  String _userName = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final profile = await ApiService.getProfile();
    
    setState(() {
      _role = prefs.getString('user_role') ?? 'admin';
      if (profile['success'] == true) {
        _userName = profile['data']['name'] ?? '';
      }
      _isLoading = false;
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  List<Widget> get _widgetOptions {
    if (_role == 'driver') {
      return [
        const EarningsScreen(),
        const TripsScreen(),
        const ExpensesScreen(),
        SettingsScreen(role: _role),
      ];
    }
    return [
      const AdminEarningsScreen(),
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

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          title: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_getGreeting()},',
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
                Text(
                  _userName.isNotEmpty ? _userName : 'User',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: _widgetOptions.elementAt(_selectedIndex),
        ),
        bottomNavigationBar: Theme(
          data: Theme.of(context).copyWith(
            canvasColor: const Color(0xFF0e3a35),
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            items: _role == 'driver' 
              ? const <BottomNavigationBarItem>[
                  BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Earnings'),
                  BottomNavigationBarItem(icon: Icon(Icons.directions_car), label: 'Trips'),
                  BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Expenses'),
                  BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
                ]
              : const <BottomNavigationBarItem>[
                BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Analytics'),
                BottomNavigationBarItem(icon: Icon(Icons.directions_car), label: 'Drivers'),
                BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Trips'),
                BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Expenses'),
                BottomNavigationBarItem(icon: Icon(Icons.payments), label: 'Advances'),
                BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
              ],
            currentIndex: _selectedIndex,
            selectedItemColor: const Color(0xFF2575FC),
            unselectedItemColor: Colors.white60,
            onTap: _onItemTapped,
          ),
        ),
      ),
    );
  }
}

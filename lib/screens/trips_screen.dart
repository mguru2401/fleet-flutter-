import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/trip_model.dart';
import 'trip_form_screen.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  List<Trip> _trips = [];
  bool _isLoading = false;
  Map<String, dynamic>? _goalStatus;

  List<String> _validCategories = ['all'];
  String _selectedCategory = 'all';
  int? _selectedMonth;
  int? _selectedYear;

  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchTrips();
    _fetchGoalStatus();
  }

  Future<void> _fetchGoalStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role') ?? 'admin';
    if (role != 'driver') return;

    final now = DateTime.now();
    final month = _selectedMonth ?? now.month;
    final year = _selectedYear ?? now.year;

    final response = await ApiService.getGoalStatus(month: month, year: year);
    if (response['success'] == true) {
      setState(() {
        _goalStatus = response['data'];
      });
    }
  }

  Future<void> _fetchCategories() async {
    final response = await ApiService.getCategories();
    if (response['success'] == true) {
      final List<dynamic> data = response['data'] ?? [];
      setState(() {
        _validCategories = ['all', ...data.map((c) => c['name'].toString())];
      });
    }
  }

  Future<void> _fetchTrips() async {
    setState(() => _isLoading = true);
    _fetchGoalStatus(); // Fetch goal status whenever trips are fetched
    
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role') ?? 'admin';
    final driverId = prefs.getString('driver_id');

    final Map<String, dynamic> response;
    if (role == 'driver' && driverId != null) {
      response = await ApiService.getTripsByDriver(
        driverId,
        category: _selectedCategory,
        month: _selectedMonth,
        year: _selectedYear,
      );
    } else {
      response = await ApiService.getTrips(
        category: _selectedCategory,
        month: _selectedMonth,
        year: _selectedYear,
      );
    }
    
    setState(() => _isLoading = false);

    if (response['success'] == true) {
      final List<dynamic> data = response['data'] ?? [];
      setState(() {
        _trips = data.map((json) => Trip.fromJson(json)).toList();
      });
    } else {
      Fluttertoast.showToast(msg: "Error: ${response['message']}");
    }
  }

  Future<void> _deleteTrip(String tripId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Trip'),
        content: const Text('Are you sure you want to delete this trip?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      final response = await ApiService.deleteTrip(tripId);
      if (response['success'] == true) {
        Fluttertoast.showToast(msg: "Trip deleted successfully");
        _fetchTrips();
      } else {
        setState(() => _isLoading = false);
        Fluttertoast.showToast(msg: "Error: ${response['message']}");
      }
    }
  }

  Widget _buildGoalProgressBar() {
    if (_goalStatus == null) return const SizedBox.shrink();

    final achievement = (_goalStatus!['achievement_percentage'] as num?)?.toDouble() ?? 0.0;
    final soFar = _goalStatus!['so_far_salary'] ?? 0;
    final remaining = _goalStatus!['remaining_to_goal'] ?? 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Goal Progress Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('${achievement.toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2575FC))),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: achievement / 100,
              minHeight: 12,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2575FC)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('So Far: ₹$soFar', style: const TextStyle(fontSize: 13, color: Colors.green)),
              Text('Remaining: ₹$remaining', style: const TextStyle(fontSize: 13, color: Colors.orange)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Trips'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchTrips,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildGoalProgressBar(),
          // Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                // Category Filter (Horizontal List)
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _validCategories.length,
                    itemBuilder: (context, index) {
                      final cat = _validCategories[index];
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(cat.toUpperCase()),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedCategory = cat);
                              _fetchTrips();
                            }
                          },
                          selectedColor: const Color(0xFF2575FC),
                          labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                // Month and Year Filters
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        value: _selectedMonth,
                        decoration: const InputDecoration(
                          hintText: 'Month',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(value: null, child: Text('All Months')),
                          ...List.generate(12, (index) => DropdownMenuItem<int?>(value: index + 1, child: Text(_months[index]))),
                        ],
                        onChanged: (val) {
                          setState(() => _selectedMonth = val);
                          _fetchTrips();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        value: _selectedYear,
                        decoration: const InputDecoration(
                          hintText: 'Year',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(value: null, child: Text('All Years')),
                          ...List.generate(5, (index) {
                            final year = DateTime.now().year - index;
                            return DropdownMenuItem<int?>(value: year, child: Text(year.toString()));
                          }),
                        ],
                        onChanged: (val) {
                          setState(() => _selectedYear = val);
                          _fetchTrips();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Trip List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _trips.isEmpty
                    ? const Center(child: Text('No trips found matching filters'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _trips.length,
                        itemBuilder: (context, index) {
                          final trip = _trips[index];
                          return Card(
                            elevation: 4,
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              title: Text(
                                trip.dropLocation,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(trip.pickUpDate),
                                      const SizedBox(width: 16),
                                      const Icon(Icons.access_time, size: 16, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(trip.pickUpTime),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Category: ${trip.category.toUpperCase()}', style: const TextStyle(color: Colors.blueAccent)),
                                  Text('Mileage: ${trip.mileage} km | Rate: ₹${trip.tripRate}'),
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => TripFormScreen(trip: trip)),
                                    ).then((value) {
                                      if (value == true) _fetchTrips();
                                    });
                                  } else if (value == 'delete') {
                                    _deleteTrip(trip.id!);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TripFormScreen()),
          ).then((value) {
            if (value == true) _fetchTrips();
          });
        },
        backgroundColor: const Color(0xFF2575FC),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

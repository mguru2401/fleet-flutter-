import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
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

  final TextEditingController _searchController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

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
    _fetchGoalStatus();
    
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role') ?? 'admin';
    final driverId = prefs.getString('driver_id');

    final Map<String, dynamic> response;
    final startStr = _startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : null;
    final endStr = _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null;
    final searchStr = _searchController.text.trim();

    if (role == 'driver' && driverId != null) {
      response = await ApiService.getTripsByDriver(
        driverId,
        category: _selectedCategory,
        month: _selectedMonth,
        year: _selectedYear,
        searchTerm: searchStr,
        startDate: startStr,
        endDate: endStr,
      );
    } else {
      response = await ApiService.getTrips(
        category: _selectedCategory,
        month: _selectedMonth,
        year: _selectedYear,
        searchTerm: searchStr,
        startDate: startStr,
        endDate: endStr,
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

  Future<void> _selectDate(bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF2575FC),
              onPrimary: Colors.white,
              surface: Color(0xFF0e3a35),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
      _fetchTrips();
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

  Map<String, List<Trip>> _groupTripsByDate() {
    Map<String, List<Trip>> groups = {};
    for (var trip in _trips) {
      if (!groups.containsKey(trip.pickUpDate)) {
        groups[trip.pickUpDate] = [];
      }
      groups[trip.pickUpDate]!.add(trip);
    }
    // Sort dates descending
    var sortedKeys = groups.keys.toList()..sort((a, b) => b.compareTo(a));
    return Map.fromIterable(sortedKeys, key: (k) => k, value: (k) => groups[k]!);
  }

  @override
  Widget build(BuildContext context) {
    final groupedTrips = _groupTripsByDate();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              border: const Border(bottom: BorderSide(color: Colors.white12)),
            ),
            child: Column(
              children: [
                // Category Filter
              // Category Filter
SizedBox(
  height: 45,
  child: ListView.builder(
    scrollDirection: Axis.horizontal,
    itemCount: _validCategories.length,
    itemBuilder: (context, index) {
      final cat = _validCategories[index];
      final isSelected = _selectedCategory == cat;

      return Padding(
        padding: const EdgeInsets.only(right: 10),
        child: ChoiceChip(
          label: Text(
            cat.toUpperCase(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() => _selectedCategory = cat);
              _fetchTrips();
            }
          },

          // ✅ Selected chip color
          selectedColor: const Color(0xFF2575FC),

          // ✅ Unselected chip (FIXED VISIBILITY)
          backgroundColor: const Color(0xFF2A2A2A),

          // ✅ Border styling
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected
                  ? const Color(0xFF2575FC)
                  : Colors.white24,
            ),
          ),

          // ✅ Better spacing
          padding: const EdgeInsets.symmetric(horizontal: 10),

          // ✅ Elevation for selected chip
          elevation: isSelected ? 4 : 0,
          shadowColor: Colors.black,
        ),
      );
    },
  ),
),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : groupedTrips.isEmpty
                    ? const Center(child: Text('No trips found', style: TextStyle(color: Colors.white70)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: groupedTrips.length,
                        itemBuilder: (context, index) {
                          final date = groupedTrips.keys.elementAt(index);
                          final trips = groupedTrips[date]!;
                          final totalEarnings = trips.fold<double>(0, (sum, item) => sum + (item.netAmount ?? 0));

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            color: Colors.white.withOpacity(0.05),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                            child: ExpansionTile(
                              iconColor: Colors.white,
                              collapsedIconColor: Colors.white,
                              shape: const RoundedRectangleBorder(side: BorderSide.none),
                              collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2575FC).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.calendar_today, color: Color(0xFF2575FC), size: 20),
                              ),
                              title: Text(
                                _formatDate(date),
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              subtitle: Text(
                                '${trips.length} trips • Total: ₹${totalEarnings.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 12, color: Colors.white70),
                              ),
                              children: trips.map((trip) => _buildTripDetailItem(trip)).toList(),
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

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      if (date.year == now.year && date.month == now.month && date.day == now.day) {
        return "Today, ${DateFormat('MMM d').format(date)}";
      }
      return DateFormat('EEEE, MMM d, yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildDateButton({required String label, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          border: Border.all(color: Colors.white24),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: Colors.white70),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildTripDetailItem(Trip trip) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      trip.pickUpTime,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(trip.category).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        trip.category.toUpperCase(),
                        style: TextStyle(
                          color: _getCategoryColor(trip.category),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  trip.dropLocation,
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${trip.mileage} km • ₹${trip.tripRate} rate',
                  style: const TextStyle(fontSize: 12, color: Colors.white54),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${trip.netAmount?.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.white60),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => TripFormScreen(trip: trip)),
                      ).then((value) {
                        if (value == true) _fetchTrips();
                      });
                    },
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                    onPressed: () => _deleteTrip(trip.id!),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'amazon': return Colors.orange;
      case 'ola': return Colors.lightGreen;
      case 'uber': return Colors.black;
      case 'porter': return Colors.blue;
      default: return Colors.grey;
    }
  }
}

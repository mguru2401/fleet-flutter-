import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/animated_counter.dart';
import '../widgets/app_background.dart';

class AdminEarningsScreen extends StatefulWidget {
  const AdminEarningsScreen({super.key});

  @override
  State<AdminEarningsScreen> createState() => _AdminEarningsScreenState();
}

class _AdminEarningsScreenState extends State<AdminEarningsScreen> {
  List<dynamic> _driverStats = [];
  bool _isLoading = true;
  
  final TextEditingController _searchController = TextEditingController();
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    _fetchAdminDashboard();
  }

  Future<void> _fetchAdminDashboard() async {
    setState(() => _isLoading = true);
    final response = await ApiService.getAdminDashboard(
      month: _selectedMonth,
      year: _selectedYear,
      search: _searchController.text.trim(),
    );
    if (response['success'] == true) {
      setState(() {
        _driverStats = response['data'] ?? [];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchAdminDashboard,
              child: _driverStats.isEmpty && !_isLoading
                  ? const Center(child: Text('No driver data found', style: TextStyle(color: Colors.white70)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _driverStats.length,
                      itemBuilder: (context, index) {
                        final driver = _driverStats[index];
                        return _buildDriverEarningsCard(driver);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        border: const Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search driver name...',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.white70),
              isDense: true,
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            onChanged: (v) => _fetchAdminDashboard(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: DropdownButton<int>(
                    value: _selectedMonth,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF0e3a35),
                    style: const TextStyle(color: Colors.white),
                    underline: const SizedBox(),
                    items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(_months[i]))),
                    onChanged: (v) {
                      setState(() => _selectedMonth = v!);
                      _fetchAdminDashboard();
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: DropdownButton<int>(
                    value: _selectedYear,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF0e3a35),
                    style: const TextStyle(color: Colors.white),
                    underline: const SizedBox(),
                    items: [2025, 2026, 2027].map((y) => DropdownMenuItem(value: y, child: Text(y.toString()))).toList(),
                    onChanged: (v) {
                      setState(() => _selectedYear = v!);
                      _fetchAdminDashboard();
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDriverEarningsCard(Map<String, dynamic> driver) {
    final achievement = (driver['achievement_percentage'] as num?)?.toDouble() ?? 0.0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      child: ExpansionTile(
        iconColor: Colors.white,
        collapsedIconColor: Colors.white,
        tilePadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF2575FC).withOpacity(0.1),
              child: Text(driver['name'][0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2575FC))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(driver['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                  Text('${driver['today_trips_count']} trips today', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Today Earning', style: TextStyle(color: Colors.white70, fontSize: 10)),
                AnimatedCounter(
                  value: double.tryParse((driver['today_salary'] ?? 0).toString()) ?? 0.0,
                  prefix: '₹',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.greenAccent),
                ),
              ],
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Monthly Goal Progress', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  Text('${achievement.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2575FC))),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: achievement / 100,
                  minHeight: 6,
                  backgroundColor: Colors.grey.shade100,
                  valueColor: AlwaysStoppedAnimation<Color>(achievement >= 100 ? Colors.green : const Color(0xFF2575FC)),
                ),
              ),
            ],
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(color: Colors.white10),
                _buildDailyTargetProgressBar(driver),
                const Divider(color: Colors.white10),
                const Text('Salary Details:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                const SizedBox(height: 8),
                _buildDetailRow('Base Salary', driver['salary_details']['base_salary']),
                _buildDetailRow('Incentives', driver['salary_details']['incentive_salary']),
                _buildDetailRow('Ola/Uber (30%)', driver['salary_details']['ola_uber_salary']),
                const Divider(color: Colors.white10),
                _buildDetailRow('Today Total Revenue', driver['today_revenue'], isBold: true, color: Colors.blueAccent),
                _buildDetailRow('Remaining to Goal', driver['remaining_to_goal'], color: Colors.orangeAccent),
                const SizedBox(height: 16),
                const Text('Today\'s Trips:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                const SizedBox(height: 8),
                _buildTripsList(driver['today_trips'] ?? []),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripsList(List<dynamic> trips) {
    if (trips.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('No trips recorded today', style: TextStyle(color: Colors.white54, fontSize: 12)),
      );
    }
    return Column(
      children: trips.map((trip) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(trip['drop_location'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('${trip['pick_up_time']} • ${trip['category'].toString().toUpperCase()}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                ],
              ),
            ),
            Text('₹${trip['net_amount'].toStringAsFixed(0)}', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildDailyTargetProgressBar(Map<String, dynamic> driver) {
    final revenue = double.tryParse((driver['today_revenue'] ?? 0).toString()) ?? 0.0;
    final target = double.tryParse((driver['target_revenue_per_day'] ?? 0).toString()) ?? 0.0;
    final progress = target > 0 ? (revenue / target).clamp(0.0, 1.0) : 0.0;
    final isExceeded = revenue >= target;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Daily Revenue Target', style: TextStyle(fontSize: 12, color: Colors.white70)),
            Text(
              '₹${revenue.toStringAsFixed(0)} / ₹${target.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isExceeded ? Colors.greenAccent : Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              isExceeded ? Colors.greenAccent : const Color(0xFF2575FC),
            ),
          ),
        ),
        if (isExceeded)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'Target Achieved! 🏆',
              style: TextStyle(fontSize: 10, color: Colors.greenAccent, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  Widget _buildDetailRow(String label, dynamic value, {bool isBold = false, Color? color}) {
    final numValue = double.tryParse((value ?? 0).toString()) ?? 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: isBold ? Colors.white : Colors.white70)),
          Text(
            '₹${numValue.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 13, 
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color ?? Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

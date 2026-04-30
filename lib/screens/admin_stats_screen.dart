import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/animated_counter.dart';

class AdminStatsScreen extends StatefulWidget {
  const AdminStatsScreen({super.key});

  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() => _isLoading = true);
    final response = await ApiService.getRevenueStats();
    if (response['success'] == true) {
      setState(() {
        _stats = response['data'];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_stats == null) return const Center(child: Text('Failed to load stats'));

    final overall = _stats!['overall_summary'];
    final byCarAndCat = _stats!['by_car_and_category'] as Map<String, dynamic>;

    return RefreshIndicator(
      onRefresh: _fetchStats,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverallSummary(overall),
            const SizedBox(height: 24),
            const Text(
              'Revenue by Car & Category',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...byCarAndCat.entries.map((entry) => _buildCarCard(entry.key, entry.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallSummary(Map<String, dynamic> overall) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2575FC), Color(0xFF6A11CB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total Revenue', overall['total_revenue'], prefix: '₹'),
              Container(width: 1, height: 40, color: Colors.white24),
              _buildStatItem('Total Trips', overall['total_trips']),
            ],
          ),
          const Divider(color: Colors.white24, height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Expenses', overall['total_expense'], prefix: '₹', color: Colors.redAccent.shade100),
              Container(width: 1, height: 40, color: Colors.white24),
              _buildStatItem('Net Profit', overall['net_profit'], prefix: '₹', color: Colors.greenAccent.shade200),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, num value, {String prefix = '', Color color = Colors.white}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        AnimatedCounter(
          value: value,
          prefix: prefix,
          style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildCarCard(String carNo, Map<String, dynamic> categories) {
    final carStats = _stats!['by_car']?[carNo] ?? {};
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.directions_car, color: Color(0xFF2575FC)),
                    const SizedBox(width: 8),
                    Text(
                      carNo,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text('${carStats['trip_count'] ?? 0} trips', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            const Divider(height: 24),
            // Car Summary Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMiniStat('Revenue', carStats['total_revenue'] ?? 0),
                _buildMiniStat('Expense', carStats['total_expense'] ?? 0, color: Colors.red),
                _buildMiniStat('Profit', carStats['net_profit'] ?? 0, color: Colors.green),
              ],
            ),
            const Divider(height: 24),
            const Text('Category Details:', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...categories.entries.map((cat) {
              final data = cat.value as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      cat.key.toUpperCase(),
                      style: const TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                    Text(
                      '₹${data['total_revenue']} (${data['trip_count']})',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, num value, {Color? color}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        const SizedBox(height: 4),
        AnimatedCounter(
          value: value,
          prefix: '₹',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color),
        ),
      ],
    );
  }
}

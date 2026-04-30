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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total Revenue', overall['total_revenue'], prefix: '₹'),
          Container(width: 1, height: 50, color: Colors.white24),
          _buildStatItem('Total Trips', overall['total_trips']),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, num value, {String prefix = ''}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 4),
        AnimatedCounter(
          value: value,
          prefix: prefix,
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildCarCard(String carNo, Map<String, dynamic> categories) {
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
              children: [
                const Icon(Icons.directions_car, color: Color(0xFF2575FC)),
                const SizedBox(width: 8),
                Text(
                  'Car: $carNo',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            ...categories.entries.map((cat) {
              final data = cat.value as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      cat.key.toUpperCase(),
                      style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                    ),
                    Row(
                      children: [
                        Text('${data['trip_count']} trips', style: const TextStyle(color: Colors.blueGrey)),
                        const SizedBox(width: 16),
                        AnimatedCounter(
                          value: data['total_revenue'],
                          prefix: '₹',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
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
}

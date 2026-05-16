import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:confetti/confetti.dart';
import '../models/user_dashboard_model.dart';
import '../services/api_service.dart';
import '../widgets/animated_counter.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  static bool _hasCelebratedThisSession = false;

  static void resetCelebration() {
    _hasCelebratedThisSession = false;
  }

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> with TickerProviderStateMixin {
  UserDashboardData? _dashboardData;
  bool _isLoading = true;
  
  late ConfettiController _confettiController;
  late AnimationController _progressController;
  Animation<double>? _progressAnimation;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fetchDashboardData();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    final response = await ApiService.getUserDashboard();
    if (response['success'] == true) {
      setState(() {
        _dashboardData = UserDashboardModel.fromJson(response).data;
        _isLoading = false;
      });
      
      final progress = (_dashboardData!.todayRevenue / _dashboardData!.todayTarget).clamp(0.0, 2.0);
      _progressAnimation = Tween<double>(begin: 0, end: progress).animate(
        CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
      );
      _progressController.forward(from: 0);

      if (_dashboardData!.todayRevenue >= _dashboardData!.todayTarget && !EarningsScreen._hasCelebratedThisSession) {
        EarningsScreen._hasCelebratedThisSession = true;
        _confettiController.play();
      }
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Failed to load dashboard')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_dashboardData == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Failed to load earnings data', style: TextStyle(color: Colors.white)),
              ElevatedButton(
                onPressed: _fetchDashboardData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _fetchDashboardData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGoalCard(),
                  const SizedBox(height: 24),
                  _buildDailyTargetProgress(),
                  const SizedBox(height: 24),
                  _buildDailyStatsHeader(),
                  const SizedBox(height: 16),
                  _buildDailyEarningsGrid(),
                  const SizedBox(height: 24),
                  const Text(
                    'Today\'s Trips',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  _buildTodayTripsList(),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
              numberOfParticles: 20,
              gravity: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard() {
    final data = _dashboardData!;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2575FC), Color(0xFF6A11CB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2575FC).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Monthly Goal Progress',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMMM yyyy').format(DateTime(data.year, data.month)),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${data.achievementPercentage.toStringAsFixed(1)}%',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          LinearProgressIndicator(
            value: data.achievementPercentage / 100,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            borderRadius: BorderRadius.circular(10),
            minHeight: 10,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildGoalInfoItem('Achieved', data.soFarSalary),
              _buildGoalInfoItem('Remaining', data.remainingToGoal),
              _buildGoalInfoItem('Target', data.desiredSalary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyTargetProgress() {
    final data = _dashboardData!;
    final isExceeded = data.todayRevenue >= data.todayTarget;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Daily Revenue Target',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text(
                '₹${data.todayRevenue.toStringAsFixed(0)} / ₹${data.todayTarget.toStringAsFixed(0)}',
                style: TextStyle(
                  color: isExceeded ? Colors.greenAccent : Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _progressController,
            builder: (context, child) {
              final currentProgress = (_progressAnimation?.value ?? 0).clamp(0.0, 1.0);
              return Stack(
                children: [
                  Container(
                    height: 12,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: currentProgress,
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isExceeded 
                            ? [Colors.green, Colors.greenAccent]
                            : [const Color(0xFF2575FC), Colors.blueAccent],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          if (isExceeded && currentProgress >= 1.0)
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isExceeded ? 'Target Achieved! 🏆' : 'Remaining to Target',
                style: TextStyle(
                  color: isExceeded ? Colors.greenAccent : Colors.white54,
                  fontSize: 12,
                  fontWeight: isExceeded ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              Text(
                '₹${data.revenueVsTargetDiff.abs().toStringAsFixed(0)} ${data.revenueVsTargetDiff >= 0 ? 'surplus' : 'needed'}',
                style: TextStyle(
                  color: data.revenueVsTargetDiff >= 0 ? Colors.greenAccent : Colors.orangeAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalInfoItem(String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        AnimatedCounter(
          value: value,
          prefix: '₹',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDailyStatsHeader() {
    final data = _dashboardData!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Today\'s Summary',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text('Revenue vs Target', style: TextStyle(color: Colors.white70, fontSize: 12)),
            Text(
              '${data.revenueVsTargetDiff >= 0 ? '+' : ''}₹${data.revenueVsTargetDiff.toStringAsFixed(0)}',
              style: TextStyle(
                color: data.revenueVsTargetDiff >= 0 ? Colors.greenAccent : Colors.redAccent,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDailyEarningsGrid() {
    final data = _dashboardData!;
    final details = data.salaryDetails;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildEarningItem('Today Total Earning', data.todaySalary, Icons.account_balance_wallet, Colors.blue),
        _buildEarningItem('Base Salary', details.baseSalary, Icons.payments, Colors.orange),
        _buildEarningItem('Incentives', details.incentiveSalary, Icons.trending_up, Colors.green),
        _buildEarningItem('Incentive Eligible', details.eligibleAmount, Icons.stars, Colors.purple),
      ],
    );
  }

  Widget _buildEarningItem(String label, double value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          AnimatedCounter(
            value: value,
            prefix: '₹',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayTripsList() {
    final trips = _dashboardData!.todayTrips;
    if (trips.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Text('No trips recorded today', style: TextStyle(color: Colors.white54)),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: trips.length,
      itemBuilder: (context, index) {
        final trip = trips[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: Colors.white.withOpacity(0.05),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: _getCategoryColor(trip.category).withOpacity(0.1),
              child: Icon(_getCategoryIcon(trip.category), color: _getCategoryColor(trip.category)),
            ),
            title: Text(
              trip.dropLocation,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text('${trip.pickUpTime} • ${trip.category.toUpperCase()}', style: const TextStyle(color: Colors.white60)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${trip.netAmount.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.greenAccent),
                ),
                Text(
                  '${trip.mileage.toStringAsFixed(1)} km',
                  style: const TextStyle(fontSize: 11, color: Colors.white54),
                ),
              ],
            ),
          ),
        );
      },
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

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'amazon': return Icons.shopping_bag;
      case 'ola':
      case 'uber': return Icons.local_taxi;
      case 'porter': return Icons.local_shipping;
      default: return Icons.directions_car;
    }
  }
}

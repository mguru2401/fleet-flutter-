import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/api_service.dart';
import '../widgets/animated_counter.dart';
import '../widgets/app_background.dart';

class UserSalaryScreen extends StatefulWidget {
  const UserSalaryScreen({super.key});

  @override
  State<UserSalaryScreen> createState() => _UserSalaryScreenState();
}

class _UserSalaryScreenState extends State<UserSalaryScreen> {
  Map<String, dynamic>? _salaryData;
  bool _isLoading = true;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    _fetchSalaryData();
  }

  Future<void> _fetchSalaryData() async {
    setState(() => _isLoading = true);
    final response = await ApiService.getUserSalaryDashboard(
      month: _selectedMonth,
      year: _selectedYear,
    );
    if (response['success'] == true) {
      setState(() {
        _salaryData = response['data'];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      Fluttertoast.showToast(msg: "Error: ${response['message']}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('My Salary', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchSalaryData),
          ],
        ),
        body: Column(
          children: [
            _buildFilterBar(),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _fetchSalaryData,
                    child: _salaryData == null
                      ? const Center(child: Text('No salary data for this period', style: TextStyle(color: Colors.white70)))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            children: [
                              _buildMainSummaryCard(),
                              const SizedBox(height: 16),
                              _buildDetailCard(),
                              const SizedBox(height: 16),
                              _buildBreakdownCard(),
                            ],
                          ),
                        ),
                  ),
            ),
          ],
        ),
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
      child: Row(
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
                  _fetchSalaryData();
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
                  _fetchSalaryData();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainSummaryCard() {
    final payable = ((_salaryData!['final_company_payable'] ?? 0) as num).toDouble();
    final status = _salaryData!['status'] == 'paid' ? 'SETTLED' : 'PENDING';
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2575FC).withOpacity(0.2),
            const Color(0xFF6A11CB).withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Company Payable', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 4),
                  AnimatedCounter(
                    value: payable,
                    prefix: '₹',
                    style: TextStyle(
                      fontSize: 32, 
                      fontWeight: FontWeight.bold, 
                      color: payable >= 0 ? Colors.greenAccent : Colors.redAccent,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (status == 'SETTLED' ? Colors.greenAccent : Colors.orangeAccent).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: (status == 'SETTLED' ? Colors.greenAccent : Colors.orangeAccent).withOpacity(0.5)),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: status == 'SETTLED' ? Colors.greenAccent : Colors.orangeAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ],
          ),
          if (_salaryData!['status'] == 'paid' && _salaryData!['payment_method'] != null) ...[
            const SizedBox(height: 16),
            const Divider(color: Colors.white10),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Payment Method', style: TextStyle(color: Colors.white54, fontSize: 12)),
                Text(_salaryData!['payment_method'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailCard() {
    return Card(
      color: Colors.white.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.white10)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildFinanceRow('Total Salary Earned', _salaryData!['total_salary_earned'], color: Colors.greenAccent),
            _buildFinanceRow('Total Advances', _salaryData!['total_advances'], color: Colors.redAccent, isDeduction: true),
            _buildFinanceRow('Cash Collected', _salaryData!['cash_revenue_collected'], color: Colors.redAccent, isDeduction: true),
            const Divider(color: Colors.white10, height: 24),
            _buildFinanceRow('Amount with You (Cash)', _salaryData!['amount_remaining_in_hand'], color: Colors.orangeAccent),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownCard() {
    final breakdown = _salaryData!['breakdown'];
    return Card(
      color: Colors.white.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.white10)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Salary Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
            const SizedBox(height: 16),
            _buildBreakdownRow('Base Pay', breakdown['base_pay']),
            _buildBreakdownRow('Performance Incentives', breakdown['incentives']),
            _buildBreakdownRow('Partner Commissions', breakdown['ola_uber_commission']),
          ],
        ),
      ),
    );
  }

  Widget _buildFinanceRow(String label, dynamic value, {Color? color, bool isBold = false, bool isDeduction = false}) {
    final numValue = (value as num?) ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: isBold ? Colors.white : Colors.white70)),
          Text(
            '${isDeduction ? "-" : ""}₹${numValue.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 14, 
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color ?? Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, dynamic value) {
    final numValue = (value as num?) ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.white54)),
          Text(
            '₹${numValue.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

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
    final payable = double.tryParse((_salaryData!['final_company_payable'] ?? 0).toString()) ?? 0.0;
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
          const SizedBox(height: 20),
          const Divider(color: Colors.white10),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryStat('Target Revenue', _salaryData!['targeted_revenue_mtd']),
              _buildSummaryStat(
                'Actual Revenue', 
                _salaryData!['actual_revenue_mtd'], 
                color: (double.tryParse((_salaryData!['actual_revenue_mtd'] ?? 0).toString()) ?? 0) >= 
                       (double.tryParse((_salaryData!['targeted_revenue_mtd'] ?? 0).toString()) ?? 0) 
                  ? Colors.greenAccent 
                  : Colors.orangeAccent,
              ),
            ],
          ),
          if (_salaryData!['status'] == 'paid' && _salaryData!['payment_method'] != null) ...[
            const SizedBox(height: 16),
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

  Widget _buildSummaryStat(String label, dynamic value, {Color? color}) {
    final numValue = double.tryParse((value ?? 0).toString()) ?? 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        const SizedBox(height: 4),
        Text(
          '₹${numValue.toStringAsFixed(0)}',
          style: TextStyle(
            color: color ?? Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailCard() {
    final breakdown = _salaryData!['breakdown'] ?? {};
    final basePay = double.tryParse((breakdown['base_pay'] ?? 0).toString()) ?? 0.0;
    final incentives = double.tryParse((breakdown['incentives'] ?? 0).toString()) ?? 0.0;
    final totalEarned = basePay + incentives;
    final netCash = double.tryParse((_salaryData!['net_cash_in_hand'] ?? 0).toString()) ?? 0.0;

    return Card(
      color: Colors.white.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.white10)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildFinanceRow('Total Salary Earned', totalEarned, color: Colors.greenAccent),
            _buildFinanceRow(
              'Total Advances', 
              _salaryData!['total_advances'], 
              color: Colors.redAccent, 
              isDeduction: true,
              onInfo: () => _showInfoModal('Advances', _salaryData!['advances_list']),
            ),
            _buildFinanceRow(
              'Expenses', 
              _salaryData!['total_expenses'], 
              color: Colors.redAccent, 
              isDeduction: true,
              onInfo: () => _showInfoModal('Expenses', _salaryData!['expense_list']),
            ),
            _buildFinanceRow(
              'Cash Collected', 
              _salaryData!['cash_revenue_collected'], 
              color: Colors.redAccent, 
              isDeduction: true,
              onInfo: () => _showInfoModal('Ola/Uber Trips', _salaryData!['ola_uber_trips_list']),
            ),
            const Divider(color: Colors.white10, height: 24),
            _buildFinanceRow(
              'Remaining Cash in Hand', 
              netCash, 
              color: netCash >= 0 ? Colors.orangeAccent : Colors.redAccent,
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoModal(String title, List<dynamic> items) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0e3a35),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 16),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('No records found', style: TextStyle(color: Colors.white54)),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(color: Colors.white10),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          item['description'] ?? item['drop_location'] ?? 'N/A',
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        subtitle: Text(
                          item['date'] ?? item['pick_up_date'] ?? '',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        trailing: Text(
                          '₹${(item['amount'] ?? item['net_amount'] ?? 0).toStringAsFixed(0)}',
                          style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white12),
                  child: const Text('Close', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBreakdownCard() {
    final breakdown = _salaryData!['breakdown'] ?? {};
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
            _buildBreakdownRow('Base Pay', '₹${(double.tryParse((breakdown['base_pay'] ?? 0).toString()) ?? 0.0).toStringAsFixed(0)}'),
            _buildBreakdownRow('Incentive Eligible Amount', '₹${(double.tryParse((breakdown['eligible_amount'] ?? 0).toString()) ?? 0.0).toStringAsFixed(0)}'),
            _buildBreakdownRow('Performance Incentives', '₹${(double.tryParse((breakdown['incentives'] ?? 0).toString()) ?? 0.0).toStringAsFixed(0)}'),
            const Divider(color: Colors.white10, height: 24),
            _buildBreakdownRow('Total Working Days', '${_salaryData!['total_working_days_mtd'] ?? 0} Days', isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildFinanceRow(String label, dynamic value, {Color? color, bool isBold = false, bool isDeduction = false, VoidCallback? onInfo}) {
    final numValue = double.tryParse((value ?? 0).toString()) ?? 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(label, style: TextStyle(fontSize: 14, color: isBold ? Colors.white : Colors.white70)),
              if (onInfo != null) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onInfo,
                  child: const Icon(Icons.info_outline, size: 14, color: Colors.blueAccent),
                ),
              ],
            ],
          ),
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

  Widget _buildBreakdownRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: isBold ? Colors.white : Colors.white54, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(
            value,
            style: TextStyle(fontSize: 13, color: isBold ? Colors.white : Colors.white70, fontWeight: isBold ? FontWeight.bold : FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

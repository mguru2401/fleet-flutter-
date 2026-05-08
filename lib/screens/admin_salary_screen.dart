import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/api_service.dart';
import '../widgets/animated_counter.dart';

class AdminSalaryScreen extends StatefulWidget {
  const AdminSalaryScreen({super.key});

  @override
  State<AdminSalaryScreen> createState() => _AdminSalaryScreenState();
}

class _AdminSalaryScreenState extends State<AdminSalaryScreen> {
  List<dynamic> _salaryStats = [];
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
    _fetchSalaryStats();
  }

  Future<void> _fetchSalaryStats() async {
    setState(() => _isLoading = true);
    final response = await ApiService.getAdminSalaryDashboard(
      month: _selectedMonth,
      year: _selectedYear,
    );
    if (response['success'] == true) {
      setState(() {
        _salaryStats = response['data'] ?? [];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      Fluttertoast.showToast(msg: "Error: ${response['message']}");
    }
  }

  Future<void> _handleSettle(Map<String, dynamic> driver) async {
    String selectedMethod = 'Bank Transfer';
    final List<String> methods = ['UPI', 'Bank Transfer', 'NEFT', 'Cash'];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF0e3a35),
          title: const Text('Settle Salary', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Confirm settlement for ${driver['driver_name']}?', style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 20),
              const Text('Payment Method:', style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: DropdownButton<String>(
                  value: selectedMethod,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF0e3a35),
                  style: const TextStyle(color: Colors.white),
                  underline: const SizedBox(),
                  items: methods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (v) => setDialogState(() => selectedMethod = v!),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.greenAccent),
              child: const Text('Confirm & Pay'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      final payload = {
        "driver_id": driver['driver_id'],
        "month": _selectedMonth,
        "year": _selectedYear,
        "payment_method": selectedMethod
      };
      final response = await ApiService.settleSalary(payload);
      if (response['success'] == true) {
        Fluttertoast.showToast(msg: "Salary settled successfully", backgroundColor: Colors.green);
        _fetchSalaryStats();
      } else {
        setState(() => _isLoading = false);
        Fluttertoast.showToast(msg: "Error: ${response['message']}", backgroundColor: Colors.red);
      }
    }
  }

  void _showAdvancesDetails(List<dynamic> advances) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0e3a35),
        title: const Text('Advance Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: advances.isEmpty
            ? const Text('No advance details available', style: TextStyle(color: Colors.white70))
            : ListView.builder(
                shrinkWrap: true,
                itemCount: advances.length,
                itemBuilder: (context, index) {
                  final adv = advances[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('₹${adv['amount']}', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(adv['date'] ?? '', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          ],
                        ),
                        if (adv['description'] != null && adv['description'].toString().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(adv['description'], style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                        const SizedBox(height: 4),
                        Text('Status: ${adv['status']?.toUpperCase()}', style: TextStyle(color: adv['status'] == 'paid' ? Colors.blueAccent : Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                },
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _fetchSalaryStats,
                  child: _salaryStats.isEmpty
                    ? const Center(child: Text('No salary data found', style: TextStyle(color: Colors.white70)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _salaryStats.length,
                        itemBuilder: (context, index) {
                          return _buildSalaryCard(_salaryStats[index]);
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
                  _fetchSalaryStats();
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
                  _fetchSalaryStats();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalaryCard(Map<String, dynamic> driver) {
    final payable = (driver['final_company_payable'] as num).toDouble();
    final inHand = (driver['amount_remaining_in_hand'] as num).toDouble();
    final totalAdvances = (driver['total_advances'] as num).toDouble();
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      child: ExpansionTile(
        iconColor: Colors.white,
        collapsedIconColor: Colors.white,
        tilePadding: const EdgeInsets.all(16),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF2575FC).withOpacity(0.1),
              child: Text(driver['driver_name'][0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2575FC))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(driver['driver_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                  Text('${_months[_selectedMonth - 1]} $_selectedYear', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Payable', style: TextStyle(color: Colors.white70, fontSize: 10)),
                AnimatedCounter(
                  value: payable,
                  prefix: '₹',
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 16, 
                    color: payable >= 0 ? Colors.greenAccent : Colors.redAccent,
                  ),
                ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildFinanceRow('Total Salary Earned', driver['total_salary_earned'], color: Colors.greenAccent),
                _buildFinanceRow(
                  'Total Advances', 
                  driver['total_advances'], 
                  color: Colors.redAccent, 
                  isDeduction: true,
                  onInfoTap: totalAdvances > 0 ? () => _showAdvancesDetails(driver['advances_list'] ?? []) : null,
                ),
                _buildFinanceRow('Cash Collected', driver['cash_revenue_collected'], color: Colors.redAccent, isDeduction: true),
                const Divider(color: Colors.white10),
                _buildFinanceRow('In-Hand with Driver', inHand, color: Colors.orangeAccent),
                _buildFinanceRow('Final Payable by Co.', payable, isBold: true, color: payable >= 0 ? Colors.greenAccent : Colors.redAccent),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Salary Breakdown:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                ),
                const SizedBox(height: 8),
                _buildBreakdownRow('Base Pay', driver['breakdown']['base_pay']),
                _buildBreakdownRow('Incentives', driver['breakdown']['incentives']),
                _buildBreakdownRow('Partner Comm.', driver['breakdown']['ola_uber_commission']),
                const SizedBox(height: 20),
                if (driver['status'] == 'paid')
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
                    ),
                    child: const Center(
                      child: Text(
                        'SETTLED',
                        style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => _handleSettle(driver),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent.withOpacity(0.1),
                        foregroundColor: Colors.greenAccent,
                        side: const BorderSide(color: Colors.greenAccent),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Settle & Pay', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceRow(String label, dynamic value, {Color? color, bool isBold = false, bool isDeduction = false, VoidCallback? onInfoTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(label, style: TextStyle(fontSize: 13, color: isBold ? Colors.white : Colors.white70)),
              if (onInfoTap != null) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onInfoTap,
                  child: const Icon(Icons.info_outline, size: 14, color: Colors.blueAccent),
                ),
              ],
            ],
          ),
          Text(
            '${isDeduction ? "-" : ""}₹${(value as num).toStringAsFixed(0)}',
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

  Widget _buildBreakdownRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.white54)),
          Text(
            '₹${(value as num).toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

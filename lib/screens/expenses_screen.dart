import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/expense_model.dart';
import '../widgets/animated_counter.dart';
import 'expense_form_screen.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  List<Expense> _expenses = [];
  Map<String, dynamic>? _breakdownData;
  bool _isLoading = false;
  String _selectedStatus = 'all';
  String _role = 'admin';
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  final List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  @override
  void initState() {
    super.initState();
    _fetchExpenses();
  }

  Future<void> _fetchExpenses() async {
    setState(() => _isLoading = true);
    
    final prefs = await SharedPreferences.getInstance();
    _role = prefs.getString('user_role') ?? 'admin';
    final driverId = prefs.getString('driver_id');

    if (_role == 'admin') {
      final response = await ApiService.getExpenseBreakdown(
        month: _selectedMonth,
        year: _selectedYear,
      );
      if (response['success'] == true) {
        setState(() {
          _breakdownData = response;
        });
      }
    }

    final String? filterDriverId = _role == 'driver' ? driverId : null;
    final response = await ApiService.getExpenses(
      status: _selectedStatus,
      driverId: filterDriverId,
    );
    
    setState(() => _isLoading = false);

    if (response['success'] == true) {
      final List<dynamic> data = response['data'] ?? [];
      setState(() {
        _expenses = data.map((json) => Expense.fromJson(json)).toList();
      });
    } else {
      Fluttertoast.showToast(msg: "Error: ${response['message']}");
    }
  }

  Future<void> _deleteExpense(String expenseId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: const Text('Are you sure you want to delete this expense?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      final response = await ApiService.deleteExpense(expenseId);
      if (response['success'] == true) {
        Fluttertoast.showToast(msg: "Expense deleted successfully");
        _fetchExpenses();
      } else {
        setState(() => _isLoading = false);
        Fluttertoast.showToast(msg: "Error: ${response['message']}");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchExpenses,
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _role == 'admin' ? _buildAdminView() : _buildDriverView(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ExpenseFormScreen()),
          ).then((value) {
            if (value == true) _fetchExpenses();
          });
        },
        backgroundColor: const Color(0xFF2575FC),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAdminView() {
    if (_breakdownData == null) return const Center(child: Text('No breakdown data available'));

    final summary = _breakdownData!['summary'];
    final carData = _breakdownData!['data'] as List<dynamic>;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Summary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              _buildMonthYearPicker(),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF00B4DB), Color(0xFF0083B0)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryStat('Revenue', summary['total_revenue'], '₹'),
                _buildSummaryStat('Expenses', summary['total_expense'], '₹'),
                _buildSummaryStat('Profit', summary['net_profit'], '₹'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Car-wise Breakdown', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...carData.map((car) => _buildCarCard(car)),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(String label, num value, String prefix) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        AnimatedCounter(
          value: value,
          prefix: prefix,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildCarCard(Map<String, dynamic> car) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CarExpenseDetailScreen(
                carNo: car['car_no'],
                expenses: (car['expense_entries'] as List<dynamic>).map((e) => Expense.fromJson(e)).toList(),
              ),
            ),
          ).then((_) => _fetchExpenses());
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Car: ${car['car_no']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMiniStat('Expense', car['total_expense']),
                  _buildMiniStat('Revenue', car['total_revenue']),
                  _buildMiniStat('Net Profit', car['net_profit'], color: Colors.green),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, num value, {Color? color}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        const SizedBox(height: 4),
        Text(
          '₹${value.toStringAsFixed(0)}',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color),
        ),
      ],
    );
  }

  Widget _buildDriverView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'all', label: Text('All')),
                ButtonSegment(value: 'pending', label: Text('Pending')),
                ButtonSegment(value: 'approved', label: Text('Approved')),
                ButtonSegment(value: 'rejected', label: Text('Rejected')),
              ],
              selected: {_selectedStatus},
              onSelectionChanged: (newSelection) {
                setState(() => _selectedStatus = newSelection.first);
                _fetchExpenses();
              },
            ),
          ),
        ),
        Expanded(
          child: _expenses.isEmpty
              ? const Center(child: Text('No expenses found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _expenses.length,
                  itemBuilder: (context, index) {
                    final expense = _expenses[index];
                    return _buildExpenseTile(expense);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildExpenseTile(Expense expense) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(expense.reason, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('₹${expense.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(expense.description),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(expense.date),
                  ],
                ),
                _getStatusChip(expense.status),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ExpenseFormScreen(expense: expense)),
              ).then((value) {
                if (value == true) _fetchExpenses();
              });
            } else if (value == 'delete') {
              _deleteExpense(expense.id!);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthYearPicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButton<int>(
            value: _selectedMonth,
            underline: const SizedBox(),
            items: List.generate(12, (index) => DropdownMenuItem(
              value: index + 1,
              child: Text(_months[index]),
            )),
            onChanged: (val) {
              setState(() => _selectedMonth = val!);
              _fetchExpenses();
            },
          ),
          const SizedBox(width: 8),
          DropdownButton<int>(
            value: _selectedYear,
            underline: const SizedBox(),
            items: [2025, 2026, 2027].map((y) => DropdownMenuItem(
              value: y,
              child: Text(y.toString()),
            )).toList(),
            onChanged: (val) {
              setState(() => _selectedYear = val!);
              _fetchExpenses();
            },
          ),
        ],
      ),
    );
  }

  Widget _getStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'approved':
        color = Colors.green;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class CarExpenseDetailScreen extends StatelessWidget {
  final String carNo;
  final List<Expense> expenses;

  const CarExpenseDetailScreen({super.key, required this.carNo, required this.expenses});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Expenses: $carNo'),
      ),
      body: expenses.isEmpty
          ? const Center(child: Text('No entries found for this car'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: expenses.length,
              itemBuilder: (context, index) {
                final expense = expenses[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    title: Text(expense.reason, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${expense.description}\n${expense.date}'),
                    trailing: Text('₹${expense.amount}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                  ),
                );
              },
            ),
    );
  }
}

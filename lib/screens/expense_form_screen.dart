import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/expense_model.dart';

class ExpenseFormScreen extends StatefulWidget {
  final Expense? expense;
  const ExpenseFormScreen({super.key, this.expense});

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _role = 'driver';
  List<dynamic> _cars = [];
  String? _selectedCarId;

  late TextEditingController _dateController;
  late TextEditingController _reasonController;
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(text: widget.expense?.date ?? '');
    _reasonController = TextEditingController(text: widget.expense?.reason ?? '');
    _descriptionController = TextEditingController(text: widget.expense?.description ?? '');
    _amountController = TextEditingController(text: widget.expense?.amount.toString() ?? '');
    _selectedCarId = widget.expense?.carId;
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _role = prefs.getString('user_role') ?? 'driver';
    });
    if (_role == 'admin') {
      _fetchCars();
    }
  }

  Future<void> _fetchCars() async {
    final response = await ApiService.getCars();
    if (response['success'] == true) {
      setState(() {
        _cars = response['data'] ?? [];
      });
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _reasonController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final expenseData = {
      'date': _dateController.text,
      'reason': _reasonController.text,
      'description': _descriptionController.text,
      'amount': double.parse(_amountController.text),
      'car_id': _selectedCarId,
    };

    final Map<String, dynamic> response;
    if (widget.expense == null) {
      response = await ApiService.createExpense(expenseData);
    } else {
      response = await ApiService.updateExpense(widget.expense!.id!, expenseData);
    }

    setState(() => _isLoading = false);

    if (response['success'] == true) {
      Fluttertoast.showToast(msg: widget.expense == null ? "Expense created successfully" : "Expense updated successfully");
      Navigator.pop(context, true);
    } else {
      Fluttertoast.showToast(msg: "Error: ${response['message']}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.expense == null ? 'Add Expense' : 'Edit Expense'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_role == 'admin') ...[
                      DropdownButtonFormField<String>(
                        value: _selectedCarId,
                        decoration: const InputDecoration(
                          labelText: 'Select Car (Optional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.directions_car),
                        ),
                        items: _cars.map((car) {
                          return DropdownMenuItem<String>(
                            value: car['id'].toString(),
                            child: Text("${car['name']} (${car['car_no']})"),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedCarId = val),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _dateController,
                      decoration: const InputDecoration(labelText: 'Date', border: OutlineInputBorder(), prefixIcon: Icon(Icons.calendar_today)),
                      readOnly: true,
                      onTap: _selectDate,
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _reasonController,
                      decoration: const InputDecoration(labelText: 'Reason', border: OutlineInputBorder(), prefixIcon: Icon(Icons.help_outline)),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder(), prefixIcon: Icon(Icons.description)),
                      maxLines: 3,
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Amount', border: OutlineInputBorder(), prefixText: '₹'),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _saveExpense,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF2575FC),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(widget.expense == null ? 'Create Expense' : 'Update Expense', style: const TextStyle(fontSize: 18)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/api_service.dart';
import '../models/advance_model.dart';
import '../widgets/app_background.dart';

class AdvancesScreen extends StatefulWidget {
  final Map<String, dynamic>? driver; // If null, show all advances
  const AdvancesScreen({super.key, this.driver});

  @override
  State<AdvancesScreen> createState() => _AdvancesScreenState();
}

class _AdvancesScreenState extends State<AdvancesScreen> {
  List<Advance> _advances = [];
  List<dynamic> _drivers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchAdvances(),
      _fetchDrivers(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _fetchAdvances() async {
    final response = await ApiService.getAdvances();
    if (response['success'] == true) {
      final List<dynamic> data = response['data'] ?? [];
      setState(() {
        _advances = data.map((json) => Advance.fromJson(json)).toList();
        if (widget.driver != null) {
          _advances = _advances.where((a) => a.driverId == widget.driver!['id'].toString()).toList();
        }
      });
    } else {
      Fluttertoast.showToast(msg: "Failed to load advances: ${response['message']}");
    }
  }

  Future<void> _fetchDrivers() async {
    final response = await ApiService.getUsers();
    if (response['success'] == true) {
      final List<dynamic> allUsers = response['data'] ?? [];
      setState(() {
        _drivers = allUsers.where((u) => u['role'] == 'driver').toList();
      });
    }
  }

  Future<void> _showAdvanceDialog({Advance? advance}) async {
    final isEditing = advance != null;
    final amountController = TextEditingController(text: isEditing ? advance.amount.toString() : '');
    final descController = TextEditingController(text: isEditing ? advance.description : '');
    final dateController = TextEditingController(text: isEditing ? advance.date : DateTime.now().toString().split(' ')[0]);
    
    String? selectedDriverId = isEditing ? advance.driverId : widget.driver?['id']?.toString();
    String selectedStatus = isEditing ? advance.status : 'unpaid';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Update Advance' : 'New Advance'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.driver == null || isEditing) ...[
                  DropdownButtonFormField<String>(
                    value: selectedDriverId,
                    decoration: const InputDecoration(labelText: 'Select Driver', border: OutlineInputBorder()),
                    items: _drivers.map((d) {
                      return DropdownMenuItem<String>(
                        value: d['id'].toString(),
                        child: Text(d['name'] ?? 'Unknown'),
                      );
                    }).toList(),
                    onChanged: isEditing ? null : (value) => setDialogState(() => selectedDriverId = value),
                    disabledHint: Text(_drivers.firstWhere((d) => d['id'].toString() == selectedDriverId, orElse: () => {'name': 'Unknown'})['name']),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: amountController, 
                  decoration: const InputDecoration(labelText: 'Amount (₹)', border: OutlineInputBorder()), 
                  keyboardType: TextInputType.number
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: dateController, 
                  decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController, 
                  decoration: const InputDecoration(labelText: 'Reason (Optional)', border: OutlineInputBorder()),
                  maxLines: 2,
                ),
                if (isEditing) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status', 
                      border: OutlineInputBorder(),
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                    dropdownColor: const Color(0xFF0e3a35),
                    style: const TextStyle(color: Colors.white),
                    items: const [
                      DropdownMenuItem(value: 'unpaid', child: Text('UNPAID')),
                      DropdownMenuItem(value: 'deducted', child: Text('DEDUCTED')),
                    ],
                    onChanged: (value) => setDialogState(() => selectedStatus = value!),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (amountController.text.isEmpty || selectedDriverId == null) {
                  Fluttertoast.showToast(msg: "Amount and Driver are required");
                  return;
                }
                final data = {
                  'driver_id': selectedDriverId,
                  'amount': double.tryParse(amountController.text) ?? 0.0,
                  'date': dateController.text,
                  'description': descController.text,
                  if (isEditing) 'status': selectedStatus,
                };
                Navigator.pop(context);
                setState(() => _isLoading = true);
                
                final res = isEditing 
                  ? await ApiService.updateAdvance(advance.id!, data)
                  : await ApiService.createAdvance(data);

                if (res['success'] == true) {
                  Fluttertoast.showToast(msg: isEditing ? "Updated" : "Created", backgroundColor: Colors.green);
                  await _fetchAdvances();
                  setState(() => _isLoading = false);
                } else {
                  setState(() => _isLoading = false);
                  Fluttertoast.showToast(msg: "Error: ${res['message']}", backgroundColor: Colors.red);
                }
              },
              child: Text(isEditing ? 'Update' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteAdvance(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Advance'),
        content: const Text('Are you sure you want to delete this record?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      final res = await ApiService.deleteAdvance(id);
      if (res['success'] == true) {
        Fluttertoast.showToast(msg: "Deleted", backgroundColor: Colors.green);
        await _fetchAdvances();
        setState(() => _isLoading = false);
      } else {
        setState(() => _isLoading = false);
        Fluttertoast.showToast(msg: "Error: ${res['message']}", backgroundColor: Colors.red);
      }
    }
  }

  Future<void> _updateStatus(String id, String status) async {
    setState(() => _isLoading = true);
    final res = await ApiService.updateAdvanceStatus(id, status);
    if (res['success'] == true) {
      Fluttertoast.showToast(msg: "Marked as $status", backgroundColor: Colors.blue);
      await _fetchAdvances();
      setState(() => _isLoading = false);
    } else {
      setState(() => _isLoading = false);
      Fluttertoast.showToast(msg: "Error: ${res['message']}", backgroundColor: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            widget.driver != null ? 'Advances: ${widget.driver!['name']}' : 'Salary Advances',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchInitialData),
          ],
        ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _advances.isEmpty
              ? const Center(child: Text('No salary advances found', style: TextStyle(color: Colors.white70)))
              : RefreshIndicator(
                  onRefresh: _fetchInitialData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _advances.length,
                    itemBuilder: (context, index) {
                      final advance = _advances[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        color: Colors.white.withOpacity(0.05),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Colors.white10),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('₹${advance.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blueAccent)),
                                  _buildStatusChip(advance.status),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  Text(advance.description.isEmpty ? 'No reason provided' : advance.description, style: const TextStyle(color: Colors.white)),
                                  Text('Date: ${advance.date}', style: const TextStyle(fontSize: 12, color: Colors.white54)),
                                  if (widget.driver == null) Text('Driver: ${advance.driverName ?? 'Unknown'}', style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Text(
                                      advance.status == 'unpaid' ? 'Pending Deduction' : 'Settled', 
                                      style: TextStyle(
                                        color: advance.status == 'unpaid' ? Colors.orangeAccent : Colors.white54, 
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(icon: const Icon(Icons.edit, size: 20, color: Colors.blueAccent), onPressed: () => _showAdvanceDialog(advance: advance)),
                                      IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.redAccent), onPressed: () => _deleteAdvance(advance.id!)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAdvanceDialog(),
          backgroundColor: const Color(0xFF2575FC),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Add Advance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final color = status == 'deducted' ? Colors.green : Colors.orange;
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

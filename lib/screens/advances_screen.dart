import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/api_service.dart';
import '../models/advance_model.dart';

class AdvancesScreen extends StatefulWidget {
  final Map<String, dynamic>? driver; // If null, show all advances
  const AdvancesScreen({super.key, this.driver});

  @override
  State<AdvancesScreen> createState() => _AdvancesScreenState();
}

class _AdvancesScreenState extends State<AdvancesScreen> {
  List<Advance> _advances = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAdvances();
  }

  Future<void> _fetchAdvances() async {
    setState(() => _isLoading = true);
    final response = await ApiService.getAdvances();
    if (response['success'] == true) {
      final List<dynamic> data = response['data'] ?? [];
      setState(() {
        _advances = data.map((json) => Advance.fromJson(json)).toList();
        // Filter by driver if provided
        if (widget.driver != null) {
          _advances = _advances.where((a) => a.driverId == widget.driver!['id'].toString()).toList();
        }
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      Fluttertoast.showToast(msg: "Error: ${response['message']}");
    }
  }

  Future<void> _showAdvanceDialog({Advance? advance}) async {
    final isEditing = advance != null;
    final amountController = TextEditingController(text: isEditing ? advance.amount.toString() : '');
    final descController = TextEditingController(text: isEditing ? advance.description : '');
    final dateController = TextEditingController(text: isEditing ? advance.date : DateTime.now().toString().split(' ')[0]);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Advance' : 'Create Advance for ${widget.driver?['name'] ?? 'Driver'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: amountController, decoration: const InputDecoration(labelText: 'Amount (₹)'), keyboardType: TextInputType.number),
            TextField(controller: dateController, decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)')),
            TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (amountController.text.isEmpty) return;
              final data = {
                'driver_id': isEditing ? advance.driverId : widget.driver!['id'].toString(),
                'amount': double.parse(amountController.text),
                'date': dateController.text,
                'description': descController.text,
              };
              Navigator.pop(context);
              setState(() => _isLoading = true);
              
              final res = isEditing 
                ? await ApiService.updateAdvance(advance.id!, data)
                : await ApiService.createAdvance(data);

              if (res['success'] == true) {
                Fluttertoast.showToast(msg: isEditing ? "Advance updated" : "Advance created");
                _fetchAdvances();
              } else {
                setState(() => _isLoading = false);
                Fluttertoast.showToast(msg: "Error: ${res['message']}");
              }
            },
            child: Text(isEditing ? 'Update' : 'Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAdvance(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Advance'),
        content: const Text('Are you sure you want to delete this advance entry?'),
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
        Fluttertoast.showToast(msg: "Advance deleted");
        _fetchAdvances();
      } else {
        setState(() => _isLoading = false);
        Fluttertoast.showToast(msg: "Error: ${res['message']}");
      }
    }
  }

  Future<void> _updateStatus(String id, String status) async {
    setState(() => _isLoading = true);
    final res = await ApiService.updateAdvanceStatus(id, status);
    if (res['success'] == true) {
      Fluttertoast.showToast(msg: "Status updated to $status");
      _fetchAdvances();
    } else {
      setState(() => _isLoading = false);
      Fluttertoast.showToast(msg: "Error: ${res['message']}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.driver != null ? 'Advances: ${widget.driver!['name']}' : 'All Advances'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchAdvances),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _advances.isEmpty
              ? const Center(child: Text('No advances found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _advances.length,
                  itemBuilder: (context, index) {
                    final advance = _advances[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        title: Text('₹${advance.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(advance.description),
                            Text('Date: ${advance.date}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            if (widget.driver == null) Text('Driver: ${advance.driverName ?? 'Unknown'}', style: const TextStyle(color: Colors.blue)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildStatusChip(advance.status),
                                if (advance.status == 'unpaid')
                                  TextButton(
                                    onPressed: () => _updateStatus(advance.id!, 'deducted'),
                                    child: const Text('Mark Paid', style: TextStyle(fontSize: 10)),
                                  ),
                              ],
                            ),
                            PopupMenuButton<String>(
                              onSelected: (val) {
                                if (val == 'edit') {
                                  _showAdvanceDialog(advance: advance);
                                } else if (val == 'delete') {
                                  _deleteAdvance(advance.id!);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: widget.driver != null
          ? FloatingActionButton(
              onPressed: () => _showAdvanceDialog(),
              backgroundColor: const Color(0xFF2575FC),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
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

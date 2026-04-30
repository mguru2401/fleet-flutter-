import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/trip_model.dart';

class TripFormScreen extends StatefulWidget {
  final Trip? trip;
  const TripFormScreen({super.key, this.trip});

  @override
  State<TripFormScreen> createState() => _TripFormScreenState();
}

class _TripFormScreenState extends State<TripFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late TextEditingController _dateController;
  late TextEditingController _timeController;
  late TextEditingController _startKmController;
  late TextEditingController _endKmController;
  late TextEditingController _dropLocationController;
  late TextEditingController _mileageController;
  late TextEditingController _tripRateController;
  String _category = 'ola';

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(text: widget.trip?.pickUpDate ?? '');
    _timeController = TextEditingController(text: widget.trip?.pickUpTime ?? '');
    _startKmController = TextEditingController(text: widget.trip?.startKm.toString() ?? '');
    _endKmController = TextEditingController(text: widget.trip?.endKm.toString() ?? '');
    _dropLocationController = TextEditingController(text: widget.trip?.dropLocation ?? '');
    _mileageController = TextEditingController(text: widget.trip?.mileage.toString() ?? '');
    _tripRateController = TextEditingController(text: widget.trip?.tripRate.toString() ?? '');
    if (widget.trip != null) {
      _category = widget.trip!.category;
    }

    // Auto-calculate mileage when start or end km changes
    _startKmController.addListener(_calculateMileage);
    _endKmController.addListener(_calculateMileage);
  }

  void _calculateMileage() {
    final start = double.tryParse(_startKmController.text) ?? 0;
    final end = double.tryParse(_endKmController.text) ?? 0;
    if (end >= start) {
      setState(() {
        _mileageController.text = (end - start).toStringAsFixed(2);
      });
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _startKmController.dispose();
    _endKmController.dispose();
    _dropLocationController.dispose();
    _mileageController.dispose();
    _tripRateController.dispose();
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

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _timeController.text = "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00";
      });
    }
  }

  Future<void> _saveTrip() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final driverId = prefs.getString('driver_id');

    final tripData = {
      'pick_up_date': _dateController.text,
      'pick_up_time': _timeController.text,
      'start_km': double.parse(_startKmController.text),
      'end_km': double.parse(_endKmController.text),
      'drop_location': _dropLocationController.text,
      'mileage': double.parse(_mileageController.text),
      'trip_rate': double.parse(_tripRateController.text),
      'category': _category,
      if (driverId != null) 'driver_id': driverId,
    };

    final Map<String, dynamic> response;
    if (widget.trip == null) {
      response = await ApiService.createTrip(tripData);
    } else {
      response = await ApiService.updateTrip(widget.trip!.id!, tripData);
    }

    setState(() => _isLoading = false);

    if (response['success'] == true) {
      Fluttertoast.showToast(msg: widget.trip == null ? "Trip created successfully" : "Trip updated successfully");
      Navigator.pop(context, true);
    } else {
      Fluttertoast.showToast(msg: "Error: ${response['message']}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.trip == null ? 'Add New Trip' : 'Edit Trip'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
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
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _dateController,
                            decoration: const InputDecoration(labelText: 'Pick Up Date', border: OutlineInputBorder(), prefixIcon: Icon(Icons.calendar_today)),
                            readOnly: true,
                            onTap: _selectDate,
                            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _timeController,
                            decoration: const InputDecoration(labelText: 'Pick Up Time', border: OutlineInputBorder(), prefixIcon: Icon(Icons.access_time)),
                            readOnly: true,
                            onTap: _selectTime,
                            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _dropLocationController,
                      decoration: const InputDecoration(labelText: 'Drop Location', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on)),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _startKmController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Start KM', border: OutlineInputBorder()),
                            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _endKmController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'End KM', border: OutlineInputBorder()),
                            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _mileageController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Mileage', border: OutlineInputBorder(), filled: true, fillColor: Color(0xFFF5F5F5)),
                            readOnly: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _tripRateController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Trip Rate', border: OutlineInputBorder(), prefixText: '₹'),
                            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _category,
                      decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                      items: ['amazon', 'ola', 'uber', 'it', 'other'].map((c) => DropdownMenuItem(value: c, child: Text(c.toUpperCase()))).toList(),
                      onChanged: (v) => setState(() => _category = v!),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _saveTrip,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF2575FC),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(widget.trip == null ? 'Create Trip' : 'Update Trip', style: const TextStyle(fontSize: 18)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

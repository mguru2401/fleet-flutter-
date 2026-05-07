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
  String _role = 'driver';
  List<dynamic> _cars = [];
  List<dynamic> _categories = [];
  String? _selectedCarId;

  late TextEditingController _dateController;
  late TextEditingController _timeController;
  late TextEditingController _startKmController;
  late TextEditingController _endKmController;
  late TextEditingController _dropLocationController;
  late TextEditingController _mileageController;
  late TextEditingController _tripRateController;
  late TextEditingController _commissionController;
  String? _category;

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
    _commissionController = TextEditingController(text: widget.trip?.commission?.toString() ?? '');
    _selectedCarId = widget.trip?.carId;
    _category = widget.trip?.category;

    _startKmController.addListener(_calculateMileage);
    _endKmController.addListener(_calculateMileage);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadUserRole();
    await _fetchCategories();
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

  Future<void> _fetchCategories() async {
    final response = await ApiService.getCategories();
    if (response['success'] == true) {
      setState(() {
        _categories = response['data'] ?? [];
        // If creating new trip and no category selected, default to first one if available
        if (_category == null && _categories.isNotEmpty) {
          _category = _categories[0]['name'];
        }
      });
    }
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
    _commissionController.dispose();
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
      'category': _category ?? 'other',
      if (_commissionController.text.isNotEmpty) 'commission': double.parse(_commissionController.text),
      if (driverId != null) 'driver_id': driverId,
      'car_id': _selectedCarId,
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
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: _categories.map((c) {
                        return DropdownMenuItem<String>(
                          value: c['name'].toString(),
                          child: Text(c['name'].toString().toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _category = v),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    if (_category?.toLowerCase() == 'uber' || _category?.toLowerCase() == 'ola') ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _commissionController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Commission (Uber/Ola Only)',
                          border: OutlineInputBorder(),
                          prefixText: '₹',
                        ),
                        validator: (v) {
                          if ((_category?.toLowerCase() == 'uber' || _category?.toLowerCase() == 'ola') && (v == null || v.isEmpty)) {
                            return 'Commission is required for Uber/Ola';
                          }
                          return null;
                        },
                      ),
                    ],
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

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/api_service.dart';
import 'advances_screen.dart';
import '../widgets/app_background.dart';

class DriversScreen extends StatefulWidget {
  final bool hideAppBar;
  const DriversScreen({super.key, this.hideAppBar = false});

  @override
  State<DriversScreen> createState() => _DriversScreenState();
}

class _DriversScreenState extends State<DriversScreen> {
  List<dynamic> _drivers = [];
  List<dynamic> _cars = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchDrivers(),
      _fetchCars(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _fetchDrivers() async {
    final response = await ApiService.getUsers();
    if (response['success'] == true) {
      final List<dynamic> allUsers = response['data'] ?? [];
      setState(() {
        _drivers = allUsers.where((u) => u['role'] == 'driver').toList();
      });
    } else {
      Fluttertoast.showToast(msg: "Failed to load drivers: ${response['message']}");
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

  Future<void> _deleteDriver(String id) async {
    final response = await ApiService.deleteUser(id);
    if (response['success'] == true) {
      Fluttertoast.showToast(msg: "Driver deleted successfully", backgroundColor: Colors.green);
      _fetchDrivers();
    } else {
      Fluttertoast.showToast(msg: "Delete failed: ${response['message']}", backgroundColor: Colors.red);
    }
  }

  void _showDriverDialog({Map<String, dynamic>? driver}) {
    final isEditing = driver != null;
    final nameController = TextEditingController(text: driver?['name'] ?? '');
    final emailController = TextEditingController(text: driver?['email'] ?? '');
    final mobileController = TextEditingController(text: driver?['mobile_no'] ?? '');
    final employeeNoController = TextEditingController(text: driver?['employee_no'] ?? '');
    final locationController = TextEditingController(text: driver?['location'] ?? '');
    final revenueController = TextEditingController(text: driver?['revenue_per_day']?.toString() ?? '');
    final passwordController = TextEditingController();
    final usernameController = TextEditingController(text: driver?['username'] ?? '');
    
    String? selectedCarId = driver?['car_id'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Update Driver' : 'Add Driver'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
                TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
                TextField(controller: usernameController, decoration: const InputDecoration(labelText: 'Username')),
                if (!isEditing) 
                  TextField(controller: passwordController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
                TextField(controller: mobileController, decoration: const InputDecoration(labelText: 'Mobile No')),
                TextField(controller: employeeNoController, decoration: const InputDecoration(labelText: 'Employee No')),
                TextField(controller: locationController, decoration: const InputDecoration(labelText: 'Location')),
                TextField(
                  controller: revenueController, 
                  decoration: const InputDecoration(labelText: 'Revenue Per Day (Optional)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCarId,
                  decoration: const InputDecoration(labelText: 'Assign Car', border: OutlineInputBorder()),
                  items: _cars.map((car) {
                    return DropdownMenuItem<String>(
                      value: car['id'].toString(),
                      child: Text("${car['name']} (${car['car_no']})"),
                    );
                  }).toList(),
                  onChanged: (value) => setDialogState(() => selectedCarId = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final userData = {
                  'name': nameController.text,
                  'email': emailController.text,
                  'username': usernameController.text,
                  'role': 'driver',
                  'mobile_no': mobileController.text,
                  'employee_no': employeeNoController.text,
                  'location': locationController.text,
                  'car_id': selectedCarId,
                  'revenue_per_day': revenueController.text.isNotEmpty 
                      ? double.tryParse(revenueController.text) 
                      : null,
                };
                if (!isEditing) userData['password'] = passwordController.text;

                Navigator.pop(context);
                setState(() => _isLoading = true);

                final response = isEditing 
                  ? await ApiService.updateUser(driver['id'].toString(), userData)
                  : await ApiService.createUser(userData);

                if (response['success'] == true) {
                  Fluttertoast.showToast(msg: isEditing ? "Driver updated" : "Driver added", backgroundColor: Colors.green);
                  _fetchDrivers();
                } else {
                  setState(() => _isLoading = false);
                  Fluttertoast.showToast(msg: "Error: ${response['message']}", backgroundColor: Colors.red);
                }
              },
              child: Text(isEditing ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content = _isLoading 
      ? const Center(child: CircularProgressIndicator())
      : _drivers.isEmpty
        ? const Center(child: Text("No drivers found", style: TextStyle(color: Colors.white70)))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _drivers.length,
            itemBuilder: (context, index) {
              final driver = _drivers[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: Colors.white.withOpacity(0.05),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.white10),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blueAccent.withOpacity(0.1),
                    child: Text(driver['name']?[0] ?? 'D', style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(driver['name'] ?? 'No Name', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: Text(
                    "Emp: ${driver['employee_no'] ?? 'N/A'} | Car: ${driver['car_no'] ?? 'N/A'}\n"
                    "Revenue: ₹${driver['revenue_per_day'] ?? '0'}/day\n"
                    "Loc: ${driver['location'] ?? 'N/A'}",
                    style: const TextStyle(color: Colors.white70),
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.payments_outlined, color: Colors.greenAccent),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => AdvancesScreen(driver: driver)),
                          );
                        },
                      ),
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blueAccent), onPressed: () => _showDriverDialog(driver: driver)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => _deleteDriver(driver['id'].toString())),
                    ],
                  ),
                ),
              );
            },
          );

    if (widget.hideAppBar) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: content,
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showDriverDialog(),
          backgroundColor: const Color(0xFF2575FC),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      );
    }

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Drivers Management', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchInitialData),
          ],
        ),
        body: content,
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showDriverDialog(),
          backgroundColor: const Color(0xFF2575FC),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}

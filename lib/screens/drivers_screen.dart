import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/api_service.dart';
import 'advances_screen.dart';

class DriversScreen extends StatefulWidget {
  const DriversScreen({super.key});

  @override
  State<DriversScreen> createState() => _DriversScreenState();
}

class _DriversScreenState extends State<DriversScreen> {
  List<dynamic> _drivers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDrivers();
  }

  Future<void> _fetchDrivers() async {
    setState(() => _isLoading = true);
    final response = await ApiService.getUsers();
    if (response['success'] == true) {
      final List<dynamic> allUsers = response['data'] ?? [];
      setState(() {
        _drivers = allUsers.where((u) => u['role'] != 'admin').toList();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      Fluttertoast.showToast(msg: "Failed to load drivers: ${response['message']}");
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
    final idController = TextEditingController(text: driver?['id']?.toString() ?? '');
    final nameController = TextEditingController(text: driver?['name'] ?? '');
    final emailController = TextEditingController(text: driver?['email'] ?? '');
    final mobileController = TextEditingController(text: driver?['mobile_no'] ?? '');
    final carController = TextEditingController(text: driver?['car_no'] ?? '');
    final locationController = TextEditingController(text: driver?['location'] ?? '');
    final passwordController = TextEditingController();
    final usernameController = TextEditingController(text: driver?['username'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
              TextField(controller: carController, decoration: const InputDecoration(labelText: 'Car No')),
              TextField(controller: locationController, decoration: const InputDecoration(labelText: 'Location')),
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
                'car_no': carController.text,
                'location': locationController.text,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drivers Management', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchDrivers),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _drivers.isEmpty
          ? const Center(child: Text("No drivers found"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _drivers.length,
              itemBuilder: (context, index) {
                final driver = _drivers[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Text(driver['name']?[0] ?? 'D'),
                    ),
                    title: Text(driver['name'] ?? 'No Name', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${driver['email']}\nCar: ${driver['car_no'] ?? 'N/A'}"),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.payments_outlined, color: Colors.green),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => AdvancesScreen(driver: driver)),
                            );
                          },
                        ),
                        IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showDriverDialog(driver: driver)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteDriver(driver['id'].toString())),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDriverDialog(),
        backgroundColor: const Color(0xFF2575FC),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

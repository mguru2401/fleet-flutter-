import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/api_service.dart';

class MetaDataScreen extends StatefulWidget {
  const MetaDataScreen({super.key});

  @override
  State<MetaDataScreen> createState() => _MetaDataScreenState();
}

class _MetaDataScreenState extends State<MetaDataScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Meta Data'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.directions_car), text: 'Cars'),
              Tab(icon: Icon(Icons.category), text: 'Categories'),
            ],
            labelColor: Color(0xFF2575FC),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF2575FC),
          ),
        ),
        body: TabBarView(
          children: [
            CarsTab(),
            CategoriesTab(),
          ],
        ),
      ),
    );
  }
}

class CarsTab extends StatefulWidget {
  const CarsTab({super.key});

  @override
  State<CarsTab> createState() => _CarsTabState();
}

class _CarsTabState extends State<CarsTab> {
  List<dynamic> _cars = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCars();
  }

  Future<void> _fetchCars() async {
    setState(() => _isLoading = true);
    final response = await ApiService.getCars();
    if (response['success'] == true) {
      setState(() {
        _cars = response['data'] ?? [];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      Fluttertoast.showToast(msg: "Error: ${response['message']}");
    }
  }

  void _showCarDialog({Map<String, dynamic>? car}) {
    final bool isEditing = car != null;
    final nameController = TextEditingController(text: car?['name']);
    final carNoController = TextEditingController(text: car?['car_no']);
    final modelController = TextEditingController(text: car?['model']);
    final yearController = TextEditingController(text: car?['year']?.toString() ?? DateTime.now().year.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Car' : 'Add New Car'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Car Name (e.g. Toyota Innova)'),
              ),
              TextField(
                controller: carNoController,
                decoration: const InputDecoration(labelText: 'Car Number (e.g. MH-01-AB-1234)'),
              ),
              TextField(
                controller: modelController,
                decoration: const InputDecoration(labelText: 'Model (e.g. Innova Crysta)'),
              ),
              TextField(
                controller: yearController,
                decoration: const InputDecoration(labelText: 'Year'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty || carNoController.text.isEmpty) {
                Fluttertoast.showToast(msg: "Name and Car No are required");
                return;
              }

              final carData = {
                "name": nameController.text,
                "car_no": carNoController.text,
                "model": modelController.text,
                "year": int.tryParse(yearController.text) ?? DateTime.now().year,
              };

              Navigator.pop(context);
              setState(() => _isLoading = true);

              final response = isEditing 
                  ? await ApiService.updateCar(car!['id'].toString(), carData)
                  : await ApiService.createCar(carData);

              if (response['success'] == true) {
                Fluttertoast.showToast(msg: isEditing ? "Car updated successfully" : "Car added successfully");
                _fetchCars();
              } else {
                setState(() => _isLoading = false);
                Fluttertoast.showToast(msg: "Error: ${response['message']}");
              }
            },
            child: Text(isEditing ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String carId, String carName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Car'),
        content: Text('Are you sure you want to delete $carName?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              final response = await ApiService.deleteCar(carId);
              if (response['success'] == true) {
                Fluttertoast.showToast(msg: "Car deleted successfully");
                _fetchCars();
              } else {
                setState(() => _isLoading = false);
                Fluttertoast.showToast(msg: "Error: ${response['message']}");
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: _cars.isEmpty
          ? const Center(child: Text('No cars found'))
          : RefreshIndicator(
              onRefresh: _fetchCars,
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _cars.length,
                itemBuilder: (context, index) {
                  final car = _cars[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFF2575FC),
                        child: Icon(Icons.directions_car, color: Colors.white),
                      ),
                      title: Text(car['name'] ?? 'Unknown Car', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("${car['model'] ?? ''} | ${car['car_no'] ?? ''}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showCarDialog(car: car),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _confirmDelete(car['id'].toString(), car['name'] ?? 'this car'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCarDialog(),
        backgroundColor: const Color(0xFF2575FC),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class CategoriesTab extends StatefulWidget {
  const CategoriesTab({super.key});

  @override
  State<CategoriesTab> createState() => _CategoriesTabState();
}

class _CategoriesTabState extends State<CategoriesTab> {
  List<dynamic> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() => _isLoading = true);
    final response = await ApiService.getCategories();
    if (response['success'] == true) {
      setState(() {
        _categories = response['data'] ?? [];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      Fluttertoast.showToast(msg: "Error: ${response['message']}");
    }
  }

  void _showCategoryDialog({Map<String, dynamic>? category}) {
    final bool isEditing = category != null;
    final nameController = TextEditingController(text: category?['name']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Category' : 'Add New Category'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Category Name (e.g. Amazon, Fuel)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                Fluttertoast.showToast(msg: "Name is required");
                return;
              }

              final categoryData = {"name": nameController.text};

              Navigator.pop(context);
              setState(() => _isLoading = true);

              final response = isEditing 
                  ? await ApiService.updateCategory(category!['id'].toString(), categoryData)
                  : await ApiService.createCategory(categoryData);

              if (response['success'] == true) {
                Fluttertoast.showToast(msg: isEditing ? "Category updated successfully" : "Category added successfully");
                _fetchCategories();
              } else {
                setState(() => _isLoading = false);
                Fluttertoast.showToast(msg: "Error: ${response['message']}");
              }
            },
            child: Text(isEditing ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String categoryId, String categoryName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete $categoryName?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              final response = await ApiService.deleteCategory(categoryId);
              if (response['success'] == true) {
                Fluttertoast.showToast(msg: "Category deleted successfully");
                _fetchCategories();
              } else {
                setState(() => _isLoading = false);
                Fluttertoast.showToast(msg: "Error: ${response['message']}");
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: _categories.isEmpty
          ? const Center(child: Text('No categories found'))
          : RefreshIndicator(
              onRefresh: _fetchCategories,
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFF2575FC),
                        child: Icon(Icons.category, color: Colors.white),
                      ),
                      title: Text(category['name'] ?? 'Unknown Category', style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showCategoryDialog(category: category),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _confirmDelete(category['id'].toString(), category['name'] ?? 'this category'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(),
        backgroundColor: const Color(0xFF2575FC),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

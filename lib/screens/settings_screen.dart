import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/api_service.dart';
import 'meta_data_screen.dart';

class SettingsScreen extends StatefulWidget {
  final String role;
  const SettingsScreen({super.key, required this.role});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isFetchingSalary = false;

  Future<void> _showDesiredSalaryDialog(BuildContext context) async {
    setState(() => _isFetchingSalary = true);
    
    String initialSalary = '';
    final profileResponse = await ApiService.getProfile();
    if (profileResponse['success'] == true) {
      initialSalary = profileResponse['data']['desired_salary']?.toString() ?? '';
    }
    
    setState(() => _isFetchingSalary = false);

    if (!mounted) return;

    final TextEditingController salaryController = TextEditingController(text: initialSalary);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Desired Salary'),
        content: TextField(
          controller: salaryController,
          decoration: const InputDecoration(
            labelText: 'Monthly Salary Target',
            prefixText: '₹ ',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (salaryController.text.isEmpty) return;
              final salary = double.tryParse(salaryController.text);
              if (salary == null) {
                Fluttertoast.showToast(msg: "Please enter a valid number");
                return;
              }
              final response = await ApiService.setDesiredSalary(salary);
              if (response['success'] == true) {
                Fluttertoast.showToast(msg: "Target salary set successfully");
                Navigator.pop(context);
              } else {
                Fluttertoast.showToast(msg: "Error: ${response['message']}");
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2575FC)),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (widget.role == 'admin') ...[
              _buildSettingItem(
                context,
                icon: Icons.data_usage,
                title: 'Meta Data',
                subtitle: 'Manage Cars and Working Days',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MetaDataScreen()),
                  );
                },
              ),
              const Divider(),
            ],
            if (widget.role == 'driver') ...[
              _buildSettingItem(
                context,
                icon: Icons.account_balance_wallet,
                title: 'Desired Salary',
                subtitle: 'Set your monthly income target',
                onTap: () => _showDesiredSalaryDialog(context),
              ),
              const Divider(),
            ],
            _buildSettingItem(
              context,
              icon: Icons.person,
              title: 'Profile Settings',
              subtitle: 'Manage your personal information',
              onTap: () {
                // Not implemented yet
              },
            ),
          ],
        ),
        if (_isFetchingSalary)
          Container(
            color: Colors.black12,
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
// ... (rest of the method remains same)
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF2575FC).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF2575FC)),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

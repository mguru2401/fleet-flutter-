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
  bool _showMetaData = false;

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

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isFetchingSalary = true);
      final response = await ApiService.logout();
      if (response['success'] == true) {
        Fluttertoast.showToast(msg: "Logged out successfully");
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        }
      } else {
        setState(() => _isFetchingSalary = false);
        Fluttertoast.showToast(msg: "Logout failed: ${response['message']}");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showMetaData) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: InkWell(
              onTap: () => setState(() => _showMetaData = false),
              child: Row(
                children: [
                  const Icon(Icons.arrow_back_ios, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  const Text('Back to Settings', style: TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
            ),
          ),
          const Expanded(child: MetaDataScreen(hideBackground: true)),
        ],
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (widget.role == 'admin') ...[
                _buildSettingItem(
                  context,
                  icon: Icons.data_usage,
                  title: 'Meta Data',
                  subtitle: 'Manage Cars and Categories',
                  onTap: () => setState(() => _showMetaData = true),
                ),
                const Divider(color: Colors.white24),
              ],
              if (widget.role == 'driver') ...[
                _buildSettingItem(
                  context,
                  icon: Icons.account_balance_wallet,
                  title: 'Desired Salary',
                  subtitle: 'Set your monthly income target',
                  onTap: () => _showDesiredSalaryDialog(context),
                ),
                const Divider(color: Colors.white24),
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
              const Divider(color: Colors.white24),
              _buildSettingItem(
                context,
                icon: Icons.logout,
                title: 'Logout',
                subtitle: 'Sign out of your account',
                onTap: () => _handleLogout(context),
                color: Colors.redAccent,
              ),
            ],
          ),
          if (_isFetchingSalary)
            Container(
              color: Colors.black12,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    final themeColor = color ?? const Color(0xFF2575FC);
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: themeColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: themeColor),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold, color: color ?? Colors.white),
      ),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white54),
      onTap: onTap,
    );
  }
}

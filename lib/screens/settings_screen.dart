import 'package:flutter/material.dart';
import 'meta_data_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
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

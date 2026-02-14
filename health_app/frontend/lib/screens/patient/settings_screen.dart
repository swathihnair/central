import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/screens/auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await ApiService.getUserData();
      if (mounted) {
        setState(() {
          _userData = userData;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
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
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ApiService.clearAuth();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Settings',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),

        // Profile Section
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  _userData?['full_name']?.substring(0, 1).toUpperCase() ?? 'P',
                  style: TextStyle(
                    fontSize: 40,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _userData?['full_name'] ?? 'User',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _userData?['email'] ?? '',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _userData?['role']?.toUpperCase() ?? 'PATIENT',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Account Settings
        _buildSectionHeader('Account'),
        _buildSettingsTile(
          icon: Icons.person_outline,
          title: 'Edit Profile',
          subtitle: 'Update your personal information',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile editing coming soon')),
            );
          },
        ),
        _buildSettingsTile(
          icon: Icons.lock_outline,
          title: 'Change Password',
          subtitle: 'Update your password',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Password change coming soon')),
            );
          },
        ),

        const SizedBox(height: 24),

        // Preferences
        _buildSectionHeader('Preferences'),
        _buildSettingsTile(
          icon: Icons.notifications_none,
          title: 'Notifications',
          subtitle: 'Manage notification preferences',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notification settings coming soon')),
            );
          },
        ),
        _buildSettingsTile(
          icon: Icons.language_outlined,
          title: 'Language',
          subtitle: 'English',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Language selection coming soon')),
            );
          },
        ),
        _buildSettingsTile(
          icon: Icons.dark_mode_outlined,
          title: 'Theme',
          subtitle: 'Light mode',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Theme selection coming soon')),
            );
          },
        ),

        const SizedBox(height: 24),

        // About
        _buildSectionHeader('About'),
        _buildSettingsTile(
          icon: Icons.info_outline,
          title: 'About',
          subtitle: 'Version 1.0.0',
          onTap: () {
            showAboutDialog(
              context: context,
              applicationName: 'Health App',
              applicationVersion: '1.0.0',
              applicationIcon: const Icon(Icons.health_and_safety, size: 48),
              children: [
                const Text('A comprehensive healthcare management system'),
              ],
            );
          },
        ),
        _buildSettingsTile(
          icon: Icons.privacy_tip_outlined,
          title: 'Privacy Policy',
          subtitle: 'Read our privacy policy',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Privacy policy coming soon')),
            );
          },
        ),
        _buildSettingsTile(
          icon: Icons.description_outlined,
          title: 'Terms of Service',
          subtitle: 'Read our terms',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Terms of service coming soon')),
            );
          },
        ),

        const SizedBox(height: 24),

        // Logout Button
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: ListTile(
            leading: Icon(Icons.logout, color: Colors.red.shade700),
            title: Text(
              'Logout',
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: _logout,
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

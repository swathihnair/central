import 'package:flutter/material.dart';
import 'package:frontend/screens/doctor/doctor_home.dart';
import 'package:frontend/screens/doctor/doctor_appointments.dart';
import 'package:frontend/screens/doctor/doctor_patients.dart';
import 'package:frontend/screens/patient/settings_screen.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DoctorHome(),
    const DoctorAppointments(),
    const DoctorPatients(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Doctor Portal", style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                "D",
                style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
              ),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 600) {
            // Desktop/Tablet Layout - Sidebar
            return Row(
              children: [
                NavigationRail(
                  extended: constraints.maxWidth > 900,
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (int index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  labelType: constraints.maxWidth > 900
                      ? NavigationRailLabelType.none
                      : NavigationRailLabelType.all,
                  leading: const SizedBox(height: 8),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard),
                      label: Text('Dashboard'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.calendar_today_outlined),
                      selectedIcon: Icon(Icons.calendar_today),
                      label: Text('Appointments'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.people_outline),
                      selectedIcon: Icon(Icons.people),
                      label: Text('Patients'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings),
                      label: Text('Settings'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(
                  child: Container(
                    color: Colors.grey.shade50,
                    child: _pages[_selectedIndex],
                  ),
                ),
              ],
            );
          } else {
            // Mobile Layout - Bottom Bar
            return Container(
              color: Colors.grey.shade50,
              child: _pages[_selectedIndex],
            );
          }
        },
      ),
      bottomNavigationBar: MediaQuery.of(context).size.width <= 600
          ? NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.calendar_today_outlined),
                  selectedIcon: Icon(Icons.calendar_today),
                  label: 'Appointments',
                ),
                NavigationDestination(
                  icon: Icon(Icons.people_outline),
                  selectedIcon: Icon(Icons.people),
                  label: 'Patients',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            )
          : null,
    );
  }
}

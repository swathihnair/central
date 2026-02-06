import 'package:flutter/material.dart';
import 'package:frontend/screens/patient/patient_home.dart';
import 'package:frontend/screens/patient/doctor_ai_screen.dart';
import 'package:frontend/screens/patient/reports_screen.dart';
import 'package:frontend/screens/patient/appointments_screen.dart';
import 'package:frontend/screens/patient/settings_screen.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  int _selectedIndex = 0;




  final List<Widget> _pages = [
    const PatientHome(),
    const AppointmentsScreen(),
    const DoctorAIScreen(),
    const ReportsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Health Portal", style: TextStyle(fontWeight: FontWeight.w600)),
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
                "P", 
                style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer)
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
                  labelType: constraints.maxWidth > 900 ? NavigationRailLabelType.none : NavigationRailLabelType.all,
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
                      icon: Icon(Icons.smart_toy_outlined),
                      selectedIcon: Icon(Icons.smart_toy),
                      label: Text('Doctor AI'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.folder_shared_outlined),
                      selectedIcon: Icon(Icons.folder_shared),
                      label: Text('Reports'),
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
                    child: _pages[_selectedIndex]
                  ),
                ),
              ],
            );
          } else {
            // Mobile Layout - Bottom Bar
            return Container(
              color: Colors.grey.shade50,
              child: _pages[_selectedIndex]
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
                  label: 'Appts',
                ),
                NavigationDestination(
                  icon: Icon(Icons.smart_toy_outlined),
                  selectedIcon: Icon(Icons.smart_toy),
                  label: 'AI',
                ),
                NavigationDestination(
                  icon: Icon(Icons.folder_shared_outlined),
                  selectedIcon: Icon(Icons.folder_shared),
                  label: 'Reports',
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

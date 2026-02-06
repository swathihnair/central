import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/screens/auth/login_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  List<dynamic> _patients = [];
  List<dynamic> _doctors = [];
  List<dynamic> _appointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        ApiService.getPatients(),
        ApiService.getDoctors(),
      ]);
      
      if (mounted) {
        setState(() {
          _patients = results[0];
          _doctors = results[1];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'logout') {
                await ApiService.clearAuth();
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  "A",
                  style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            extended: MediaQuery.of(context).size.width > 900,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() => _selectedIndex = index);
            },
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Overview'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: Text('Patients'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.medical_services_outlined),
                selectedIcon: Icon(Icons.medical_services),
                label: Text('Doctors'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.upload_file_outlined),
                selectedIcon: Icon(Icons.upload_file),
                label: Text('Upload Reports'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: Container(
              color: Colors.grey.shade50,
              child: _buildPage(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage() {
    if (_isLoading && _selectedIndex != 3) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (_selectedIndex) {
      case 0:
        return _buildOverview();
      case 1:
        return _buildPatientsList();
      case 2:
        return _buildDoctorsList();
      case 3:
        return _buildUploadReports();
      default:
        return const Center(child: Text('Page not found'));
    }
  }

  Widget _buildOverview() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Dashboard Overview',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 600) {
              return Column(
                children: [
                  _buildStatCard('Total Patients', _patients.length.toString(), Icons.people, Colors.blue),
                  const SizedBox(height: 16),
                  _buildStatCard('Total Doctors', _doctors.length.toString(), Icons.medical_services, Colors.green),
                  const SizedBox(height: 16),
                  _buildStatCard('Appointments', _appointments.length.toString(), Icons.calendar_today, Colors.orange),
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: _buildStatCard('Total Patients', _patients.length.toString(), Icons.people, Colors.blue)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard('Total Doctors', _doctors.length.toString(), Icons.medical_services, Colors.green)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard('Appointments', _appointments.length.toString(), Icons.calendar_today, Colors.orange)),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientsList() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Patients',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        ..._patients.map((patient) => _buildUserCard(patient, Colors.blue)),
      ],
    );
  }

  Widget _buildDoctorsList() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Doctors',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        ..._doctors.map((doctor) => _buildUserCard(doctor, Colors.green)),
      ],
    );
  }

  Widget _buildUserCard(dynamic user, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(Icons.person, color: color),
        ),
        title: Text(
          user['full_name'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(user['email']),
            if (user['specialization'] != null) ...[
              const SizedBox(height: 2),
              Text('Specialization: ${user['specialization']}'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUploadReports() {
    String? selectedPatientId;
    String title = '';
    String department = 'General';
    PlatformFile? selectedFile;

    return StatefulBuilder(
      builder: (context, setPageState) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Upload Patient Report',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Select Patient',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedPatientId,
                  items: _patients.map<DropdownMenuItem<String>>((patient) {
                    return DropdownMenuItem<String>(
                      value: patient['id'],
                      child: Text(patient['full_name']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setPageState(() => selectedPatientId = value);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Report Title',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => title = value,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Department',
                    border: OutlineInputBorder(),
                  ),
                  value: department,
                  items: const [
                    DropdownMenuItem(value: 'General', child: Text('General')),
                    DropdownMenuItem(value: 'Cardiology', child: Text('Cardiology')),
                    DropdownMenuItem(value: 'Pathology', child: Text('Pathology')),
                    DropdownMenuItem(value: 'Radiology', child: Text('Radiology')),
                    DropdownMenuItem(value: 'Neurology', child: Text('Neurology')),
                  ],
                  onChanged: (value) {
                    setPageState(() => department = value!);
                  },
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                    );
                    if (result != null) {
                      setPageState(() => selectedFile = result.files.first);
                    }
                  },
                  icon: const Icon(Icons.attach_file),
                  label: Text(selectedFile?.name ?? 'Select File'),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedPatientId == null || title.isEmpty || selectedFile == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all fields')),
                      );
                      return;
                    }

                    try {
                      final token = await ApiService.getToken();
                      final request = http.MultipartRequest(
                        'POST',
                        Uri.parse('${ApiService.baseUrl}/reports/upload'),
                      );
                      
                      request.headers['Authorization'] = 'Bearer $token';
                      request.fields['patient_id'] = selectedPatientId!;
                      request.fields['title'] = title;
                      request.fields['department'] = department;
                      
                      request.files.add(
                        http.MultipartFile.fromBytes(
                          'file',
                          selectedFile!.bytes!,
                          filename: selectedFile!.name,
                        ),
                      );

                      final response = await request.send();
                      
                      if (response.statusCode == 200) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Report uploaded successfully')),
                        );
                        setPageState(() {
                          selectedPatientId = null;
                          selectedFile = null;
                        });
                      } else {
                        throw Exception('Upload failed');
                      }
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Upload failed: $e')),
                      );
                    }
                  },
                  child: const Text('Upload Report'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

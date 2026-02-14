import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/screens/auth/login_screen.dart';
import 'package:frontend/screens/admin/patient_details_screen.dart';
import 'package:frontend/screens/admin/rfid_scanner_screen.dart';

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
  String? _selectedPatientIdForUpload;

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
        ApiService.getAllAppointments(),
      ]);
      
      if (mounted) {
        setState(() {
          _patients = results[0];
          _doctors = results[1];
          _appointments = results[2];
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
                icon: Icon(Icons.calendar_today_outlined),
                selectedIcon: Icon(Icons.calendar_today),
                label: Text('Appointments'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.upload_file_outlined),
                selectedIcon: Icon(Icons.upload_file),
                label: Text('Upload Reports'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.nfc_outlined),
                selectedIcon: Icon(Icons.nfc),
                label: Text('RFID Scanner'),
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
    if (_isLoading && _selectedIndex != 4 && _selectedIndex != 5) {
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
        return _buildAppointmentsList();
      case 4:
        return _buildUploadReports();
      case 5:
        return const RFIDScannerScreen();
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
            color: Colors.black.withValues(alpha: 0.02),
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
                  color: color.withValues(alpha: 0.1),
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

  Widget _buildAppointmentsList() {
    final pendingAppointments = _appointments.where((apt) => apt['status'] == 'pending').toList();
    
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Appointments',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (_appointments.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(48.0),
              child: Column(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No appointments found'),
                ],
              ),
            ),
          )
        else ...[
          if (pendingAppointments.isNotEmpty) ...[
            Text(
              'Pending Approvals (${pendingAppointments.length})',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 16),
            ...pendingAppointments.map((apt) => _buildAppointmentCard(apt)),
            const SizedBox(height: 24),
          ],
          Text(
            'All Appointments',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ..._appointments.map((apt) => _buildAppointmentCard(apt)),
        ],
      ],
    );
  }

  Widget _buildAppointmentCard(dynamic appointment) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (appointment['status']) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'CONFIRMED';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'REJECTED';
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusText = 'PENDING';
    }

    final doctorApproved = appointment['doctor_approved'] == 'approved';
    final adminApproved = appointment['admin_approved'] == 'approved';
    final adminPending = appointment['admin_approved'] == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.1),
          radius: 28,
          child: Icon(Icons.calendar_today, color: statusColor, size: 24),
        ),
        title: Text(
          '${appointment['patient_name']} → ${appointment['doctor_name']}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              DateTime.parse(appointment['date_time']).toString().substring(0, 16),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, size: 12, color: statusColor),
                  const SizedBox(width: 4),
                  Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildApprovalChip(
                        'Doctor',
                        doctorApproved,
                        appointment['doctor_approved'] == 'rejected',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildApprovalChip(
                        'Admin',
                        adminApproved,
                        appointment['admin_approved'] == 'rejected',
                      ),
                    ),
                  ],
                ),
                if (adminPending && appointment['status'] == 'pending') ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _approveAppointment(appointment['id']),
                          icon: const Icon(Icons.check),
                          label: const Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _rejectAppointment(appointment['id']),
                          icon: const Icon(Icons.close),
                          label: const Text('Reject'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalChip(String label, bool approved, bool rejected) {
    Color color;
    IconData icon;
    String status;

    if (approved) {
      color = Colors.green;
      icon = Icons.check_circle;
      status = 'Approved';
    } else if (rejected) {
      color = Colors.red;
      icon = Icons.cancel;
      status = 'Rejected';
    } else {
      color = Colors.orange;
      icon = Icons.pending;
      status = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            status,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _approveAppointment(String appointmentId) async {
    try {
      await ApiService.approveAppointment(appointmentId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Appointment approved!'),
          backgroundColor: Colors.green,
        ),
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    }
  }

  Future<void> _rejectAppointment(String appointmentId) async {
    try {
      await ApiService.rejectAppointment(appointmentId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Appointment rejected'),
          backgroundColor: Colors.red,
        ),
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    }
  }

  Widget _buildUserCard(dynamic user, Color color) {
    final isPatient = user['role'] == 'patient';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
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
        trailing: isPatient
            ? ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedIndex = 4; // Go to Upload Reports page
                    _selectedPatientIdForUpload = user['id'];
                  });
                },
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('Upload Report'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              )
            : null,
        onTap: isPatient
            ? () {
                // Navigate to patient details screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PatientDetailsScreen(patient: user),
                  ),
                );
              }
            : null,
      ),
    );
  }

  Widget _buildUploadReports() {
    String? selectedPatientId = _selectedPatientIdForUpload;
    String title = '';
    String department = 'General';
    PlatformFile? selectedFile;

    return StatefulBuilder(
      builder: (context, setPageState) {
        // If a patient was pre-selected, use that
        if (_selectedPatientIdForUpload != null && selectedPatientId == null) {
          selectedPatientId = _selectedPatientIdForUpload;
        }
        
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              children: [
                if (_selectedPatientIdForUpload != null)
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      setState(() {
                        _selectedIndex = 1; // Go back to Patients list
                        _selectedPatientIdForUpload = null;
                      });
                    },
                  ),
                Expanded(
                  child: Text(
                    _selectedPatientIdForUpload != null 
                        ? 'Upload Report for ${_patients.firstWhere((p) => p['id'] == _selectedPatientIdForUpload)['full_name']}'
                        : 'Upload Patient Report',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
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
                    initialValue: selectedPatientId,
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
                    initialValue: department,
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
                  if (selectedFile != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Selected: ${selectedFile!.name}',
                              style: TextStyle(color: Colors.green.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                            const SnackBar(
                              content: Text('✅ Report uploaded successfully! AI is extracting vitals...'),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 3),
                            ),
                          );
                          
                          // Reset form
                          setPageState(() {
                            selectedFile = null;
                          });
                          
                          // Go back to patients list if we came from there
                          if (_selectedPatientIdForUpload != null) {
                            setState(() {
                              _selectedIndex = 1;
                              _selectedPatientIdForUpload = null;
                            });
                          }
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
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Upload Report', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

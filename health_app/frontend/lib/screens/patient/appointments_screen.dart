import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:intl/intl.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  List<dynamic> _appointments = [];
  List<dynamic> _doctors = [];
  bool _isLoading = true;
  String _patientId = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final userData = await ApiService.getUserData();
      if (userData != null) {
        _patientId = userData['id'];
        await Future.wait([
          _fetchAppointments(),
          _fetchDoctors(),
        ]);
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAppointments() async {
    try {
      final appointments = await ApiService.getPatientAppointments(_patientId);
      if (mounted) {
        setState(() => _appointments = appointments);
      }
    } catch (e) {
      debugPrint('Error fetching appointments: $e');
    }
  }

  Future<void> _fetchDoctors() async {
    try {
      final doctors = await ApiService.getDoctors();
      if (mounted) {
        setState(() => _doctors = doctors);
      }
    } catch (e) {
      debugPrint('Error fetching doctors: $e');
    }
  }

  void _showBookAppointmentDialog() {
    String? selectedDoctorId;
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    String notes = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Book Appointment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Select Doctor',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedDoctorId,
                  items: _doctors.map<DropdownMenuItem<String>>((doctor) {
                    return DropdownMenuItem<String>(
                      value: doctor['id'],
                      child: Text('${doctor['full_name']} - ${doctor['specialization'] ?? 'General'}'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedDoctorId = value);
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Date'),
                  subtitle: Text(DateFormat('MMM dd, yyyy').format(selectedDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                    );
                    if (date != null) {
                      setDialogState(() => selectedDate = date);
                    }
                  },
                ),
                ListTile(
                  title: const Text('Time'),
                  subtitle: Text(selectedTime.format(context)),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (time != null) {
                      setDialogState(() => selectedTime = time);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  onChanged: (value) => notes = value,
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
                if (selectedDoctorId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a doctor')),
                  );
                  return;
                }

                try {
                  final dateTime = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    selectedTime.hour,
                    selectedTime.minute,
                  );

                  await ApiService.createAppointment({
                    'patient_id': _patientId,
                    'doctor_id': selectedDoctorId,
                    'date_time': dateTime.toIso8601String(),
                    'status': 'pending',
                    'notes': notes,
                  });

                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Appointment booked successfully')),
                  );
                  _fetchAppointments();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to book appointment: $e')),
                  );
                }
              },
              child: const Text('Book'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Appointments',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showBookAppointmentDialog,
                icon: const Icon(Icons.add),
                label: const Text('Book'),
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
                    Text('No appointments yet'),
                  ],
                ),
              ),
            )
          else
            ..._appointments.map((appointment) => _buildAppointmentCard(appointment)),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(dynamic appointment) {
    Color statusColor;
    IconData statusIcon;
    
    switch (appointment['status']) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusIcon = Icons.done_all;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
    }

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
          backgroundColor: Colors.blue.shade50,
          radius: 28,
          child: Icon(Icons.person, color: Colors.blue.shade700, size: 28),
        ),
        title: Text(
          appointment['doctor_name'] ?? 'Doctor',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM dd, yyyy - hh:mm a').format(
                    DateTime.parse(appointment['date_time']),
                  ),
                ),
              ],
            ),
            if (appointment['notes'] != null && appointment['notes'].isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                appointment['notes'],
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(statusIcon, size: 14, color: statusColor),
              const SizedBox(width: 4),
              Text(
                appointment['status'].toString().toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

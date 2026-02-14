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
    String? selectedTimeSlot;
    String notes = '';
    List<dynamic> availableSlots = [];
    bool loadingSlots = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Book Appointment'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Select Doctor',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: selectedDoctorId,
                    items: _doctors.map<DropdownMenuItem<String>>((doctor) {
                      return DropdownMenuItem<String>(
                        value: doctor['id'],
                        child: Text('${doctor['full_name']} - ${doctor['specialization'] ?? 'General'}'),
                      );
                    }).toList(),
                    onChanged: (value) async {
                      setDialogState(() {
                        selectedDoctorId = value;
                        selectedTimeSlot = null;
                        availableSlots = [];
                      });
                      
                      // Fetch available slots when doctor is selected
                      if (value != null) {
                        setDialogState(() => loadingSlots = true);
                        try {
                          final slots = await ApiService.getAvailableSlots(
                            value,
                            selectedDate.toIso8601String(),
                          );
                          setDialogState(() {
                            availableSlots = slots['available_slots'] ?? [];
                            loadingSlots = false;
                          });
                        } catch (e) {
                          setDialogState(() => loadingSlots = false);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error loading slots: $e')),
                            );
                          }
                        }
                      }
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
                        setDialogState(() {
                          selectedDate = date;
                          selectedTimeSlot = null;
                          availableSlots = [];
                        });
                        
                        // Fetch available slots for new date
                        if (selectedDoctorId != null) {
                          setDialogState(() => loadingSlots = true);
                          try {
                            final slots = await ApiService.getAvailableSlots(
                              selectedDoctorId!,
                              date.toIso8601String(),
                            );
                            setDialogState(() {
                              availableSlots = slots['available_slots'] ?? [];
                              loadingSlots = false;
                            });
                          } catch (e) {
                            setDialogState(() => loadingSlots = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error loading slots: $e')),
                              );
                            }
                          }
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  if (selectedDoctorId != null) ...[
                    if (loadingSlots)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      )
                    else if (availableSlots.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange.shade700),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'No available slots for this date. Please select another date.',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Available Time Slots:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: GridView.builder(
                          shrinkWrap: true,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 2.5,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: availableSlots.length,
                          itemBuilder: (context, index) {
                            final slot = availableSlots[index];
                            final isSelected = selectedTimeSlot == slot['datetime'];
                            
                            return InkWell(
                              onTap: () {
                                setDialogState(() {
                                  selectedTimeSlot = slot['datetime'];
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.blue
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.blue
                                        : Colors.grey.shade300,
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    slot['display'],
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black87,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],
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
                
                if (selectedTimeSlot == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a time slot')),
                  );
                  return;
                }

                try {
                  await ApiService.createAppointment({
                    'patient_id': _patientId,
                    'doctor_id': selectedDoctorId,
                    'date_time': selectedTimeSlot,
                    'status': 'pending',
                    'notes': notes,
                  });

                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Appointment booked successfully'),
                      backgroundColor: Colors.green,
                    ),
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
      case 'completed':
        statusColor = Colors.blue;
        statusIcon = Icons.done_all;
        statusText = 'COMPLETED';
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusText = 'PENDING';
    }

    // Check approval status
    final doctorApproved = appointment['doctor_approved'] == 'approved';
    final adminApproved = appointment['admin_approved'] == 'approved';
    final doctorRejected = appointment['doctor_approved'] == 'rejected';
    final adminRejected = appointment['admin_approved'] == 'rejected';

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
                  Icon(statusIcon, size: 14, color: statusColor),
                  const SizedBox(width: 4),
                  Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (appointment['notes'] != null && appointment['notes'].isNotEmpty) ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Notes:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    appointment['notes'],
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                ],
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Approval Status:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildApprovalChip(
                        'Doctor',
                        doctorApproved,
                        doctorRejected,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildApprovalChip(
                        'Admin',
                        adminApproved,
                        adminRejected,
                      ),
                    ),
                  ],
                ),
                if (appointment['status'] == 'pending') ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            doctorApproved && !adminApproved
                                ? 'Doctor approved. Waiting for admin approval.'
                                : adminApproved && !doctorApproved
                                    ? 'Admin approved. Waiting for doctor approval.'
                                    : 'Waiting for doctor and admin approval.',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
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
}

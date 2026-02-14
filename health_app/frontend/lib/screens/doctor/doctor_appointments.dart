import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:intl/intl.dart';

class DoctorAppointments extends StatefulWidget {
  const DoctorAppointments({super.key});

  @override
  State<DoctorAppointments> createState() => _DoctorAppointmentsState();
}

class _DoctorAppointmentsState extends State<DoctorAppointments> {
  bool _isLoading = true;
  String _doctorId = '';
  List<dynamic> _appointments = [];
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final userData = await ApiService.getUserData();
      if (userData != null) {
        _doctorId = userData['id'];
        await _fetchAppointments();
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAppointments() async {
    try {
      final appointments = await ApiService.getDoctorAppointments(_doctorId);
      if (mounted) {
        setState(() => _appointments = appointments);
      }
    } catch (e) {
      debugPrint('Error fetching appointments: $e');
    }
  }

  List<dynamic> get _filteredAppointments {
    if (_filterStatus == 'all') return _appointments;
    return _appointments.where((apt) => apt['status'] == _filterStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'All Appointments',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('All', 'all'),
              const SizedBox(width: 8),
              _buildFilterChip('Pending', 'pending'),
              const SizedBox(width: 8),
              _buildFilterChip('Approved', 'approved'),
              const SizedBox(width: 8),
              _buildFilterChip('Completed', 'completed'),
              const SizedBox(width: 8),
              _buildFilterChip('Rejected', 'rejected'),
            ],
          ),
        ),
        const SizedBox(height: 24),

        if (_filteredAppointments.isEmpty)
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
        else
          ..._filteredAppointments.map((appointment) => _buildAppointmentCard(appointment)),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filterStatus = value);
      },
      backgroundColor: Colors.white,
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      checkmarkColor: Theme.of(context).colorScheme.primary,
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

    final doctorApproved = appointment['doctor_approved'] == 'approved';
    final adminApproved = appointment['admin_approved'] == 'approved';
    final doctorPending = appointment['doctor_approved'] == 'pending';
    final doctorRejected = appointment['doctor_approved'] == 'rejected';

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
          child: Icon(Icons.person, color: statusColor, size: 28),
        ),
        title: Text(
          appointment['patient_name'] ?? 'Patient',
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      child: _buildApprovalStatus(
                        'Your Approval',
                        doctorApproved,
                        doctorRejected,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildApprovalStatus(
                        'Admin Approval',
                        adminApproved,
                        appointment['admin_approved'] == 'rejected',
                      ),
                    ),
                  ],
                ),
                if (doctorPending && appointment['status'] == 'pending') ...[
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
                if (doctorApproved && !adminApproved && appointment['status'] == 'pending') ...[
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
                            'You approved this appointment. Waiting for admin approval.',
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

  Widget _buildApprovalStatus(String label, bool approved, bool rejected) {
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
            textAlign: TextAlign.center,
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

      _fetchAppointments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to approve: $e')),
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

      _fetchAppointments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reject: $e')),
      );
    }
  }
}

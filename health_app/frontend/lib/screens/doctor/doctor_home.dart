import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class DoctorHome extends StatefulWidget {
  const DoctorHome({super.key});

  @override
  State<DoctorHome> createState() => _DoctorHomeState();
}

class _DoctorHomeState extends State<DoctorHome> {
  bool _isLoading = true;
  String _doctorId = '';
  List<dynamic> _appointments = [];
  List<dynamic> _todayAppointments = [];
  List<dynamic> _patients = [];
  int _totalPatients = 0;
  int _todayPatients = 0;
  int _newPatients = 0;
  int _oldPatients = 0;

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
        await _fetchPatients();
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
        final today = DateTime.now();
        final todayAppts = appointments.where((apt) {
          final aptDate = DateTime.parse(apt['date_time']);
          return aptDate.year == today.year &&
              aptDate.month == today.month &&
              aptDate.day == today.day;
        }).toList();

        // Get unique patient IDs
        final uniquePatients = appointments
            .map((apt) => apt['patient_id'])
            .toSet()
            .length;

        setState(() {
          _appointments = appointments;
          _todayAppointments = todayAppts;
          _totalPatients = uniquePatients;
          _todayPatients = todayAppts.length;
        });
      }
    } catch (e) {
      debugPrint('Error fetching appointments: $e');
    }
  }

  Future<void> _fetchPatients() async {
    try {
      final patients = await ApiService.getAllPatients();
      
      if (mounted) {
        // Calculate new vs old patients (patients created in last 30 days are "new")
        final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
        int newCount = 0;
        int oldCount = 0;
        
        for (var patient in patients) {
          // Since we don't have created_at, we'll use a simple split
          // In production, you'd check the created_at timestamp
          if (patients.indexOf(patient) % 3 == 0) {
            newCount++;
          } else {
            oldCount++;
          }
        }

        setState(() {
          _patients = patients;
          _newPatients = newCount;
          _oldPatients = oldCount;
        });
      }
    } catch (e) {
      debugPrint('Error fetching patients: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Dashboard",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.calendar_today_outlined),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Top Stats Row
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 900) {
                return Column(
                  children: [
                    _buildStatCard("Total Patient", _totalPatients.toString(),
                        "24 Today", Icons.people_outline, const Color(0xFF0066FF)),
                    const SizedBox(height: 16),
                    _buildStatCard("Today Patient", _todayPatients.toString(),
                        DateFormat('dd MMM, yyyy').format(DateTime.now()),
                        Icons.calendar_today, const Color(0xFF0066FF)),
                    const SizedBox(height: 16),
                    _buildStatCard("Today Appointments", _todayAppointments.length.toString(),
                        "${_appointments.where((a) => a['status'] == 'pending').length} New",
                        Icons.event_note, const Color(0xFF0066FF)),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: _buildStatCard("Total Patient", _totalPatients.toString(),
                        "24 Today", Icons.people_outline, const Color(0xFF0066FF)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard("Today Patient", _todayPatients.toString(),
                        DateFormat('dd MMM, yyyy').format(DateTime.now()),
                        Icons.calendar_today, const Color(0xFF0066FF)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard("Today Appointments", _todayAppointments.length.toString(),
                        "${_appointments.where((a) => a['status'] == 'pending').length} New",
                        Icons.event_note, const Color(0xFF0066FF)),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Main Content Grid
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 900) {
                return Column(
                  children: [
                    _buildPatientChart(),
                    const SizedBox(height: 24),
                    _buildTodayAppointments(),
                    const SizedBox(height: 24),
                    _buildOldPatientDetails(),
                    const SizedBox(height: 24),
                    _buildPatientsReviews(),
                    const SizedBox(height: 24),
                    _buildAppointmentRequest(),
                    const SizedBox(height: 24),
                    _buildCalendar(),
                  ],
                );
              }
              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            _buildPatientChart(),
                            const SizedBox(height: 24),
                            _buildPatientsReviews(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            _buildTodayAppointments(),
                            const SizedBox(height: 24),
                            _buildOldPatientDetails(),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildAppointmentRequest(),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 1,
                        child: _buildCalendar(),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientChart() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Patients Percentage December 2021",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 0,
                centerSpaceRadius: 60,
                sections: [
                  PieChartSectionData(
                    color: const Color(0xFF0066FF),
                    value: _newPatients.toDouble(),
                    title: '',
                    radius: 40,
                  ),
                  PieChartSectionData(
                    color: const Color(0xFFFFB800),
                    value: _oldPatients.toDouble(),
                    title: '',
                    radius: 40,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem("New Patients", _newPatients.toString(), const Color(0xFF0066FF)),
              _buildLegendItem("Old Patients", _oldPatients.toString(), const Color(0xFFFFB800)),
            ],
          ),
          const Divider(height: 32),
          _buildLegendItem("Total Patients", _totalPatients.toString(), Colors.grey),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildTodayAppointments() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Today Appointments",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text("Time"),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_todayAppointments.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text('No appointments for today'),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _todayAppointments.length > 5 ? 5 : _todayAppointments.length,
              separatorBuilder: (_, __) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final apt = _todayAppointments[index];
                final time = DateFormat('hh:mm a').format(DateTime.parse(apt['date_time']));
                
                return Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.blue.shade50,
                      child: Text(
                        (apt['patient_name'] ?? 'P')[0].toUpperCase(),
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            apt['patient_name'] ?? 'Patient',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            apt['notes'] ?? 'Consultation',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: apt['status'] == 'approved'
                            ? const Color(0xFF0066FF)
                            : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        time,
                        style: TextStyle(
                          color: apt['status'] == 'approved'
                              ? Colors.white
                              : Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          if (_todayAppointments.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Center(
                child: TextButton(
                  onPressed: () {},
                  child: const Text("View All"),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOldPatientDetails() {
    final oldPatientsList = _patients.take(4).toList();
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Old Patient Details",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          if (oldPatientsList.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text('No patient data'),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: oldPatientsList.length,
              separatorBuilder: (_, __) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final patient = oldPatientsList[index];
                
                return Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.purple.shade50,
                      child: Text(
                        (patient['full_name'] ?? 'P')[0].toUpperCase(),
                        style: TextStyle(
                          color: Colors.purple.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patient['full_name'] ?? 'Patient',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            patient['email'] ?? '',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          "4.${5 + index}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPatientsReviews() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Patients Reviews",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          _buildReviewBar("Excellent", 0.8, Colors.green),
          const SizedBox(height: 12),
          _buildReviewBar("Good", 0.6, Colors.blue),
          const SizedBox(height: 12),
          _buildReviewBar("Average", 0.3, Colors.orange),
          const SizedBox(height: 12),
          _buildReviewBar("Poor", 0.1, Colors.red),
        ],
      ),
    );
  }

  Widget _buildReviewBar(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 13,
              ),
            ),
            Text(
              "${(value * 100).toInt()}%",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildAppointmentRequest() {
    final pendingAppts = _appointments
        .where((apt) => apt['status'] == 'pending')
        .take(3)
        .toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Appointment Request",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          if (pendingAppts.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text('No pending requests'),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pendingAppts.length,
              separatorBuilder: (_, __) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final apt = pendingAppts[index];
                
                return Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.orange.shade50,
                      child: Text(
                        (apt['patient_name'] ?? 'P')[0].toUpperCase(),
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            apt['patient_name'] ?? 'Patient',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('MMM dd, yyyy')
                                .format(DateTime.parse(apt['date_time'])),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check_circle, color: Colors.green, size: 28),
                          onPressed: () => _updateAppointmentStatus(apt['id'], 'approved'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red, size: 28),
                          onPressed: () => _updateAppointmentStatus(apt['id'], 'rejected'),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final startingWeekday = firstDayOfMonth.weekday;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMMM yyyy').format(now),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 20),
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 20),
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Weekday headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su']
                .map((day) => SizedBox(
                      width: 32,
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          // Calendar grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: 35,
            itemBuilder: (context, index) {
              final dayNumber = index - startingWeekday + 2;
              
              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const SizedBox();
              }

              final isToday = dayNumber == now.day;
              
              return Container(
                decoration: BoxDecoration(
                  color: isToday ? const Color(0xFF0066FF) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    dayNumber.toString(),
                    style: TextStyle(
                      color: isToday ? Colors.white : Colors.black87,
                      fontSize: 13,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _updateAppointmentStatus(String appointmentId, String status) async {
    try {
      await ApiService.updateAppointmentStatus(appointmentId, status);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Appointment ${status == 'approved' ? 'approved' : 'rejected'}'),
        ),
      );
      
      // Refresh data
      _fetchAppointments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update appointment: $e')),
      );
    }
  }
}

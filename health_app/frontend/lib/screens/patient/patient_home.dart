import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/screens/patient/patient_dashboard.dart';

class PatientHome extends StatefulWidget {
  const PatientHome({super.key});

  @override
  State<PatientHome> createState() => _PatientHomeState();
}

class _PatientHomeState extends State<PatientHome> {
  bool _isLoading = true;
  Map<String, dynamic> _vitals = {
    "bp": "Loading...",
    "sugar": "Loading...",
    "cholesterol": "Loading...",
  };
  List<FlSpot> _bpSpots = [];
  List<FlSpot> _sugarSpots = [];
  List<FlSpot> _cholesterolSpots = [];
  List<dynamic> _appointments = [];
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
        await _fetchVitals();
        await _fetchAppointments();
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    }
  }

  Future<void> _fetchVitals() async {
    try {
      final vitals = await ApiService.getPatientVitals(_patientId);
      
      if (mounted && vitals.isNotEmpty) {
        final latest = vitals.first;
        setState(() {
          _vitals = {
            "bp": "${latest['bp_systolic']}/${latest['bp_diastolic']}",
            "sugar": "${latest['sugar_level']} mg/dL",
            "cholesterol": "${latest['cholesterol']} mg/dL",
          };
          
          // Create trend data for all vitals from history
          _bpSpots = vitals.asMap().entries.map((entry) {
            return FlSpot(
              entry.key.toDouble(),
              entry.value['bp_systolic'].toDouble(),
            );
          }).toList().reversed.toList();
          
          // Create sugar trend data
          _sugarSpots = vitals.asMap().entries.map((entry) {
            return FlSpot(
              entry.key.toDouble(),
              entry.value['sugar_level'].toDouble(),
            );
          }).toList().reversed.toList();
          
          // Create cholesterol trend data
          _cholesterolSpots = vitals.asMap().entries.map((entry) {
            return FlSpot(
              entry.key.toDouble(),
              entry.value['cholesterol'].toDouble(),
            );
          }).toList().reversed.toList();
          
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching vitals: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAppointments() async {
    try {
      final appointments = await ApiService.getPatientAppointments(_patientId);
      if (mounted) {
        setState(() {
          _appointments = appointments.where((apt) => apt['status'] == 'approved').toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching appointments: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue.shade50.withValues(alpha: 0.3),
            Colors.white,
          ],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Header Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Health Overview", 
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    )
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Track your health metrics",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Icon(Icons.favorite, color: Colors.red.shade400, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Vitals Section
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.blue.shade600,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Vitals Comparison", 
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                )
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
               // Stack vertically on very small screens
               if (constraints.maxWidth < 600) {
                 return Column(
                   children: [
                     _buildVitalCard(context, "Blood Pressure", _vitals['bp'], Colors.red.shade400, _bpSpots),
                     const SizedBox(height: 16),
                     _buildVitalCard(context, "Sugar Level", _vitals['sugar'], Colors.purple.shade400, _sugarSpots),
                     const SizedBox(height: 16),
                     _buildVitalCard(context, "Cholesterol", _vitals['cholesterol'], Colors.orange.shade400, _cholesterolSpots),
                   ],
                 );
               }
               return Row(
                children: [
                  Expanded(child: _buildVitalCard(context, "Blood Pressure", _vitals['bp'], Colors.red.shade400, _bpSpots)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildVitalCard(context, "Sugar Level", _vitals['sugar'], Colors.purple.shade400, _sugarSpots)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildVitalCard(context, "Cholesterol", _vitals['cholesterol'], Colors.orange.shade400, _cholesterolSpots)),
                ],
              );
            }
          ),
          
          const SizedBox(height: 32),
          // Quick Actions and Info Section
          LayoutBuilder(
            builder: (context, constraints) {
              // Stack vertically on small screens
              if (constraints.maxWidth < 900) {
                return Column(
                  children: [
                    _buildQuickActionCard(
                      context,
                      'Book Appointment',
                      'Schedule a visit with your doctor',
                      Icons.calendar_today_rounded,
                      Colors.blue.shade600,
                      () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const PatientDashboard(initialIndex: 1),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildAppointmentSection(),
                    const SizedBox(height: 20),
                    _buildTipCard(),
                  ],
                );
              }
              // Side by side on larger screens
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _buildQuickActionCard(
                          context,
                          'Book Appointment',
                          'Schedule a visit with your doctor',
                          Icons.calendar_today_rounded,
                          Colors.blue.shade600,
                          () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => const PatientDashboard(initialIndex: 1),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildTipCard(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 3,
                    child: _buildAppointmentSection(),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildVitalCard(BuildContext context, String title, String value, Color color, List<FlSpot> spots) {
    // Define normal ranges
    double normalValue = 0;
    double patientValue = 0;
    String normalRange = '';
    
    if (title == 'Blood Pressure') {
      normalValue = 120;
      normalRange = '~120/80';
      if (spots.isNotEmpty) {
        patientValue = spots.last.y;
      }
    } else if (title == 'Sugar Level') {
      normalValue = 85;
      normalRange = '70-99';
      if (spots.isNotEmpty) {
        patientValue = spots.last.y;
      }
    } else if (title == 'Cholesterol') {
      normalValue = 200;
      normalRange = '<200';
      if (spots.isNotEmpty) {
        patientValue = spots.last.y;
      }
    }
    
    return Container(
      height: 240,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.monitor_heart_outlined, size: 20, color: color),
          ),
          const SizedBox(height: 16),
          Text(
            title, 
            style: TextStyle(
              color: Colors.grey[600], 
              fontSize: 13,
              fontWeight: FontWeight.w500,
            )
          ),
          const SizedBox(height: 8),
          Text(
            value, 
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            )
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Normal: $normalRange', 
              style: TextStyle(
                color: Colors.green.shade700, 
                fontSize: 11,
                fontWeight: FontWeight.w500,
              )
            ),
          ),
          const Spacer(),
          // Comparison Bar Chart
          if (patientValue > 0 && !_isLoading)
            SizedBox(
              height: 70,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return Text('Normal', style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w500));
                          if (value == 1) return Text('Your Value', style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w500));
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: normalValue,
                          gradient: LinearGradient(
                            colors: [Colors.green.shade400, Colors.green.shade600],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          width: 45,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: patientValue,
                          gradient: LinearGradient(
                            colors: patientValue > normalValue * 1.2 
                              ? [Colors.red.shade400, Colors.red.shade600]
                              : [color.withValues(alpha: 0.7), color],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          width: 45,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                        ),
                      ],
                    ),
                  ],
                  maxY: (normalValue > patientValue ? normalValue : patientValue) * 1.3,
                ),
              ),
            )
          else
             Container(
              height: 6,
              width: 50,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(3),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildAppointmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.green.shade600,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "Upcoming Appointments", 
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              )
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildAppointmentCard(),
      ],
    );
  }

  Widget _buildAppointmentCard() {
    if (_appointments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.event_busy, color: Colors.grey.shade400, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              'No upcoming appointments',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Book an appointment to get started',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    final appointment = _appointments.first;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.blue.shade600],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment['doctor_name'] ?? 'Doctor',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      appointment['date_time'] ?? '',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade400, Colors.green.shade600],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              "Approved", 
              style: TextStyle(
                color: Colors.white, 
                fontWeight: FontWeight.bold, 
                fontSize: 12,
              )
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade400, Colors.green.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.lightbulb_outline, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 20),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Health Tip", 
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 16,
                    color: Colors.white,
                  )
                ),
                SizedBox(height: 6),
                Text(
                  "Your recent report indicates good progress. Keep maintaining your diet and exercise routine.",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            )
          ),
        ],
      ),
    );
  }
}

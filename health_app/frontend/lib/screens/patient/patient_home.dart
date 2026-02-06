import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:frontend/services/api_service.dart';

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
          
          // Create trend data from vitals history
          _bpSpots = vitals.asMap().entries.map((entry) {
            return FlSpot(
              entry.key.toDouble(),
              entry.value['bp_systolic'].toDouble(),
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
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          "Health Overview", 
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold
          )
        ),
        const SizedBox(height: 24),
        
        // Vitals Section
        Text("Vitals Trends (Latest Report)", style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
             // Stack vertically on very small screens
             if (constraints.maxWidth < 600) {
               return Column(
                 children: [
                   _buildVitalCard(context, "Blood Pressure", _vitals['bp'], Colors.red, true),
                   const SizedBox(height: 16),
                   _buildVitalCard(context, "Sugar Level", _vitals['sugar'], Colors.purple, false),
                   const SizedBox(height: 16),
                   _buildVitalCard(context, "Cholesterol", _vitals['cholesterol'], Colors.orange, false),
                 ],
               );
             }
             return Row(
              children: [
                Expanded(child: _buildVitalCard(context, "Blood Pressure", _vitals['bp'], Colors.red, true)),
                const SizedBox(width: 16),
                Expanded(child: _buildVitalCard(context, "Sugar Level", _vitals['sugar'], Colors.purple, false)),
                const SizedBox(width: 16),
                Expanded(child: _buildVitalCard(context, "Cholesterol", _vitals['cholesterol'], Colors.orange, false)),
              ],
            );
          }
        ),
        
        const SizedBox(height: 32),
        // Appointments
        Text("Upcoming Appointments", style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        _buildAppointmentCard(),

        const SizedBox(height: 32),
        // Healthy Tip
        _buildTipCard(),
      ],
    );
  }

  Widget _buildVitalCard(BuildContext context, String title, String value, Color color, bool showGraph) {
    return Container(
      height: 180, // Fixed height for alignment
      padding: const EdgeInsets.all(16),
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
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.monitor_heart_outlined, size: 16, color: color),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const Spacer(),
          if (showGraph && !_isLoading)
            SizedBox(
              height: 50,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _bpSpots,
                      isCurved: true,
                      color: color,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: true, color: color.withOpacity(0.1)),
                    ),
                  ],
                ),
              ),
            )
          else
             Container(
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildAppointmentCard() {
    if (_appointments.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(
            child: Text('No upcoming appointments'),
          ),
        ),
      );
    }

    final appointment = _appointments.first;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade50,
          child: const Icon(Icons.person, color: Colors.blue),
        ),
        title: Text(
          appointment['doctor_name'] ?? 'Doctor',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(appointment['date_time'] ?? ''),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            "Approved", 
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)
          ),
        ),
      ),
    );
  }

  Widget _buildTipCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.teal.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lightbulb, color: Colors.orange),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Doctor's Note", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 4),
                Text("Your recent report indicates good progress. Keep maintaining your diet."),
              ],
            )
          ),
        ],
      ),
    );
  }
}

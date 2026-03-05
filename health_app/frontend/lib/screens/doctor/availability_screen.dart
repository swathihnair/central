import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';

class AvailabilityScreen extends StatefulWidget {
  final String doctorId;

  const AvailabilityScreen({super.key, required this.doctorId});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  final Map<String, Map<String, dynamic>> _availability = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    try {
      final availability = await ApiService.getDoctorAvailability(widget.doctorId);
      
      if (mounted) {
        setState(() {
          _availability.clear();
          for (var slot in availability) {
            _availability[slot['day_of_week']] = {
              'start_time': slot['start_time'],
              'end_time': slot['end_time'],
              'is_available': slot['is_available'],
            };
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading availability: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveAvailability() async {
    try {
      final slots = _availability.entries
          .where((entry) => entry.value['is_available'] == true)
          .map((entry) => {
                'day_of_week': entry.key,
                'start_time': entry.value['start_time'],
                'end_time': entry.value['end_time'],
                'is_available': true,
              })
          .toList();

      await ApiService.setDoctorAvailability(widget.doctorId, slots);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Availability updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _toggleDay(String day) {
    setState(() {
      if (_availability.containsKey(day)) {
        _availability[day]!['is_available'] = !_availability[day]!['is_available'];
      } else {
        _availability[day] = {
          'start_time': '09:00',
          'end_time': '17:00',
          'is_available': true,
        };
      }
    });
  }

  Future<void> _selectTime(String day, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        final timeStr = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        if (!_availability.containsKey(day)) {
          _availability[day] = {
            'start_time': '09:00',
            'end_time': '17:00',
            'is_available': true,
          };
        }
        if (isStartTime) {
          _availability[day]!['start_time'] = timeStr;
        } else {
          _availability[day]!['end_time'] = timeStr;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Availability'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveAvailability,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue),
                            SizedBox(width: 8),
                            Text(
                              'Set Your Available Hours',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Toggle days on/off and set your working hours. Patients will only see these time slots when booking appointments.',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ..._daysOfWeek.map((day) => _buildDayCard(day)).toList(),
              ],
            ),
    );
  }

  Widget _buildDayCard(String day) {
    final isAvailable = _availability[day]?['is_available'] ?? false;
    final startTime = _availability[day]?['start_time'] ?? '09:00';
    final endTime = _availability[day]?['end_time'] ?? '17:00';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    day,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Switch(
                  value: isAvailable,
                  onChanged: (_) => _toggleDay(day),
                ),
              ],
            ),
            if (isAvailable) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTimeButton(
                      label: 'Start Time',
                      time: startTime,
                      onTap: () => _selectTime(day, true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTimeButton(
                      label: 'End Time',
                      time: endTime,
                      onTap: () => _selectTime(day, false),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeButton({
    required String label,
    required String time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 4),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

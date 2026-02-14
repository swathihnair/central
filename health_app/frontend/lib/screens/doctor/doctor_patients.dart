import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';

class DoctorPatients extends StatefulWidget {
  const DoctorPatients({super.key});

  @override
  State<DoctorPatients> createState() => _DoctorPatientsState();
}

class _DoctorPatientsState extends State<DoctorPatients> {
  bool _isLoading = true;
  List<dynamic> _patients = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    try {
      final patients = await ApiService.getPatients();
      if (mounted) {
        setState(() {
          _patients = patients;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading patients: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> get _filteredPatients {
    if (_searchQuery.isEmpty) return _patients;
    return _patients.where((patient) {
      final name = patient['full_name'].toString().toLowerCase();
      final email = patient['email'].toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || email.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'My Patients',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 24),

        // Search bar
        TextField(
          decoration: InputDecoration(
            hintText: 'Search patients...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          onChanged: (value) {
            setState(() => _searchQuery = value);
          },
        ),
        const SizedBox(height: 24),

        if (_filteredPatients.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(48.0),
              child: Column(
                children: [
                  Icon(Icons.people_outline, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No patients found'),
                ],
              ),
            ),
          )
        else
          ..._filteredPatients.map((patient) => _buildPatientCard(patient)),
      ],
    );
  }

  Widget _buildPatientCard(dynamic patient) {
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
          backgroundColor: Colors.blue.shade50,
          radius: 28,
          child: Text(
            patient['full_name'].toString().substring(0, 1).toUpperCase(),
            style: TextStyle(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        title: Text(
          patient['full_name'],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.email_outlined, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(patient['email']),
              ],
            ),
            if (patient['phone'] != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.phone_outlined, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(patient['phone']),
                ],
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward_ios, size: 16),
          onPressed: () {
            // Navigate to patient details
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('View ${patient['full_name']} details')),
            );
          },
        ),
      ),
    );
  }
}

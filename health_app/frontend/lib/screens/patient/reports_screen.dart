import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  Map<String, List<dynamic>> _groupedReports = {};
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
        await _fetchReports();
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchReports() async {
    try {
      final reports = await ApiService.getPatientReports(_patientId);
      _groupReports(reports);
    } catch (e) {
      debugPrint("Error fetching reports: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _viewReport(String reportId) async {
    try {
      final url = Uri.parse('${ApiService.baseUrl}/reports/view/$reportId');
      
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open PDF viewer')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error viewing report: $e')),
        );
      }
    }
  }

  Future<void> _downloadReport(String reportId, String title) async {
    try {
      // Generate a clean filename
      final filename = '${title.replaceAll(' ', '_')}.pdf';
      
      await ApiService.downloadPDF(reportId, filename);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloaded $title'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error downloading report: $e')),
        );
      }
    }
  }

  void _groupReports(List<dynamic> reports) {
    Map<String, List<dynamic>> temp = {};
    for (var report in reports) {
      String dept = report['department'] ?? 'General';
      if (!temp.containsKey(dept)) {
        temp[dept] = [];
      }
      temp[dept]!.add(report);
    }
    setState(() {
      _groupedReports = temp;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_groupedReports.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_off_outlined, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text("No reports found."),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          "Medical Reports",
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        ..._groupedReports.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDepartmentHeader(entry.key),
              const SizedBox(height: 12),
              ...entry.value.map((report) => _buildReportCard(report)),
              const SizedBox(height: 24),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildDepartmentHeader(String dept) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          dept,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildReportCard(dynamic report) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.description_outlined, color: Colors.blue.shade700),
        ),
        title: Text(report['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text("Date: ${report['date']}"),
            if (report['vitals'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Wrap(
                  spacing: 8,
                  children: (report['vitals'] as Map<String, dynamic>).entries.map((v) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text("${v.key}: ${v.value}", style: const TextStyle(fontSize: 12)),
                    );
                  }).toList(),
                ),
              )
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility_outlined),
              tooltip: 'View PDF',
              color: Colors.blue,
              onPressed: () => _viewReport(report['id']),
            ),
            IconButton(
              icon: const Icon(Icons.download_rounded),
              tooltip: 'Download PDF',
              color: Colors.green,
              onPressed: () => _downloadReport(report['id'], report['title']),
            ),
          ],
        ),
      ),
    );
  }
}

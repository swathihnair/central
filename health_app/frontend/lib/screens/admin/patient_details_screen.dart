import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class PatientDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> patient;

  const PatientDetailsScreen({super.key, required this.patient});

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  List<dynamic> _reports = [];
  bool _isLoading = true;
  bool _showUploadForm = false;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    try {
      final reports = await ApiService.getPatientReports(widget.patient['id']);
      if (mounted) {
        setState(() {
          _reports = reports;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading reports: $e');
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

  Future<void> _deleteReport(String reportId, String title) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Report'),
        content: Text('Are you sure you want to delete "$title"?\n\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.deleteReport(reportId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deleted $title'),
              backgroundColor: Colors.red,
            ),
          );
          // Reload reports
          _loadReports();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting report: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.patient['full_name']} - Reports'),
        actions: [
          if (!_showUploadForm)
            TextButton.icon(
              onPressed: () {
                setState(() => _showUploadForm = true);
              },
              icon: const Icon(Icons.add),
              label: const Text('Upload New Report'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
      body: _showUploadForm
          ? _buildUploadForm()
          : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildReportsList(),
    );
  }

  Widget _buildReportsList() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Patient Info Card
        Container(
          padding: const EdgeInsets.all(20),
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
          child: Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  widget.patient['full_name'][0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.patient['full_name'],
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.patient['email'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (widget.patient['phone'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.patient['phone'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_reports.length} Reports',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Reports Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Medical Reports',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            TextButton.icon(
              onPressed: _loadReports,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),

        const SizedBox(height: 16),

        if (_reports.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No reports uploaded yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () {
                    setState(() => _showUploadForm = true);
                  },
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload First Report'),
                ),
              ],
            ),
          )
        else
          ..._reports.map((report) => _buildReportCard(report)),
      ],
    );
  }

  Widget _buildReportCard(dynamic report) {
    final hasVitals = report['vitals'] != null;
    
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
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.picture_as_pdf, color: Colors.red.shade700),
        ),
        title: Text(
          report['title'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.medical_services, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  report['department'],
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(width: 16),
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  report['date'],
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasVitals) ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Extracted Vitals',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildVitalChip(
                        'Blood Pressure',
                        report['vitals']['bp'],
                        Icons.favorite,
                        Colors.red,
                      ),
                      _buildVitalChip(
                        'Sugar Level',
                        '${report['vitals']['sugar']} mg/dL',
                        Icons.water_drop,
                        Colors.purple,
                      ),
                      _buildVitalChip(
                        'Cholesterol',
                        '${report['vitals']['cholesterol']} mg/dL',
                        Icons.analytics,
                        Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _viewReport(report['id']),
                        icon: const Icon(Icons.visibility),
                        label: const Text('View PDF'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _downloadReport(report['id'], report['title']),
                        icon: const Icon(Icons.download),
                        label: const Text('Download'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _deleteReport(report['id'], report['title']),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete Report'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalChip(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUploadForm() {
    String title = '';
    String department = 'General';
    PlatformFile? selectedFile;

    return StatefulBuilder(
      builder: (context, setFormState) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() => _showUploadForm = false);
                },
              ),
              const SizedBox(width: 8),
              Text(
                'Upload New Report',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
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
                // Patient Info (Read-only)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.person, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Patient',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            widget.patient['full_name'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Report Title',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                  onChanged: (value) => title = value,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Department',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.medical_services),
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
                    setFormState(() => department = value!);
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
                      setFormState(() => selectedFile = result.files.first);
                    }
                  },
                  icon: const Icon(Icons.attach_file),
                  label: Text(selectedFile?.name ?? 'Select File (PDF, JPG, PNG)'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
                if (selectedFile != null) ...[
                  const SizedBox(height: 12),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'File Selected',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                selectedFile!.name,
                                style: TextStyle(color: Colors.green.shade700),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (title.isEmpty || selectedFile == null) {
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
                      request.fields['patient_id'] = widget.patient['id'];
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

                        // Reload reports and hide form
                        setState(() {
                          _showUploadForm = false;
                        });
                        _loadReports();
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
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload Report'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

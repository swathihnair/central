import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/rfid_websocket_service.dart';
import 'package:frontend/screens/admin/patient_details_screen.dart';
import 'dart:async';

class RFIDScannerScreen extends StatefulWidget {
  const RFIDScannerScreen({super.key});

  @override
  State<RFIDScannerScreen> createState() => _RFIDScannerScreenState();
}

class _RFIDScannerScreenState extends State<RFIDScannerScreen> {
  final TextEditingController _cardUidController = TextEditingController();
  final FocusNode _scannerFocusNode = FocusNode();
  bool _isScanning = false;
  String _statusMessage = 'Ready to scan RFID card...';
  Color _statusColor = Colors.blue;
  String _lastScannedCard = '';
  
  // WebSocket service
  final RFIDWebSocketService _wsService = RFIDWebSocketService();
  StreamSubscription? _wsSubscription;
  bool _isWebSocketConnected = false;

  @override
  void initState() {
    super.initState();
    // Auto-focus on the text field for RFID scanner input
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scannerFocusNode.requestFocus();
      _connectWebSocket();
    });
    
    // Listen to text changes for real-time scanning
    _cardUidController.addListener(_onCardUidChanged);
  }
  
  Future<void> _connectWebSocket() async {
    debugPrint('🔌 Connecting to RFID WebSocket...');
    
    try {
      await _wsService.connect();
      
      // Listen to WebSocket messages
      _wsSubscription = _wsService.messages.listen((message) {
        debugPrint('📨 WebSocket message received: $message');
        
        if (message['type'] == 'rfid_scan') {
          // Card scanned from Arduino
          final cardUid = message['card_uid'];
          debugPrint('🎴 Arduino scanned card: $cardUid');
          
          // Trigger scan
          _handleScan(cardUid);
        } else if (message['type'] == 'connected') {
          setState(() {
            _isWebSocketConnected = true;
            _statusMessage = 'Connected to Arduino - Ready to scan!';
            _statusColor = Colors.green;
          });
        }
      });
      
      setState(() {
        _isWebSocketConnected = true;
      });
    } catch (e) {
      debugPrint('❌ WebSocket connection failed: $e');
      setState(() {
        _isWebSocketConnected = false;
        _statusMessage = 'WebSocket disconnected - Using manual mode';
        _statusColor = Colors.orange;
      });
    }
  }
  
  void _onCardUidChanged() {
    final text = _cardUidController.text.trim();
    
    // Auto-scan when we detect a complete card UID
    // Most RFID readers send the UID followed by Enter
    // We'll trigger on text length >= 8 characters (typical UID length)
    if (text.isNotEmpty && text.length >= 8 && text != _lastScannedCard && !_isScanning) {
      debugPrint('🔍 Real-time detection: $text');
      // Small delay to ensure full UID is captured
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && _cardUidController.text.trim() == text) {
          _handleScan(text);
        }
      });
    }
  }

  @override
  void dispose() {
    _cardUidController.dispose();
    _scannerFocusNode.dispose();
    _wsSubscription?.cancel();
    _wsService.dispose();
    super.dispose();
  }

  Future<void> _handleScan(String cardUid) async {
    if (cardUid.isEmpty || _isScanning) return;

    // Prevent duplicate scans of the same card
    if (cardUid == _lastScannedCard) {
      debugPrint('⏭️ Skipping duplicate scan: $cardUid');
      return;
    }

    _lastScannedCard = cardUid;
    debugPrint('🎴 Scanning card UID: $cardUid');

    setState(() {
      _isScanning = true;
      _statusMessage = 'Scanning card...';
      _statusColor = Colors.orange;
    });

    try {
      debugPrint('📡 Calling API with card UID: $cardUid');
      final patientData = await ApiService.scanRFIDCard(cardUid);
      
      debugPrint('✅ RFID Scan Success: $patientData');
      debugPrint('Patient ID: ${patientData['patient_id']}');
      debugPrint('Patient Name: ${patientData['full_name']}');
      
      if (!mounted) {
        debugPrint('⚠️ Widget not mounted, aborting');
        return;
      }
      
      setState(() {
        _statusMessage = 'Patient found: ${patientData['full_name']}';
        _statusColor = Colors.green;
      });

      debugPrint('🔔 Showing dialog...');
      // Show success dialog and redirect
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 32),
              const SizedBox(width: 12),
              const Text('Patient Identified'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                patientData['full_name'],
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text('Email: ${patientData['email']}'),
              if (patientData['phone'] != null)
                Text('Phone: ${patientData['phone']}'),
              if (patientData['age'] != null)
                Text('Age: ${patientData['age']}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                debugPrint('🚀 Navigating to patient details...');
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PatientDetailsScreen(
                      patient: {
                        'id': patientData['patient_id'].toString(),
                        'full_name': patientData['full_name'] ?? 'Unknown',
                        'email': patientData['email'] ?? '',
                        'phone': patientData['phone'],
                        'age': patientData['age'],
                      },
                    ),
                  ),
                ).then((_) {
                  debugPrint('✅ Returned from patient details');
                });
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('View Medical History'),
            ),
          ],
        ),
      );

      debugPrint('✅ Dialog closed');
      
      // Reset for next scan
      _cardUidController.clear();
      _lastScannedCard = ''; // Reset to allow re-scanning same card
      _scannerFocusNode.requestFocus();
      if (mounted) {
        setState(() {
          _statusMessage = 'Ready to scan next card...';
          _statusColor = Colors.blue;
        });
      }
    } catch (e) {
      debugPrint('❌ RFID Scan Error: $e');
      debugPrint('Error type: ${e.runtimeType}');
      
      if (!mounted) return;
      
      setState(() {
        _statusMessage = 'Error: ${e.toString()}';
        _statusColor = Colors.red;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Card not registered: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );

      _cardUidController.clear();
      _lastScannedCard = ''; // Reset to allow retry
      _scannerFocusNode.requestFocus();
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RFID Card Scanner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('How to Use'),
                  content: const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('1. Place patient RFID card near the reader'),
                      SizedBox(height: 8),
                      Text('2. The card will be scanned automatically'),
                      SizedBox(height: 8),
                      Text('3. Patient information will appear'),
                      SizedBox(height: 8),
                      Text('4. Click "View Medical History" to see patient records'),
                      SizedBox(height: 16),
                      Text(
                        'Note: The scanner field must be focused. Click on it if scanning doesn\'t work.',
                        style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Scanner Animation
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _statusColor,
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      _isScanning ? Icons.sync : Icons.nfc,
                      size: 100,
                      color: _statusColor,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Status Message
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _statusColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_isScanning ? Icons.hourglass_empty : Icons.info_outline, 
                           color: _statusColor),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          _statusMessage,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: _statusColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Real-time indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isWebSocketConnected ? Colors.green.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isWebSocketConnected ? Colors.green.shade300 : Colors.orange.shade300
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _isWebSocketConnected ? Colors.green : Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isWebSocketConnected 
                            ? 'Connected' 
                            : 'Manual Mode',
                        style: TextStyle(
                          color: _isWebSocketConnected 
                              ? Colors.green.shade700 
                              : Colors.orange.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Real-time input field for RFID scanner
                TextField(
                  controller: _cardUidController,
                  focusNode: _scannerFocusNode,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'RFID Scanner Input (Auto-scanning)',
                    hintText: 'Scan card - detects automatically',
                    prefixIcon: const Icon(Icons.nfc),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: _isScanning
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : Icon(Icons.sensors, color: Colors.green.shade600),
                  ),
                  onSubmitted: _handleScan,
                  enabled: !_isScanning,
                ),
                const SizedBox(height: 16),

                // Manual scan button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isScanning
                        ? null
                        : () => _handleScan(_cardUidController.text),
                    icon: const Icon(Icons.search),
                    label: const Text('Manual Scan'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Instructions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb_outline, color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Quick Tips',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text('• Real-time scanning - no need to press Enter!'),
                      const SizedBox(height: 4),
                      const Text('• Just scan the card and wait for the dialog'),
                      const SizedBox(height: 4),
                      const Text('• RFID reader acts as a keyboard input device'),
                      const SizedBox(height: 4),
                      const Text('• Scans automatically when UID is detected'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

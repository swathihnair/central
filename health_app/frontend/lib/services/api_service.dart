import 'dart:convert';
import 'dart:js_interop';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web/web.dart' as web;

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
  
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }
  
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(userData));
  }
  
  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');
    if (userDataString != null) {
      return jsonDecode(userDataString);
    }
    return null;
  }
  
  static Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user_data');
  }
  
  static Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
  
  // Auth APIs
  static Future<Map<String, dynamic>> login(String email, String password, String role) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'role': role,
      }),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await saveToken(data['access_token']);
      
      // Get user data
      final userResponse = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: {'Authorization': 'Bearer ${data['access_token']}'},
      );
      
      if (userResponse.statusCode == 200) {
        final userData = jsonDecode(userResponse.body);
        await saveUserData(userData);
        return userData;
      }
      
      return data;
    } else {
      throw Exception(jsonDecode(response.body)['detail'] ?? 'Login failed');
    }
  }
  
  static Future<void> register(Map<String, dynamic> userData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(userData),
    );
    
    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['detail'] ?? 'Registration failed');
    }
  }
  
  // Reports APIs
  static Future<List<dynamic>> getPatientReports(String patientId) async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/reports/patient/$patientId'),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load reports');
  }
  
  static Future<List<dynamic>> getPatientVitals(String patientId) async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/reports/patient/$patientId/vitals'),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load vitals');
  }
  
  // Appointments APIs
  static Future<List<dynamic>> getPatientAppointments(String patientId) async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/appointments/patient/$patientId'),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load appointments');
  }
  
  static Future<List<dynamic>> getDoctorAppointments(String doctorId) async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/appointments/doctor/$doctorId'),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load appointments');
  }
  
  static Future<void> createAppointment(Map<String, dynamic> appointmentData) async {
    final headers = await getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/appointments/create'),
      headers: headers,
      body: jsonEncode(appointmentData),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to create appointment');
    }
  }
  
  static Future<void> updateAppointmentStatus(String appointmentId, String status) async {
    final headers = await getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/appointments/$appointmentId/status?status=$status'),
      headers: headers,
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to update appointment');
    }
  }
  
  static Future<void> approveAppointment(String appointmentId) async {
    final headers = await getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/appointments/$appointmentId/approve'),
      headers: headers,
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to approve appointment');
    }
  }
  
  static Future<void> rejectAppointment(String appointmentId) async {
    final headers = await getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/appointments/$appointmentId/reject'),
      headers: headers,
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to reject appointment');
    }
  }
  
  static Future<List<dynamic>> getAllAppointments() async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/appointments/all'),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load appointments');
  }
  
  static Future<Map<String, dynamic>> getAvailableSlots(String doctorId, String date) async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/appointments/available-slots/$doctorId/$date'),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load available slots');
  }
  
  // Users APIs
  static Future<List<dynamic>> getPatients() async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/users/patients'),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load patients');
  }

  static Future<List<dynamic>> getAllPatients() async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/users/patients'),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load patients');
  }
  
  static Future<List<dynamic>> getDoctors() async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/users/doctors'),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load doctors');
  }
  
  // AI Chat API
  static Future<String> sendChatMessage(String message, {String? patientId}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ai/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'message': message,
        'history': [],
        'patient_id': patientId != null ? int.tryParse(patientId) : null,
      }),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['response'];
    }
    throw Exception('Failed to get AI response');
  }

  // Download PDF file
  static Future<void> downloadPDF(String reportId, String filename) async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/reports/download/$reportId'),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      // Create a blob from the PDF bytes
      final blob = web.Blob([response.bodyBytes.toJS].toJS, web.BlobPropertyBag(type: 'application/pdf'));
      final url = web.URL.createObjectURL(blob);
      
      // Create a temporary anchor element and trigger download
      final anchor = web.document.createElement('a') as web.HTMLAnchorElement
        ..href = url
        ..download = filename
        ..style.display = 'none';
      
      web.document.body?.appendChild(anchor);
      anchor.click();
      
      // Cleanup
      web.document.body?.removeChild(anchor);
      web.URL.revokeObjectURL(url);
    } else {
      throw Exception('Failed to download PDF');
    }
  }

  // Delete report (admin only)
  static Future<void> deleteReport(String reportId) async {
    final headers = await getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/reports/delete/$reportId'),
      headers: headers,
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to delete report');
    }
  }

  // RFID APIs
  static Future<Map<String, dynamic>> assignRFIDCard(String cardUid, int patientId) async {
    final headers = await getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/rfid/assign'),
      headers: headers,
      body: jsonEncode({
        'card_uid': cardUid,
        'patient_id': patientId,
      }),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to assign RFID card');
  }

  static Future<Map<String, dynamic>> scanRFIDCard(String cardUid) async {
    final headers = await getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/rfid/scan'),
      headers: headers,
      body: jsonEncode({
        'card_uid': cardUid,
      }),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception(jsonDecode(response.body)['detail'] ?? 'RFID card not found');
  }

  static Future<Map<String, dynamic>> getPatientRFID(int patientId) async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/rfid/patient/$patientId'),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to get RFID card');
  }

  static Future<void> unassignRFIDCard(String cardUid) async {
    final headers = await getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/rfid/unassign/$cardUid'),
      headers: headers,
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to unassign RFID card');
    }
  }
}

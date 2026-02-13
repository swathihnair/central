import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:frontend/services/api_service.dart';

class DoctorAIScreen extends StatefulWidget {
  const DoctorAIScreen({super.key});

  @override
  State<DoctorAIScreen> createState() => _DoctorAIScreenState();
}

class _DoctorAIScreenState extends State<DoctorAIScreen> {
  final ChatUser _currentUser = ChatUser(id: '1', firstName: 'Patient');
  final ChatUser _geminiUser = ChatUser(
    id: '2', 
    firstName: 'Dr. AI',
    profileImage: "https://cdn-icons-png.flaticon.com/512/3774/3774299.png"
  );
  
  List<ChatMessage> _messages = [];
  final List<ChatMessage> _typing = [];
  String? _patientId;

  @override
  void initState() {
    super.initState();
    _loadPatientId();
    // Initial greeting
    _messages.add(
      ChatMessage(
        text: "Hello! I am your AI Health Assistant. How can I help you today?",
        user: _geminiUser,
        createdAt: DateTime.now(),
      )
    );
  }

  Future<void> _loadPatientId() async {
    try {
      final userData = await ApiService.getUserData();
      if (userData != null) {
        setState(() {
          _patientId = userData['id'];
        });
      }
    } catch (e) {
      debugPrint('Error loading patient ID: $e');
    }
  }

  Future<void> _handleSendMessage(ChatMessage message) async {
    setState(() {
      _messages.insert(0, message);
      _typing.add(ChatMessage(
        text: "typing...", 
        user: _geminiUser, 
        createdAt: DateTime.now()
      ));
    });

    try {
      final botResponse = await ApiService.sendChatMessage(
        message.text,
        patientId: _patientId,
      );

      setState(() {
        _messages.insert(0, ChatMessage(
          text: botResponse,
          user: _geminiUser,
          createdAt: DateTime.now(),
        ));
      });
    } catch (e) {
      _showError("Connection error. Make sure backend is running.");
    } finally {
      setState(() {
        _typing.clear();
      });
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DashChat(
        currentUser: _currentUser,
        onSend: _handleSendMessage,
        messages: _messages,
        typingUsers: _typing.isNotEmpty ? [_geminiUser] : [],
        inputOptions: const InputOptions(
          inputDecoration: InputDecoration(
            hintText: "Ask about your health...",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(25)),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            filled: true,
            fillColor: Colors.white,
          ),
          alwaysShowSend: true,
        ),
        messageOptions: MessageOptions(
          currentUserContainerColor: Theme.of(context).primaryColor,
          containerColor: Colors.grey.shade200,
          textColor: Colors.black87,
          currentUserTextColor: Colors.white,
          borderRadius: 18,
        ),
      ),
    );
  }
}

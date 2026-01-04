import 'package:flutter/material.dart';
import 'package:financial_app/services/api_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/widgets/chat/chat_message_bubble.dart';
import 'package:financial_app/widgets/chat/chat_input_field.dart';

class ChatAssistantScreen extends StatefulWidget {
  const ChatAssistantScreen({super.key});

  @override
  State<ChatAssistantScreen> createState() => _ChatAssistantScreenState();
}

class _ChatAssistantScreenState extends State<ChatAssistantScreen> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChatHistory() async {
    try {
      final history = await _apiService.getChatHistory();
      if (mounted) {
        setState(() {
          _messages.clear();
          for (var entry in history) {
            _messages.add({
              'message': entry['user'] ?? '',
              'isUser': true,
              'timestamp': entry['timestamp'] != null
                  ? DateTime.tryParse(entry['timestamp'])
                  : DateTime.now(),
            });
            _messages.add({
              'message': entry['assistant'] ?? '',
              'isUser': false,
              'timestamp': entry['timestamp'] != null
                  ? DateTime.tryParse(entry['timestamp'])
                  : DateTime.now(),
            });
          }
          _isInitializing = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      LoggerService.error('Failed to load chat history', error: e);
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty || _isLoading) return;

    setState(() {
      _messages.add({
        'message': message,
        'isUser': true,
        'timestamp': DateTime.now(),
      });
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      // Prepare conversation history for API
      final conversationHistory = _messages
          .where((m) => m['isUser'] == true || m['isUser'] == false)
          .map((m) => m['isUser'] == true
              ? {'user': m['message']}
              : {'assistant': m['message']})
          .toList();

      final response = await _apiService.sendChatMessage(
        message,
        conversationHistory: conversationHistory,
      );

      if (mounted) {
        setState(() {
          _messages.add({
            'message': response['response'] ?? 'Maaf, terjadi kesalahan.',
            'isUser': false,
            'timestamp': DateTime.now(),
          });
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      LoggerService.error('Failed to send message', error: e);
      if (mounted) {
        setState(() {
          _messages.add({
            'message': 'Maaf, terjadi kesalahan saat mengirim pesan. Silakan coba lagi.',
            'isUser': false,
            'timestamp': DateTime.now(),
          });
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Hapus Riwayat',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Apakah Anda yakin ingin menghapus semua riwayat percakapan?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Hapus',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _apiService.clearChatHistory();
        if (mounted) {
          setState(() {
            _messages.clear();
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Riwayat percakapan telah dihapus'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        LoggerService.error('Failed to clear history', error: e);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menghapus riwayat'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Asisten Keuangan AI',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              onPressed: _clearHistory,
              tooltip: 'Hapus riwayat',
            ),
        ],
      ),
      body: _isInitializing
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                Expanded(
                  child: _messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 64,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Mulai percakapan dengan asisten AI',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tanyakan tentang keuangan Anda',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            return ChatMessageBubble(
                              message: message['message'] as String,
                              isUser: message['isUser'] as bool,
                              timestamp: message['timestamp'] as DateTime?,
                            );
                          },
                        ),
                ),
                ChatInputField(
                  onSend: _sendMessage,
                  isLoading: _isLoading,
                ),
              ],
            ),
    );
  }
}


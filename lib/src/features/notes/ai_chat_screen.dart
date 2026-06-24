import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../core/theme/app_theme.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/toast_utils.dart';
import '../../data/note.dart';
import 'package:gap/gap.dart';

import 'notes_controller.dart';

class AIChatScreen extends ConsumerStatefulWidget {
  const AIChatScreen({super.key, required this.note});
  final Note note;

  @override
  ConsumerState<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends ConsumerState<AIChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.note.chatHistory.isNotEmpty) {
      _messages.addAll(widget.note.chatHistory.map((m) => {
        'role': m['role']?.toString() ?? '',
        'content': m['content']?.toString() ?? '',
      }));
    } else {
      _messages.add({
        'role': 'assistant',
        'content': 'I\'ve analyzed "${widget.note.title}". What would you like to know about it?',
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _controller.clear();
      _isLoading = true;
    });

    try {
      final headers = await ref.read(authServiceProvider).getAuthHeaders(json: true);
      final response = await http.post(
        Uri.parse('${_baseUrl}/notes/${widget.note.id}/chat'),
        headers: headers,
        body: jsonEncode({'message': text}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final reply = data['reply'] as String? ?? '';
        if (mounted) {
          setState(() {
            _messages.add({'role': 'assistant', 'content': reply});
          });

          final updatedHistory = [
            ...widget.note.chatHistory,
            {'role': 'user', 'content': text},
            {'role': 'assistant', 'content': reply},
          ];

          await ref.read(notesControllerProvider.notifier).upsert(
            id: widget.note.id,
            title: widget.note.title,
            content: widget.note.content,
            chatHistory: updatedHistory,
          );
        }
      } else {
        final err = jsonDecode(response.body);
        throw Exception(err['message'] ?? 'AI chat failed.');
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showError(context, 'Could not get a response: ${e.toString().replaceAll('Exception: ', '')}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String get _baseUrl {
    final authService = ref.read(authServiceProvider);
    // Re-use the same env-loaded base URL as auth_service
    return authService.baseUrl;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        title: Column(
          children: [
            const Text('AI Chat', style: TextStyle(fontSize: 16)),
            Text(widget.note.title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return const _LoadingBubble();
                }
                final msg = _messages[index];
                return _ChatBubble(
                  content: msg['content']!,
                  isUser: msg['role'] == 'user',
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Ask anything about this note...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const Gap(8),
                  GestureDetector(
                    onTap: _isLoading ? null : _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isLoading ? Colors.grey : Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.content, required this.isUser});
  final String content;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser
              ? Colors.blue
              : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200]),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 20),
          ),
        ),
        child: Text(
          content,
          style: TextStyle(
            color: isUser ? Colors.white : (isDark ? Colors.white : Colors.black87),
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class _LoadingBubble extends StatelessWidget {
  const _LoadingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withOpacity(0.1)
              : Colors.grey[200],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
              strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.blue)),
        ),
      ),
    );
  }
}

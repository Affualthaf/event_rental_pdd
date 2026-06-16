import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';
import '../../services/firebase_service.dart';

class ChatDetailScreen extends StatefulWidget {
  final String partnerId;
  final String partnerName;

  const ChatDetailScreen({
    super.key,
    required this.partnerId,
    required this.partnerName,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _ctrl = TextEditingController();
  final _scrollController = ScrollController();
  
  String _currentUid = '';
  String _currentName = '';
  String _chatId = '';

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    final user = await FirebaseService().getCurrentUserProfile();
    if (user != null && mounted) {
      setState(() {
        _currentUid = user.id;
        _currentName = user.role == 'Vendor' && (user.shopName?.isNotEmpty ?? false) ? user.shopName! : user.name;
        _chatId = FirebaseService().getChatId(_currentUid, widget.partnerId);
      });
    }
  }

  void _sendMessage() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _currentUid.isEmpty) return;

    _ctrl.clear();
    
    await FirebaseService().sendMessage(
      uid1: _currentUid,
      uid2: widget.partnerId,
      text: text,
      senderName: _currentName,
      receiverName: widget.partnerName,
    );
    
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            title: widget.partnerName,
            subtitle: 'Online',
            leading: IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
              child: _chatId.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                  : StreamBuilder<List<Map<String, dynamic>>>(
                      stream: FirebaseService().getMessages(_chatId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: AppColors.accent));
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                          );
                        }
                        
                        final messages = snapshot.data ?? [];
                        
                        // Scroll to bottom when new messages arrive
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (_scrollController.hasClients) {
                            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                          }
                        });

                        return ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                          itemCount: messages.length,
                          itemBuilder: (_, i) {
                            final m = messages[i];
                            final isMe = m['senderId'] == _currentUid;
                            final text = m['text'] as String? ?? '';
                            
                            // Format timestamp
                            String timeStr = '';
                            final tsStr = m['timestamp'] as String?;
                            if (tsStr != null) {
                              try {
                                final dt = DateTime.parse(tsStr).toLocal();
                                timeStr = DateFormat('h:mm a').format(dt);
                              } catch (_) {}
                            }

                            return Align(
                              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                                decoration: BoxDecoration(
                                  gradient: isMe
                                      ? const LinearGradient(colors: [AppColors.accent, AppColors.accentDark])
                                      : null,
                                  color: isMe ? null : Colors.white.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(16),
                                  border: isMe ? null : Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                ),
                                child: Column(
                                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                  children: [
                                    Text(text,
                                        style: TextStyle(
                                            color: isMe ? Colors.white : AppColors.textPrimary,
                                            fontSize: 14)),
                                    if (timeStr.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(timeStr,
                                          style: TextStyle(
                                              fontSize: 10,
                                              color: isMe ? Colors.white.withValues(alpha: 0.7) : AppColors.textSecondary)),
                                    ]
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF11102A),
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
            ),
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).padding.bottom + 12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    style: const TextStyle(color: Colors.white),
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.04),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [AppColors.accent, AppColors.accentDark]),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
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

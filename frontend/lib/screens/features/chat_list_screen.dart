import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';
import '../../services/firebase_service.dart';
import '../../models/user_model.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  bool _isVendor = false;
  String _uid = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text.trim();
      });
    });
    _checkRole();
  }

  Future<void> _checkRole() async {
    final user = await FirebaseService().getCurrentUserProfile();
    if (user != null) {
      if (mounted) {
        setState(() {
          _isVendor = user.role == 'Vendor';
          _uid = user.id;
        });
        if (!_isVendor && user.location.isNotEmpty && user.location != 'Not set') {
          _searchCtrl.text = user.location;
        }
      }
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_uid.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          _isVendor ? _buildVendorHeader() : _buildCustomerHeader(),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
              child: _isVendor ? _buildVendorInbox() : _buildCustomerSearch(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerHeader() {
    return GradientHeader(
      title: 'Chat with Vendors',
      subtitle: 'Find vendors in your city to chat',
      leading: IconButton(
        onPressed: () => context.go('/home'),
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
      ),
      bottom: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: TextField(
          controller: _searchCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search city name...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                    onPressed: () => _searchCtrl.clear(),
                  )
                : null,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildVendorHeader() {
    return GradientHeader(
      title: 'Inbox',
      subtitle: 'Customer conversations',
      leading: IconButton(
        onPressed: () => context.go('/home'),
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildCustomerSearch() {
    return StreamBuilder<List<UserModel>>(
      stream: FirebaseService().getVendorsByCity(_searchQuery),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.accent));
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
          );
        }
        
        final vendors = snapshot.data ?? [];
        if (vendors.isEmpty) {
          return const Center(
            child: Text('No vendors found for this city.\nTry a different search term.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: vendors.length,
          itemBuilder: (context, index) {
            final vendor = vendors[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                onTap: () {
                  context.push(
                    '/chat-detail',
                    extra: {
                      'partnerId': vendor.id,
                      'partnerName': (vendor.shopName?.isNotEmpty ?? false) ? vendor.shopName! : vendor.name,
                    },
                  );
                },
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.storefront_rounded, color: AppColors.accent, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text((vendor.shopName?.isNotEmpty ?? false) ? vendor.shopName! : vendor.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                          const SizedBox(height: 4),
                          Text('${vendor.location} • ${vendor.pincode}',
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.textSecondary),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVendorInbox() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirebaseService().getUserChats(_uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.accent));
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
          );
        }
        
        final chats = snapshot.data ?? [];
        if (chats.isEmpty) {
          return const Center(
            child: Text('No messages yet.\nWhen customers contact you, they will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: chats.length,
          itemBuilder: (context, index) {
            final chat = chats[index];
            
            final participantNames = chat['participantNames'] as Map<String, dynamic>? ?? {};
            
            // Find the partner's ID (the one that is not _uid)
            final participants = List<String>.from(chat['participants'] ?? []);
            final partnerId = participants.firstWhere((p) => p != _uid, orElse: () => '');
            final partnerName = participantNames[partnerId] ?? 'Unknown Customer';
            
            final lastMessage = chat['lastMessage'] as String? ?? '';
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                onTap: () {
                  context.push(
                    '/chat-detail',
                    extra: {
                      'partnerId': partnerId,
                      'partnerName': partnerName,
                    },
                  );
                },
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Icon(Icons.person_rounded, color: Colors.blue, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(partnerName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                          const SizedBox(height: 4),
                          Text(lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

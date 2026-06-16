import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firebase_service.dart';
import '../../models/user_model.dart';
import '../../models/order_model.dart';

// ─── Notification helpers ─────────────────────────────────────────────────────

/// Converts an [OrderModel] into a display-friendly notification map.
/// [isVendor] = true → a new-order alert; false → an order-status-update alert.
Map<String, dynamic> _orderToNotif(OrderModel order, {required bool isVendor}) {
  if (isVendor) {
    return {
      'icon': Icons.shopping_bag_outlined,
      'color': AppColors.accent,
      'title': 'New Order Received',
      'body': '${order.customerName} placed an order for ${order.items.map((i) => i.name).join(', ')}.',
      'time': _timeAgo(order.createdAt),
    };
  }

  // Customer — map status to icon/colour/title
  final statusMap = {
    'Processing':      (Icons.hourglass_top_rounded,    Colors.orange,       'Order Placed'),
    'Confirmed':       (Icons.check_circle_outline,     Colors.green,        'Order Confirmed'),
    'Prepared':        (Icons.inventory_2_outlined,     AppColors.accent,    'Order Prepared'),
    'Out for Delivery':(Icons.local_shipping_outlined,  AppColors.primary,   'Out for Delivery'),
    'Delivered':       (Icons.done_all_rounded,         Colors.teal,         'Order Delivered'),
    'Rejected':        (Icons.cancel_outlined,          Colors.redAccent,    'Order Rejected'),
  };

  final entry = statusMap[order.status] ??
      (Icons.info_outline, AppColors.textSecondary as Color, order.status);
  final itemNames = order.items.map((i) => i.name).join(', ');

  return {
    'icon':  entry.$1,
    'color': entry.$2,
    'title': entry.$3,
    'body':  'Order #${order.id.substring(0, 8).toUpperCase()} — $itemNames',
    'time':  _timeAgo(order.createdAt),
  };
}

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} hr ago';
  if (diff.inDays < 7) return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
  return '${(diff.inDays / 7).floor()} wk ago';
}

// ─── Notifications Screen ─────────────────────────────────────────────────────
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = FirebaseService();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            title: 'Notifications',
            leading: IconButton(
              onPressed: () => context.go('/home'),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
              child: StreamBuilder<UserModel?>(
                stream: service.userProfileStream(),
                builder: (context, userSnap) {
                  if (userSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final user = userSnap.data;
                  final isVendor = user?.role == 'Vendor';

                  final ordersStream = isVendor
                      ? service.getOrdersForVendor(uid)
                      : service.getCustomerOrders(uid);

                  return StreamBuilder<List<OrderModel>>(
                    stream: ordersStream,
                    builder: (context, ordersSnap) {
                      if (ordersSnap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final orders = ordersSnap.data ?? [];

                      if (orders.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.notifications_none_rounded,
                                    color: AppColors.accent, size: 40),
                              ),
                              const SizedBox(height: 16),
                              const Text('No notifications yet',
                                  style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary)),
                              const SizedBox(height: 6),
                              const Text('Your order updates will appear here.',
                                  style: TextStyle(
                                      fontSize: 13, color: AppColors.textSecondary)),
                            ],
                          ),
                        );
                      }

                      final notifs = orders
                          .map((o) => _orderToNotif(o, isVendor: isVendor))
                          .toList();

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                        itemCount: notifs.length,
                        itemBuilder: (_, i) {
                          final n = notifs[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GlassCard(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: (n['color'] as Color).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(n['icon'] as IconData,
                                        color: n['color'] as Color, size: 26),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Flexible(
                                              child: Text(n['title'] as String,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 15,
                                                      color: AppColors.textPrimary)),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(n['time'] as String,
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                    color: AppColors.textSecondary)),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(n['body'] as String,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontSize: 13,
                                                height: 1.4,
                                                color: AppColors.textSecondary)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// ─── Support Screen ───────────────────────────────────────────────────────────
class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = [
      {'q': 'How do I cancel a booking?', 'a': 'You can cancel up to 48 hours before delivery for a full refund.'},
      {'q': 'What is the delivery area?', 'a': 'We currently deliver within a 50-mile radius of major city centers.'},
      {'q': 'Can I extend my rental?', 'a': 'Yes! Contact us or use the app to extend before your return date.'},
      {'q': 'What if equipment is damaged?', 'a': 'We offer insurance coverage for accidental damage during rental.'},
    ];

    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            title: 'Support',
            subtitle: 'How can we help you?',
            leading: IconButton(
              onPressed: () => context.go('/home'),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Contact options
                  Row(children: [
                    Expanded(
                      child: GlassCard(
                        onTap: () => context.go('/chat'),
                        child: const Column(
                          children: [
                            Icon(Icons.chat_bubble_outline, color: AppColors.accent, size: 28),
                            SizedBox(height: 8),
                            Text('Live Chat', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('Online now', style: TextStyle(fontSize: 12, color: Colors.green)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GlassCard(
                        child: const Column(
                          children: [
                            Icon(Icons.phone_outlined, color: AppColors.accent, size: 28),
                            SizedBox(height: 8),
                            Text('Call Us', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('Mon-Fri 9-6', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  const SectionHeader(title: 'FAQs'),
                  const SizedBox(height: 12),
                  ...faqs.map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GlassCard(
                          child: ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            title: Text(f['q']!,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: AppColors.textPrimary)),
                            children: [
                              Text(f['a']!,
                                  style: const TextStyle(
                                      color: AppColors.textSecondary, fontSize: 13))
                            ],
                          ),
                        ),
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Profile Screen ───────────────────────────────────────────────────────────
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = FirebaseService();

    return Scaffold(
      body: StreamBuilder<UserModel?>(
        stream: service.userProfileStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data;
          final info = [
            {'icon': Icons.mail_outline, 'label': 'Email', 'value': user?.email ?? 'Not set'},
            {'icon': Icons.phone_outlined, 'label': 'Phone', 'value': user?.phone ?? 'Not set'},
            {'icon': Icons.location_on_outlined, 'label': 'Location', 'value': user?.location ?? 'Not set'},
            if (user?.role == 'Vendor') ...[
              {'icon': Icons.store_outlined, 'label': 'Shop Name', 'value': user?.shopName ?? 'Not set'},
              {'icon': Icons.pin_drop_outlined, 'label': 'Pincode', 'value': user?.pincode ?? 'Not set'},
            ],
          ];

          return Column(
            children: [
              GradientHeader(
                title: 'My Profile',
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
                    children: [
                      GlassCard(
                        child: Column(
                          children: [
                            Container(
                              width: 96,
                              height: 96,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                    colors: [AppColors.accent, AppColors.accentDark]),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.person_rounded,
                                  color: Colors.white, size: 52),
                            ),
                            const SizedBox(height: 14),
                            Text(user?.name ?? 'Guest User',
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary)),
                            Text(user?.role ?? 'Account',
                                style: const TextStyle(color: AppColors.textSecondary)),
                            const SizedBox(height: 16),
                            ...info.map((item) => Container(
                             margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.04),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
                                  child: Row(
                                    children: [
                                      Icon(item['icon'] as IconData,
                                          color: AppColors.accent, size: 20),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(item['label'] as String,
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.textSecondary)),
                                          Text(item['value'] as String,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.textPrimary)),
                                        ],
                                      ),
                                    ],
                                  ),
                                )),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 2.5,
                        children: [
                          GlassCard(
                            onTap: () {},
                            child: const Row(
                              children: [
                                Icon(Icons.edit_outlined, color: AppColors.accent),
                                SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Edit Profile',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    Text('Update info',
                                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          GlassCard(
                            onTap: () {},
                            child: const Row(
                              children: [
                                Icon(Icons.shield_outlined, color: AppColors.accent),
                                SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Security',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    Text('Password & 2FA',
                                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AppButton(
                        text: 'Sign Out',
                        variant: ButtonVariant.danger,
                        fullWidth: true,
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          if (context.mounted) {
                            context.go('/login');
                          }
                        },
                        icon: const Icon(Icons.logout_rounded, color: Colors.red, size: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── AI Recommendations ───────────────────────────────────────────────────────
class AiRecommendationsScreen extends StatelessWidget {
  const AiRecommendationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final recs = [
      {'emoji': '🎤', 'name': 'Wireless Mic Array', 'reason': 'Based on your recent PA System rental', 'price': '\$95/day', 'match': '98%'},
      {'emoji': '💡', 'name': 'Intelligent Moving Heads', 'reason': 'Popular with your event type', 'price': '\$180/day', 'match': '94%'},
      {'emoji': '🎛️', 'name': 'Digital Mixing Console', 'reason': 'Complements your existing gear', 'price': '\$120/day', 'match': '90%'},
    ];

    return Scaffold(
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF9C27B0)],
              ),
            ),
            child: GradientHeader(
              title: 'AI Recommendations',
              subtitle: '✨ Personalized for you',
              leading: IconButton(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  GlassCard(
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [Color(0xFF6C63FF), Color(0xFF9C27B0)]),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.auto_awesome,
                              color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Text(
                            'Our AI has analyzed your booking history and preferences to curate these recommendations.',
                            style: TextStyle(
                                fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...recs.map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GlassCard(
                          onTap: () => context.go('/equipment-listing'),
                          child: Row(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [
                                    AppColors.accent.withValues(alpha: 0.15),
                                    AppColors.primary.withValues(alpha: 0.15),
                                  ]),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(r['emoji'] as String,
                                      style: const TextStyle(fontSize: 32)),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(r['name'] as String,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary)),
                                    const SizedBox(height: 2),
                                    Text(r['reason'] as String,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary)),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Text(r['price'] as String,
                                            style: const TextStyle(
                                                color: AppColors.accent,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13)),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade50,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text('${r['match']} match',
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green.shade700)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded,
                                  color: AppColors.textSecondary),
                            ],
                          ),
                        ),
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';
import '../../services/firebase_service.dart';
import '../../models/user_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final service = FirebaseService();
    return StreamBuilder<UserModel?>(
      stream: service.userProfileStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
          );
        }

        final user = snapshot.data;
        final isVendor = user?.role == 'Vendor';

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: GradientHeader(
                    title: user != null ? 'Hello, ${user.name.split(' ')[0]}!' : 'EventSphere',
                    subtitle: isVendor
                        ? 'Shop: ${user?.shopName ?? "Verified Partner"}'
                        : (user != null ? 'Ready to plan your next event?' : 'Your Event Equipment Partner'),
                    trailing: Row(
                      children: [
                        IconButton(
                          onPressed: () => context.go('/notifications'),
                          icon: const Badge(
                            label: Text('2'),
                            child: Icon(Icons.notifications_none_rounded, color: Colors.white, size: 28),
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => context.go('/profile'),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                            ),
                            child: const Icon(Icons.person_rounded, color: Colors.white, size: 24),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isVendor) ...[

                  // ─── Vendor Services Grid ───────────────────
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const SectionHeader(title: 'Quick Actions'),
                        const SizedBox(height: 16),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.15,
                          children: [
                            _HomeServiceCard(
                              icon: Icons.storefront_rounded,
                              title: 'Inventory',
                              subtitle: 'Manage shop items',
                              gradient: const [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                              onTap: () => context.push('/vendor-items/${user?.id ?? "mock_vendor_1"}'),
                            ),
                            _HomeServiceCard(
                              icon: Icons.assignment_turned_in_outlined,
                              title: 'Orders',
                              subtitle: 'View rental requests',
                              gradient: const [Color(0xFFEC4899), Color(0xFFEF4444)],
                              onTap: () => context.go('/vendor-orders'),
                            ),
                            _HomeServiceCard(
                              icon: Icons.forum_outlined,
                              title: 'Inbox',
                              subtitle: 'Chat with customers',
                              gradient: const [Color(0xFF3B82F6), Color(0xFF10B981)],
                              onTap: () => context.go('/chat'),
                            ),
                            _HomeServiceCard(
                              icon: Icons.settings_outlined,
                              title: 'Settings',
                              subtitle: 'Shop & profile info',
                              gradient: const [Color(0xFFF59E0B), Color(0xFFF97316)],
                              onTap: () => context.go('/profile'),
                            ),
                          ],
                        ),
                      ]),
                    ),
                  ),
                ] else ...[
                  // ─── Customer Services Grid ───────────────────
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const SectionHeader(title: 'Our Services'),
                        const SizedBox(height: 20),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.15,
                          children: [
                            _HomeServiceCard(
                              icon: Icons.search_rounded,
                              title: 'Search',
                              subtitle: 'Find local vendors',
                              gradient: const [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                              onTap: () => context.go('/categories'),
                            ),
                            _HomeServiceCard(
                              icon: Icons.local_shipping_outlined,
                              title: 'Track',
                              subtitle: 'Live order status',
                              gradient: const [Color(0xFFEC4899), Color(0xFFEF4444)],
                              onTap: () => context.go('/order-tracking'),
                            ),
                            _HomeServiceCard(
                              icon: Icons.chat_bubble_outline_rounded,
                              title: 'Chat',
                              subtitle: 'Contact partners',
                              gradient: const [Color(0xFF3B82F6), Color(0xFF10B981)],
                              onTap: () => context.go('/chat'),
                            ),
                            _HomeServiceCard(
                              icon: Icons.person_outline_rounded,
                              title: 'Profile',
                              subtitle: 'Settings & account',
                              gradient: const [Color(0xFFF59E0B), Color(0xFFF97316)],
                              onTap: () => context.go('/profile'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // ─── Premium AI Recommendation Banner ───
                        const SectionHeader(title: 'Recommended For You'),
                        const SizedBox(height: 16),
                        GlassCard(
                          onTap: () => context.go('/ai-recommendations'),
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF8B5CF6), Color(0xFFD946EF)],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.auto_awesome,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Smart AI Planner',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Discover recommended equipment for your event matching your preferences.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: AppColors.textSecondary,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ]),
                    ),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 110)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HomeServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _HomeServiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradient,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: gradient[0].withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.textSecondary,
                size: 14,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

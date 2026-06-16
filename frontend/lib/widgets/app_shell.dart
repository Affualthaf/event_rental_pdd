import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../services/firebase_service.dart';
import '../models/user_model.dart';

// ─── Navigation Destination Model ────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}

const _customerNavItems = [
  _NavItem(
    icon: Icons.home_outlined,
    activeIcon: Icons.home_rounded,
    label: 'Home',
    route: '/home',
  ),
  _NavItem(
    icon: Icons.search_rounded,
    activeIcon: Icons.search_rounded,
    label: 'Search',
    route: '/categories',
  ),
  _NavItem(
    icon: Icons.local_shipping_outlined,
    activeIcon: Icons.local_shipping_rounded,
    label: 'Track',
    route: '/order-tracking',
  ),
  _NavItem(
    icon: Icons.chat_bubble_outline_rounded,
    activeIcon: Icons.chat_bubble_rounded,
    label: 'Chat',
    route: '/chat',
  ),
  _NavItem(
    icon: Icons.person_outline_rounded,
    activeIcon: Icons.person_rounded,
    label: 'Profile',
    route: '/profile',
  ),
];

const _vendorNavItems = [
  _NavItem(
    icon: Icons.home_outlined,
    activeIcon: Icons.home_rounded,
    label: 'Home',
    route: '/home',
  ),
  _NavItem(
    icon: Icons.add_box_outlined,
    activeIcon: Icons.add_box_rounded,
    label: 'Add Item',
    route: '/add-product',
  ),
  _NavItem(
    icon: Icons.local_shipping_outlined,
    activeIcon: Icons.local_shipping_rounded,
    label: 'Bookings',
    route: '/vendor-orders',
  ),
  _NavItem(
    icon: Icons.chat_bubble_outline_rounded,
    activeIcon: Icons.chat_bubble_rounded,
    label: 'Chat',
    route: '/chat',
  ),
  _NavItem(
    icon: Icons.person_outline_rounded,
    activeIcon: Icons.person_rounded,
    label: 'Profile',
    route: '/profile',
  ),
];

// ─── AppShell ─────────────────────────────────────────────────────────────────
class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  int _currentIndex(BuildContext context, List<_NavItem> items) {
    final location = GoRouterState.of(context).uri.path;
    for (int i = 0; i < items.length; i++) {
      if (location.startsWith(items[i].route)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final service = FirebaseService();
    return StreamBuilder<UserModel?>(
      stream: service.userProfileStream(),
      builder: (context, snapshot) {
        final isVendor = snapshot.data?.role == 'Vendor';
        final navItems = isVendor ? _vendorNavItems : _customerNavItems;
        final currentIndex = _currentIndex(context, navItems);

        return Scaffold(
          backgroundColor: AppColors.background,
          extendBody: true,
          body: child,
          bottomNavigationBar: _FloatingNavBar(
            currentIndex: currentIndex,
            items: navItems,
            onTap: (i) {
              HapticFeedback.lightImpact();
              context.go(navItems[i].route);
            },
          ),
        );
      },
    );
  }
}

// ─── Floating Nav Bar ─────────────────────────────────────────────────────────
class _FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  const _FloatingNavBar({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPadding + 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF11102A).withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.10),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                  blurRadius: 32,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, (i) {
                return _NavButton(
                  item: items[i],
                  isActive: i == currentIndex,
                  onTap: () => onTap(i),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Nav Button ───────────────────────────────────────────────────────────────
class _NavButton extends StatefulWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _glowAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );

    if (widget.isActive) _ctrl.forward();
  }

  @override
  void didUpdateWidget(_NavButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _ctrl.forward();
    } else if (!widget.isActive && oldWidget.isActive) {
      _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          return SizedBox(
            width: 64,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon container with animated glow pill
                Transform.scale(
                  scale: _scaleAnim.value,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    width: widget.isActive ? 48 : 40,
                    height: widget.isActive ? 36 : 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: widget.isActive
                          ? const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF8B5CF6),
                                Color(0xFFEC4899),
                              ],
                            )
                          : null,
                      color: widget.isActive ? null : Colors.transparent,
                      boxShadow: widget.isActive
                          ? [
                              BoxShadow(
                                color: const Color(0xFF8B5CF6)
                                    .withValues(alpha: 0.5 * _glowAnim.value),
                                blurRadius: 16,
                                spreadRadius: 2,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      widget.isActive
                          ? widget.item.activeIcon
                          : widget.item.icon,
                      size: 22,
                      color: widget.isActive
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.45),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Animated label
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 250),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: widget.isActive
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: widget.isActive
                        ? const Color(0xFFA78BFA)
                        : Colors.white.withValues(alpha: 0.35),
                    letterSpacing: widget.isActive ? 0.3 : 0,
                  ),
                  child: Text(widget.item.label),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

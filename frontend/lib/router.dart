
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'models/order_model.dart';
import 'widgets/app_shell.dart';
import 'screens/vendor/vendor_add_product_screen.dart';
import 'screens/vendor/vendor_order_tracking_screen.dart';

import 'screens/auth/splash_screen.dart';
import 'screens/auth/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/forgot_password_screen.dart';

import 'screens/customer/home_screen.dart';
import 'screens/customer/categories_screen.dart';
import 'screens/customer/equipment_listing_screen.dart';
import 'screens/customer/equipment_detail_screen.dart';
import 'screens/customer/availability_calendar_screen.dart';
import 'screens/customer/cart_screen.dart';
import 'screens/customer/checkout_screen.dart';
import 'screens/customer/payment_screen.dart';
import 'screens/customer/order_confirmation_screen.dart';
import 'screens/customer/order_tracking_screen.dart';
import 'screens/customer/booking_history_screen.dart';
import 'screens/customer/vendor_items_screen.dart';

import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/admin_users_screen.dart';
import 'screens/admin/admin_vendor_approval_screen.dart';
import 'screens/admin/admin_reports_screen.dart';

import 'screens/features/notifications_screen.dart';
import 'screens/features/chat_list_screen.dart';
import 'screens/features/chat_detail_screen.dart';
import 'screens/features/chat_screen.dart';
import 'screens/features/support_screen.dart';
import 'screens/features/profile_screen.dart';
import 'screens/features/ai_recommendations_screen.dart';

/// Public routes that don't require authentication.
const _publicRoutes = [
  '/splash',
  '/onboarding-1',
  '/onboarding-2',
  '/onboarding-3',
  '/login',
  '/signup',
  '/forgot-password',
];

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  redirect: (context, state) {
    final loggedIn = FirebaseAuth.instance.currentUser != null;
    final path = state.uri.path;
    final isPublic = _publicRoutes.any((r) => path.startsWith(r));

    // Unauthenticated user trying to reach a protected route → send to login.
    if (!loggedIn && !isPublic) return '/login';

    // Authenticated user trying to reach login or signup → send home.
    if (loggedIn && (path == '/login' || path == '/signup')) return '/home';

    return null; // no redirect needed
  },
  routes: [
    // ── Auth / Onboarding (no shell) ─────────────────────────────────────────
    GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/onboarding-1', builder: (_, __) => const OnboardingScreen(page: 1)),
    GoRoute(path: '/onboarding-2', builder: (_, __) => const OnboardingScreen(page: 2)),
    GoRoute(path: '/onboarding-3', builder: (_, __) => const OnboardingScreen(page: 3)),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (_, __) => const SignUpScreen()),
    GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),

    // ── Main shell with floating bottom nav ──────────────────────────────────
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/categories', builder: (_, __) => const CategoriesScreen()),
        GoRoute(path: '/add-product', builder: (_, __) => const VendorAddProductScreen()),
        GoRoute(path: '/vendor-orders', builder: (_, __) => const VendorOrderTrackingScreen()),
        GoRoute(
          path: '/order-tracking',
          builder: (_, state) => OrderTrackingScreen(orderId: state.extra as String?),
        ),
        GoRoute(path: '/chat', builder: (_, __) => const ChatListScreen()),
        GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      ],
    ),

    // ── Customer sub-screens (no shell, full screen) ──────────────────────────
    GoRoute(path: '/equipment-listing', builder: (_, __) => const EquipmentListingScreen()),
    GoRoute(
      path: '/vendor-items/:id',
      builder: (_, state) => VendorItemsScreen(vendorId: state.pathParameters['id'] ?? ''),
    ),
    GoRoute(
      path: '/equipment-detail/:id',
      builder: (_, state) => EquipmentDetailScreen(id: state.pathParameters['id'] ?? '1'),
    ),
    GoRoute(path: '/availability-calendar', builder: (_, __) => const AvailabilityCalendarScreen()),
    GoRoute(path: '/cart', builder: (_, __) => const CartScreen()),
    GoRoute(path: '/checkout', builder: (_, __) => const CheckoutScreen()),
    GoRoute(
      path: '/payment',
      builder: (_, state) => PaymentScreen(order: state.extra as OrderModel?),
    ),
    GoRoute(path: '/order-confirmation', builder: (_, __) => const OrderConfirmationScreen()),
    GoRoute(path: '/booking-history', builder: (_, __) => const BookingHistoryScreen()),

    // ── Admin (no shell) ─────────────────────────────────────────────────────
    GoRoute(path: '/admin-dashboard', builder: (_, __) => const AdminDashboardScreen()),
    GoRoute(path: '/admin-users', builder: (_, __) => const AdminUsersScreen()),
    GoRoute(path: '/admin-vendor-approval', builder: (_, __) => const AdminVendorApprovalScreen()),
    GoRoute(path: '/admin-reports', builder: (_, __) => const AdminReportsScreen()),

    // ── Feature screens (no shell) ────────────────────────────────────────────
    GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
    GoRoute(path: '/support', builder: (_, __) => const SupportScreen()),
    GoRoute(path: '/ai-recommendations', builder: (_, __) => const AiRecommendationsScreen()),
    GoRoute(
      path: '/chat-detail',
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return ChatDetailScreen(
          partnerId: extra['partnerId'] as String? ?? '',
          partnerName: extra['partnerName'] as String? ?? 'User',
        );
      },
    ),
  ],
);

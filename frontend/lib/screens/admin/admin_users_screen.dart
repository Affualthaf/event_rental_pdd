import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';

// ─── Admin Users ──────────────────────────────────────────────────────────────
class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  static const _users = [
    {'name': 'Alice Johnson', 'email': 'alice@example.com', 'role': 'Customer', 'status': 'Active'},
    {'name': 'Bob Smith', 'email': 'bob@example.com', 'role': 'Vendor', 'status': 'Active'},
    {'name': 'Carol White', 'email': 'carol@example.com', 'role': 'Customer', 'status': 'Suspended'},
    {'name': 'David Brown', 'email': 'david@example.com', 'role': 'Vendor', 'status': 'Pending'},
    {'name': 'Eve Davis', 'email': 'eve@example.com', 'role': 'Customer', 'status': 'Active'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            title: 'User Management',
            subtitle: '${_users.length} users',
            leading: IconButton(
              onPressed: () => context.go('/admin-dashboard'),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            ),
            trailing: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.person_add_outlined, color: Colors.white),
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _users.length,
                itemBuilder: (_, i) {
                  final u = _users[i];
                  final statusColor = switch (u['status']) {
                    'Active' => Colors.green,
                    'Suspended' => Colors.red,
                    _ => Colors.orange,
                  };
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlassCard(
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.accent.withValues(alpha: 0.15),
                            child: Text(u['name']![0],
                                style: const TextStyle(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(u['name']!,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary)),
                                Text(u['email']!,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(u['status']!,
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: statusColor)),
                              ),
                              const SizedBox(height: 4),
                              Text(u['role']!,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                        ],
                      ),
                    ),
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

// ─── Admin Vendor Approval ────────────────────────────────────────────────────
class AdminVendorApprovalScreen extends StatelessWidget {
  const AdminVendorApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vendors = [
      {'name': 'SoundPro Rentals', 'owner': 'Mike Johnson', 'items': '45 items', 'status': 'Pending'},
      {'name': 'Bright Lights Co.', 'owner': 'Sarah Lee', 'items': '32 items', 'status': 'Pending'},
      {'name': 'Stage Masters', 'owner': 'Tom Baker', 'items': '18 items', 'status': 'Under Review'},
    ];

    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            title: 'Vendor Approval',
            leading: IconButton(
              onPressed: () => context.go('/admin-dashboard'),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: vendors.length,
                itemBuilder: (_, i) {
                  final v = vendors[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                      colors: [AppColors.accent, AppColors.accentDark]),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.store_outlined,
                                    color: Colors.white, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(v['name']!,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary)),
                                    Text('${v['owner']} • ${v['items']}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(v['status']!,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.orange)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: AppButton(
                                  text: 'Approve',
                                  variant: ButtonVariant.primary,
                                  size: ButtonSize.sm,
                                  onPressed: () {},
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: AppButton(
                                  text: 'Reject',
                                  variant: ButtonVariant.danger,
                                  size: ButtonSize.sm,
                                  onPressed: () {},
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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

// ─── Admin Reports ────────────────────────────────────────────────────────────
class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reports = [
      {'title': 'Monthly Revenue', 'value': '\$125,400', 'change': '+23%', 'icon': Icons.trending_up, 'up': true},
      {'title': 'New Users (May)', 'value': '1,234', 'change': '+12%', 'icon': Icons.person_add, 'up': true},
      {'title': 'Orders Completed', 'value': '847', 'change': '+18%', 'icon': Icons.check_circle_outline, 'up': true},
      {'title': 'Avg Order Value', 'value': '\$1,480', 'change': '+6%', 'icon': Icons.receipt_outlined, 'up': true},
      {'title': 'Cancellations', 'value': '23', 'change': '-8%', 'icon': Icons.cancel_outlined, 'up': false},
      {'title': 'Support Tickets', 'value': '156', 'change': '+4%', 'icon': Icons.support_outlined, 'up': false},
    ];

    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            title: 'Reports & Analytics',
            leading: IconButton(
              onPressed: () => context.go('/admin-dashboard'),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2,
                ),
                itemCount: reports.length,
                itemBuilder: (_, i) {
                  final r = reports[i];
                  final up = r['up'] as bool;
                  return GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(r['icon'] as IconData, color: AppColors.accent, size: 24),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: up ? Colors.green.shade50 : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(r['change'] as String,
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: up ? Colors.green.shade700 : Colors.red.shade700)),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(r['value'] as String,
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 4),
                        Text(r['title'] as String,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
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

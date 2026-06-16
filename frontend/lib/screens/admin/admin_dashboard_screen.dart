import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = [
      {'label': 'Total Users', 'value': '12,345', 'icon': Icons.people_outline, 'colors': [const Color(0xFF3B82F6), const Color(0xFF2563EB)], 'change': '+12%'},
      {'label': 'Equipment', 'value': '856', 'icon': Icons.inventory_2_outlined, 'colors': [const Color(0xFF10B981), const Color(0xFF059669)], 'change': '+8%'},
      {'label': 'Revenue', 'value': '\$125K', 'icon': Icons.attach_money_rounded, 'colors': [const Color(0xFF9333EA), const Color(0xFF7C3AED)], 'change': '+23%'},
      {'label': 'Deliveries', 'value': '42', 'icon': Icons.local_shipping_outlined, 'colors': [const Color(0xFFF97316), const Color(0xFFEA580C)], 'change': '+5%'},
    ];

    final revenueSpots = [
      FlSpot(0, 45),
      FlSpot(1, 52),
      FlSpot(2, 61),
      FlSpot(3, 73),
      FlSpot(4, 85),
    ];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: GradientHeader(
              title: 'Admin Dashboard',
              subtitle: 'EventSphere Platform Analytics',
              trailing: Row(
                children: [
                  IconButton(
                    onPressed: () => context.go('/notifications'),
                    icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                  ),
                  IconButton(
                    onPressed: () => context.go('/profile'),
                    icon: const Icon(Icons.person_outline, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Stats Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.3,
                  ),
                  itemCount: stats.length,
                  itemBuilder: (_, i) {
                    final s = stats[i];
                    return StatCard(
                      label: s['label'] as String,
                      value: s['value'] as String,
                      icon: s['icon'] as IconData,
                      colors: s['colors'] as List<Color>,
                      change: s['change'] as String,
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Revenue Chart
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Revenue Overview',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              getDrawingHorizontalLine: (_) => FlLine(
                                  color: Colors.white.withValues(alpha: 0.06), strokeWidth: 1),
                              drawVerticalLine: false,
                            ),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (v, _) {
                                    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May'];
                                    final i = v.toInt();
                                    return i >= 0 && i < months.length
                                        ? Text(months[i],
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textSecondary))
                                        : const SizedBox();
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: revenueSpots,
                                isCurved: true,
                                color: AppColors.accent,
                                barWidth: 3,
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: AppColors.accent.withValues(alpha: 0.15),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Quick links
                const SectionHeader(title: 'Quick Actions'),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.1,
                  children: [
                    _AdminLink(icon: Icons.people_alt_outlined, label: 'Users', onTap: () => context.go('/admin-users')),
                    _AdminLink(icon: Icons.verified_outlined, label: 'Vendors', onTap: () => context.go('/admin-vendor-approval')),
                    _AdminLink(icon: Icons.bar_chart_rounded, label: 'Reports', onTap: () => context.go('/admin-reports')),
                    _AdminLink(icon: Icons.inventory_outlined, label: 'Inventory', onTap: () {}),
                    _AdminLink(icon: Icons.receipt_long_outlined, label: 'Orders', onTap: () {}),
                    _AdminLink(icon: Icons.local_shipping_outlined, label: 'Logistics', onTap: () {}),
                  ],
                ),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _AdminLink({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.accent, size: 28),
          const SizedBox(height: 6),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

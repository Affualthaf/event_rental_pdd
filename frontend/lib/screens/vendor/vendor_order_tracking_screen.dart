import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';
import '../../services/firebase_service.dart';
import '../../models/order_model.dart';
import 'package:url_launcher/url_launcher.dart';

// ─── Tracking steps shared between vendor & customer views ────────────────────
const _trackingLabels = [
  'Order Placed',
  'Order Confirmed',
  'Equipment Prepared',
  'Out for Delivery',
  'Delivered',
];

const _trackingIcons = [
  Icons.shopping_bag_outlined,
  Icons.check_circle_outline_rounded,
  Icons.inventory_2_outlined,
  Icons.local_shipping_outlined,
  Icons.home_rounded,
];

// ─── Vendor Order Tracking Screen ─────────────────────────────────────────────
class VendorOrderTrackingScreen extends StatefulWidget {
  const VendorOrderTrackingScreen({super.key});

  @override
  State<VendorOrderTrackingScreen> createState() =>
      _VendorOrderTrackingScreenState();
}

class _VendorOrderTrackingScreenState
    extends State<VendorOrderTrackingScreen> {
  final _service = FirebaseService();
  String _filterStatus = 'All';

  static const _filters = ['All', 'Pending', 'Confirmed', 'Delivered', 'Rejected'];

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: Column(
          children: [
            const GradientHeader(
              title: 'Bookings',
              subtitle: 'Manage customer orders',
            ),

            // ── Filter Chips ──────────────────────────────────────────────────
            SizedBox(
              height: 52,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final f = _filters[i];
                  final selected = f == _filterStatus;
                  return GestureDetector(
                    onTap: () => setState(() => _filterStatus = f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: selected ? AppColors.accentGradient : null,
                        color: selected
                            ? null
                            : Colors.white.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? Colors.transparent
                              : Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Text(
                        f,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: selected
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── Orders List ───────────────────────────────────────────────────
            Expanded(
              child: StreamBuilder<List<OrderModel>>(
                stream: _service.getOrdersForVendor(uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.accent),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}',
                          style: const TextStyle(
                              color: AppColors.textSecondary)),
                    );
                  }

                  final all = snapshot.data ?? [];
                  final orders = _filterStatus == 'All'
                      ? all
                      : all.where((o) {
                          if (_filterStatus == 'Pending') {
                            return o.status == 'Processing';
                          }
                          return o.status == _filterStatus;
                        }).toList();

                  if (orders.isEmpty) {
                    return _EmptyState(filter: _filterStatus);
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                    itemCount: orders.length,
                    itemBuilder: (_, i) => _OrderCard(
                      order: orders[i],
                      service: _service,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String filter;
  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
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
            child: const Icon(Icons.receipt_long_outlined,
                color: AppColors.accent, size: 40),
          ),
          const SizedBox(height: 20),
          Text(
            filter == 'All'
                ? 'No bookings yet'
                : 'No $filter bookings',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bookings from customers will\nappear here',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ─── Order Card ───────────────────────────────────────────────────────────────
class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final FirebaseService service;

  const _OrderCard({required this.order, required this.service});

  Color get _statusColor {
    return switch (order.status) {
      'Confirmed' => const Color(0xFF10B981),
      'Delivered' => const Color(0xFF3B82F6),
      'Rejected' => const Color(0xFFEF4444),
      'Out for Delivery' => const Color(0xFFF59E0B),
      'Prepared' => const Color(0xFF8B5CF6),
      _ => const Color(0xFFF59E0B), // Processing / Pending
    };
  }

  bool get _isPending => order.status == 'Processing';
  bool get _isRejected => order.status == 'Rejected';
  bool get _isDelivered => order.status == 'Delivered';
  bool get _canUpdateTracking =>
      !_isPending && !_isRejected && !_isDelivered;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Card Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  // Order icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.event_rounded,
                        color: _statusColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  // Order info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.eventName.isEmpty
                              ? 'Unnamed Event'
                              : order.eventName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${order.customerName} • #${order.id.substring(0, 8).toUpperCase()}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: _statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _isPending ? 'Pending' : order.status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _statusColor,
                      ),
                    ),
                  ),
                  // Call button – always visible when phone is known
                  if (order.phone.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () async {
                        final uri = Uri(scheme: 'tel', path: order.phone);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                        ),
                        child: const Icon(Icons.call_rounded,
                            color: Color(0xFF10B981), size: 18),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── Order Details Row ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _InfoChip(
                    icon: Icons.currency_rupee_rounded,
                    label:
                        '₹${order.total.toStringAsFixed(0)}',
                  ),
                  const SizedBox(width: 8),
                  _InfoChip(
                    icon: Icons.location_on_outlined,
                    label: order.city.isEmpty ? 'N/A' : order.city,
                  ),
                  const SizedBox(width: 8),
                  _InfoChip(
                    icon: Icons.calendar_today_outlined,
                    label:
                        '${order.createdAt.day}/${order.createdAt.month}',
                  ),
                ],
              ),
            ),

            // ── Items Preview ─────────────────────────────────────────────────
            if (order.items.isNotEmpty) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  order.items
                      .take(2)
                      .map((i) => '${i.name} ×${i.quantity}')
                      .join(', ') +
                      (order.items.length > 2
                          ? ' +${order.items.length - 2} more'
                          : ''),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],

            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0x18FFFFFF)),

            // ── Action Buttons ────────────────────────────────────────────────
            if (_isPending) ...[
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Reject
                    Expanded(
                      child: _ActionButton(
                        label: 'Reject',
                        icon: Icons.close_rounded,
                        color: const Color(0xFFEF4444),
                        onTap: () => _confirmReject(context),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Accept
                    Expanded(
                      flex: 2,
                      child: _ActionButton(
                        label: 'Accept Order',
                        icon: Icons.check_rounded,
                        color: const Color(0xFF10B981),
                        filled: true,
                        onTap: () => _accept(context),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (_canUpdateTracking) ...[
              Padding(
                padding: const EdgeInsets.all(12),
                child: _TrackingUpdater(order: order, service: service),
              ),
            ] else if (_isDelivered) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF10B981), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Delivered on ${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}',
                      style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ] else if (_isRejected) ...[
              const Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.cancel_outlined,
                        color: Color(0xFFEF4444), size: 18),
                    SizedBox(width: 8),
                    Text('Order rejected',
                        style: TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _accept(BuildContext context) async {
    try {
      await service.acceptOrder(order.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _snack('Order accepted! Update tracking below.', 0xFF10B981),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(_snack('Error: $e', 0xFFEF4444));
      }
    }
  }

  Future<void> _confirmReject(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF11102A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reject Order?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Are you sure you want to reject this booking from ${order.customerName}?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reject',
                style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await service.rejectOrder(order.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(_snack('Order rejected.', 0xFFEF4444));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(_snack('Error: $e', 0xFFEF4444));
        }
      }
    }
  }

  SnackBar _snack(String msg, int colorHex) => SnackBar(
        content: Text(msg,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: Color(colorHex),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      );
}

// ─── Tracking Updater ─────────────────────────────────────────────────────────
class _TrackingUpdater extends StatefulWidget {
  final OrderModel order;
  final FirebaseService service;

  const _TrackingUpdater({required this.order, required this.service});

  @override
  State<_TrackingUpdater> createState() => _TrackingUpdaterState();
}

class _TrackingUpdaterState extends State<_TrackingUpdater> {
  late int _step;
  late TextEditingController _noteCtrl;
  bool _loading = false;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _step = widget.order.trackingStep.clamp(1, 4);
    _noteCtrl = TextEditingController(text: widget.order.trackingNote);
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mini step progress bar
        _MiniProgress(current: widget.order.trackingStep),
        const SizedBox(height: 10),

        // Toggle update panel
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(
            children: [
              Icon(
                _expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.edit_rounded,
                color: AppColors.accent,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                _expanded ? 'Close update panel' : 'Update tracking',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        if (_expanded) ...[
          const SizedBox(height: 14),

          // Step selector
          const Text(
            'Set current stage',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(4, (i) {
              final stepIdx = i + 1; // 1..4
              final selected = stepIdx == _step;
              return GestureDetector(
                onTap: () => setState(() => _step = stepIdx),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: selected ? AppColors.accentGradient : null,
                    color: selected
                        ? null
                        : Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? Colors.transparent
                          : Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_trackingIcons[stepIdx],
                          size: 14,
                          color: selected
                              ? Colors.white
                              : AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        _trackingLabels[stepIdx],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: selected
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 12),

          // Note field
          TextFormField(
            controller: _noteCtrl,
            style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 13),
            maxLines: 2,
            decoration: InputDecoration(
              hintText:
                  'Optional note (e.g. "Driver on the way, ETA 30 min")',
              hintStyle: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.6),
                  fontSize: 12),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.04),
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.12)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.12)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: AppColors.accent, width: 1.5),
              ),
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _save,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 13),
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: _loading
                      ? null
                      : AppColors.accentGradient,
                  color: _loading ? Colors.white10 : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  alignment: Alignment.center,
                  padding:
                      const EdgeInsets.symmetric(vertical: 13),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Save Tracking Update',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await widget.service
          .updateTracking(widget.order.id, _step, _noteCtrl.text.trim());
      if (mounted) {
        setState(() => _expanded = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Tracking updated!',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ─── Mini progress bar ────────────────────────────────────────────────────────
class _MiniProgress extends StatelessWidget {
  final int current; // 0-4
  const _MiniProgress({required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final done = i <= current;
        return Expanded(
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      done ? AppColors.accent : Colors.white.withValues(alpha: 0.2),
                ),
              ),
              if (i < 4)
                Expanded(
                  child: Container(
                    height: 2,
                    color: done && i < current
                        ? AppColors.accent
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

// ─── Small helper widgets ─────────────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: filled
              ? color.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: filled ? 0.4 : 0.25),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

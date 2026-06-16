import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';
import '../../services/cart_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  Widget build(BuildContext context) {
    final cart = CartService();

    return Scaffold(
      body: Column(
        children: [
          // ── Gradient Header ───────────────────────────────────────────────
          ListenableBuilder(
            listenable: cart,
            builder: (context, _) {
              return GradientHeader(
                title: 'Shopping Cart',
                subtitle: '${cart.items.length} item${cart.items.length == 1 ? '' : 's'}',
                leading: IconButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  },
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                ),
              );
            },
          ),

          // ── Cart Content ──────────────────────────────────────────────────
          Expanded(
            child: Container(
              decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
              child: ListenableBuilder(
                listenable: cart,
                builder: (context, _) {
                  final items = cart.items;

                  if (items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 80,
                            color: AppColors.textSecondary.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Your cart is empty',
                            style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 24),
                          AppButton(
                            text: 'Browse Equipment',
                            onPressed: () => context.go('/equipment-listing'),
                            size: ButtonSize.md,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                    children: [
                      // Cart items list
                      ...items.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GlassCard(
                              child: Row(
                                children: [
                                  // Item Thumbnail Emoji
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(colors: [
                                        AppColors.accent.withValues(alpha: 0.15),
                                        AppColors.primary.withValues(alpha: 0.15),
                                      ]),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        item.emoji,
                                        style: const TextStyle(fontSize: 32),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Item Info details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: AppColors.textPrimary,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '₹${item.price.toStringAsFixed(0)}/day × ${item.days} day${item.days == 1 ? '' : 's'}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            // Qty Controls
                                            _QtyControl(
                                              qty: item.qty,
                                              onDecrement: () => cart.updateQty(item.id, -1),
                                              onIncrement: () => cart.updateQty(item.id, 1),
                                            ),
                                            const Spacer(),
                                            // Item subtotal
                                            Text(
                                              '₹${(item.price * item.qty * item.days).toStringAsFixed(0)}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.accent,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            IconButton(
                                              onPressed: () => cart.removeItem(item.id),
                                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )),

                      const SizedBox(height: 8),

                      // Order Summary Card
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Order Summary',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _SummaryRow(
                              label: 'Subtotal',
                              value: '₹${cart.subtotal.toStringAsFixed(0)}',
                            ),
                            _SummaryRow(
                              label: 'Tax (10%)',
                              value: '₹${cart.tax.toStringAsFixed(0)}',
                            ),
                            const Divider(color: Color(0x1AFFFFFF)),
                            _SummaryRow(
                              label: 'Total',
                              value: '₹${cart.total.toStringAsFixed(0)}',
                              bold: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Proceed button
                      AppButton(
                        text: 'Proceed to Checkout',
                        onPressed: () => context.go('/checkout'),
                        fullWidth: true,
                        size: ButtonSize.lg,
                        icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                      ),
                    ],
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

class _QtyControl extends StatelessWidget {
  final int qty;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _QtyControl({
    required this.qty,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onDecrement,
            child: Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              child: const Icon(Icons.remove, size: 14, color: Colors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '$qty',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          GestureDetector(
            onTap: onIncrement,
            child: Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              child: const Icon(Icons.add, size: 14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: bold ? 15 : 14,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      color: bold ? AppColors.textPrimary : AppColors.textSecondary,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}

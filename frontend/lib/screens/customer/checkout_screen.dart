import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';
import '../../services/firebase_service.dart';
import '../../services/cart_service.dart';
import '../../models/order_model.dart';
import '../../models/user_model.dart';

// ─── Checkout Screen ──────────────────────────────────────────────────────────
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipController = TextEditingController();
  final _eventNameController = TextEditingController();
  final _instructionsController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    _eventNameController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = CartService();
    final cartItems = cart.items;

    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            title: 'Checkout',
            subtitle: 'Finalize your equipment rental',
            leading: IconButton(
              onPressed: () => context.go('/cart'),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            ),
          ),
          Expanded(
            child: Container(
              decoration:
                  const BoxDecoration(gradient: AppColors.backgroundGradient),
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Delivery address details
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Delivery Address',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.textPrimary)),
                          const SizedBox(height: 12),
                          AppInput(
                            label: 'Full Name',
                            hint: 'John Doe',
                            controller: _nameController,
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
                          ),
                          const SizedBox(height: 12),
                          AppInput(
                            label: 'Phone',
                            hint: '9876543210',
                            keyboardType: TextInputType.phone,
                            controller: _phoneController,
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your phone number' : null,
                          ),
                          const SizedBox(height: 12),
                          AppInput(
                            label: 'Address',
                            hint: '123 Event Avenue, Suite 4',
                            controller: _addressController,
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your address' : null,
                          ),
                          const SizedBox(height: 12),
                          Row(children: [
                            Expanded(
                              child: AppInput(
                                label: 'City',
                                hint: 'New York',
                                controller: _cityController,
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppInput(
                                label: 'ZIP',
                                hint: '10001',
                                controller: _zipController,
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                              ),
                            ),
                          ]),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Event info
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Event Details',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.textPrimary)),
                          const SizedBox(height: 12),
                          AppInput(
                            label: 'Event Name',
                            hint: 'My Wedding Reception',
                            controller: _eventNameController,
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter event name' : null,
                          ),
                          const SizedBox(height: 12),
                          AppInput(
                            label: 'Special Instructions',
                            hint: 'Any setup notes...',
                            maxLines: 3,
                            controller: _instructionsController,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Order summary
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Order Summary',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.textPrimary)),
                          const SizedBox(height: 12),
                          if (cartItems.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Text('No items in cart', style: TextStyle(color: AppColors.textSecondary)),
                            )
                          else
                            ...cartItems.map((item) => _Row(
                                  label: '${item.name} × ${item.qty} (${item.days} day${item.days == 1 ? '' : 's'})',
                                  value: '₹${(item.price * item.qty * item.days).toStringAsFixed(0)}',
                                )),
                          _Row(label: 'Tax (10%)', value: '₹${cart.tax.toStringAsFixed(0)}'),
                          const Divider(color: Color(0x1AFFFFFF)),
                          _Row(label: 'Total', value: '₹${cart.total.toStringAsFixed(0)}', bold: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Proceed button
                    AppButton(
                      text: 'Proceed Request',
                      onPressed: () async {
                        if (!_formKey.currentState!.validate()) return;
                        if (cartItems.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Your cart is empty.')),
                          );
                          return;
                        }

                        // Show loader dialog
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
                        );

                        try {
                          final orderItems = cartItems
                              .map((item) => OrderItem(
                                    name: item.name,
                                    quantity: item.qty,
                                    price: item.price,
                                    days: item.days,
                                  ))
                              .toList();

                          final firstVendorId = cartItems.isNotEmpty ? cartItems.first.vendorId : '';

                          final order = OrderModel(
                            id: '',
                            customerName: _nameController.text.trim(),
                            phone: _phoneController.text.trim(),
                            address: _addressController.text.trim(),
                            city: _cityController.text.trim(),
                            zip: _zipController.text.trim(),
                            eventName: _eventNameController.text.trim(),
                            specialInstructions: _instructionsController.text.trim(),
                            items: orderItems,
                            total: cart.total,
                            status: 'Processing',
                            createdAt: DateTime.now(),
                            vendorId: firstVendorId,
                          );

                          final service = FirebaseService();
                          final orderId = await service.placeOrder(order);

                          final savedOrder = OrderModel(
                            id: orderId,
                            customerName: order.customerName,
                            phone: order.phone,
                            address: order.address,
                            city: order.city,
                            zip: order.zip,
                            eventName: order.eventName,
                            specialInstructions: order.specialInstructions,
                            items: order.items,
                            total: order.total,
                            status: order.status,
                            createdAt: order.createdAt,
                            vendorId: order.vendorId,
                          );

                          // Clear local shopping cart
                          CartService().clear();

                          if (context.mounted) {
                            Navigator.of(context).pop(); // Dismiss loading
                            context.go('/order-confirmation', extra: savedOrder);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            Navigator.of(context).pop(); // Dismiss loading
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error placing request: $e')),
                            );
                          }
                        }
                      },
                      fullWidth: true,
                      size: ButtonSize.lg,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  final bool bold;
  const _Row({required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) {
    final s = TextStyle(
        fontSize: bold ? 15 : 14,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        color: bold ? AppColors.textPrimary : AppColors.textSecondary);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: s, maxLines: 2, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          Text(value, style: s),
        ],
      ),
    );
  }
}

// ─── Payment Screen ───────────────────────────────────────────────────────────
class PaymentScreen extends StatefulWidget {
  final OrderModel? order;
  const PaymentScreen({super.key, this.order});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _method = 'card';

  @override
  Widget build(BuildContext context) {
    final displayTotal = widget.order?.total.toStringAsFixed(0) ?? "0";

    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            title: 'Payment',
            subtitle: 'Total: ₹$displayTotal',
            leading: IconButton(
              onPressed: () => context.go('/checkout'),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                children: [
                  // Method selector
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Payment Method',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 16),
                        ...[
                          {
                            'value': 'card',
                            'icon': Icons.credit_card_rounded,
                            'label': 'Credit / Debit Card'
                          },
                          {
                            'value': 'paypal',
                            'icon': Icons.account_balance_wallet_rounded,
                            'label': 'PayPal'
                          },
                          {
                            'value': 'bank',
                            'icon': Icons.account_balance_rounded,
                            'label': 'Bank Transfer'
                          },
                        ].map((m) {
                          final sel = _method == m['value'];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _method = m['value'] as String),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: sel
                                      ? AppColors.accent.withValues(alpha: 0.05)
                                      : Colors.white.withValues(alpha: 0.03),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: sel
                                          ? AppColors.accent
                                          : Colors.white.withValues(alpha: 0.08),
                                      width: 1.5),
                                ),
                                child: Row(
                                  children: [
                                    Icon(m['icon'] as IconData,
                                        color: sel
                                            ? AppColors.accent
                                            : AppColors.textSecondary,
                                        size: 22),
                                    const SizedBox(width: 14),
                                    Text(m['label'] as String,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: sel
                                                ? AppColors.accent
                                                : AppColors.textPrimary)),
                                    const Spacer(),
                                    if (sel)
                                      const Icon(Icons.check_circle_rounded,
                                          color: AppColors.accent, size: 20),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_method == 'card')
                    const GlassCard(
                      child: Column(
                        children: [
                          AppInput(
                              label: 'Card Number',
                              hint: '1234 5678 9012 3456',
                              prefix: Icon(Icons.credit_card_rounded, size: 20),
                              keyboardType: TextInputType.number),
                          SizedBox(height: 16),
                          AppInput(
                              label: 'Card Holder',
                              prefix: Icon(Icons.person_outline_rounded, size: 20),
                              hint: 'JOHN DOE'),
                          SizedBox(height: 16),
                          Row(children: [
                            Expanded(
                                child:
                                    AppInput(label: 'Expiry', hint: 'MM/YY')),
                            SizedBox(width: 16),
                            Expanded(
                                child: AppInput(
                                    label: 'CVV',
                                    hint: '•••',
                                    obscureText: true)),
                          ]),
                        ],
                      ),
                    ),
                  const SizedBox(height: 32),
                  AppButton(
                    text: 'Pay ₹$displayTotal',
                    variant: ButtonVariant.accent,
                    onPressed: () async {
                      if (widget.order != null) {
                        final service = FirebaseService();
                        final orderId = await service.placeOrder(widget.order!);
                        final savedOrder = OrderModel(
                          id: orderId,
                          customerName: widget.order!.customerName,
                          phone: widget.order!.phone,
                          address: widget.order!.address,
                          city: widget.order!.city,
                          zip: widget.order!.zip,
                          eventName: widget.order!.eventName,
                          specialInstructions: widget.order!.specialInstructions,
                          items: widget.order!.items,
                          total: widget.order!.total,
                          status: widget.order!.status,
                          createdAt: widget.order!.createdAt,
                          vendorId: widget.order!.vendorId,
                        );
                        // Clear local shopping cart
                        CartService().clear();
                        if (context.mounted) {
                          context.go('/order-confirmation', extra: savedOrder);
                        }
                      } else {
                        context.go('/order-confirmation');
                      }
                    },
                    fullWidth: true,
                    size: ButtonSize.lg,
                    icon: const Icon(Icons.lock_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Order Confirmation ───────────────────────────────────────────────────────
class OrderConfirmationScreen extends StatelessWidget {
  final OrderModel? order;
  const OrderConfirmationScreen({super.key, this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)]),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.green.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8))
                    ],
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 52),
                ),
                const SizedBox(height: 32),
                const Text('Request Sent to Vendor!',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                const Text('Your request has been successfully sent to the vendor. You will be notified once they accept it.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 15, height: 1.5, color: AppColors.textSecondary)),
                const SizedBox(height: 40),
                GlassCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _ConfRow(
                        label: 'Request ID', 
                        value: order != null && order!.id.isNotEmpty
                            ? (order!.id.length > 8 ? order!.id.substring(0, 8).toUpperCase() : order!.id.toUpperCase())
                            : 'ES-B042A',
                      ),
                      const Divider(height: 24, thickness: 1, color: Color(0xFFF1F5F9)),
                      _ConfRow(label: 'Total Amount', value: '₹${order?.total.toStringAsFixed(0) ?? "1,815"}'),
                      const Divider(height: 24, thickness: 1, color: Color(0xFFF1F5F9)),
                      const _ConfRow(label: 'Delivery Status', value: 'Processing', valueColor: AppColors.warning),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                AppButton(
                  text: 'Track Order',
                  variant: ButtonVariant.accent,
                  onPressed: () => context.go('/order-tracking', extra: order?.id),
                  fullWidth: true,
                  size: ButtonSize.lg,
                  icon: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(height: 16),
                AppButton(
                  text: 'Back to Home',
                  variant: ButtonVariant.ghost,
                  onPressed: () => context.go('/home'),
                  fullWidth: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfRow extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  const _ConfRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 14)),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: valueColor ?? AppColors.textPrimary)),
        ],
      ),
    );
  }
}

// ─── Order Tracking Screen ────────────────────────────────────────────────────
class OrderTrackingScreen extends StatefulWidget {
  final String? orderId;
  const OrderTrackingScreen({super.key, this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  @override
  Widget build(BuildContext context) {
    final service = FirebaseService();

    if (widget.orderId != null && widget.orderId!.isNotEmpty) {
      return StreamBuilder<OrderModel?>(
        stream: service.getOrderByIdStream(widget.orderId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
            );
          }
          final order = snapshot.data;
          if (order == null) {
            return _buildEmptyState(context);
          }
          return _buildTrackingContent(context, order);
        },
      );
    }

    // Default: stream customer's own orders and track the latest one
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return StreamBuilder<List<OrderModel>>(
      stream: service.getCustomerOrders(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
          );
        }
        final orders = snapshot.data ?? [];
        if (orders.isEmpty) {
          return _buildEmptyState(context);
        }
        return _buildTrackingContent(context, orders.first);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            title: 'Order Tracking',
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
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_shipping_outlined, size: 64, color: AppColors.textSecondary),
                    SizedBox(height: 16),
                    Text('No orders to track', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingContent(BuildContext context, OrderModel order) {
    final step = order.trackingStep;
    final isRejected = order.status == 'Rejected';

    // List of steps with description, active state and timestamp
    final steps = [
      {
        'label': 'Request Sent',
        'done': step >= 0 && !isRejected,
        'time': 'Sent',
        'subtitle': 'Waiting for vendor approval'
      },
      {
        'label': 'Request Confirmed',
        'done': step >= 1 && !isRejected,
        'time': step >= 1 ? 'Approved' : 'Pending',
        'subtitle': isRejected ? 'Request was rejected' : 'Vendor accepted booking request'
      },
      {
        'label': 'Equipment Prepared',
        'done': step >= 2 && !isRejected,
        'time': step >= 2 ? 'Completed' : 'Pending',
        'subtitle': 'Equipment package ready for event'
      },
      {
        'label': 'Out for Delivery',
        'done': step >= 3 && !isRejected,
        'time': step >= 3 ? 'Shipped' : 'Pending',
        'subtitle': 'Transit to event venue'
      },
      {
        'label': 'Delivered',
        'done': step >= 4 && !isRejected,
        'time': step >= 4 ? 'Arrived' : 'Pending',
        'subtitle': 'Handed over and set up'
      },
    ];

    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            title: 'Order Tracking',
            subtitle: 'Order ID: #${order.id.length > 8 ? order.id.substring(0, 8).toUpperCase() : order.id.toUpperCase()}',
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
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
                children: [
                  // Real-time status banner
                  GlassCard(
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isRejected
                                ? Colors.red.withValues(alpha: 0.15)
                                : AppColors.accent.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isRejected ? Icons.cancel_rounded : Icons.local_shipping_rounded,
                            color: isRejected ? Colors.red : AppColors.accent,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isRejected ? 'Request Rejected' : 'Current Status: ${order.status}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (order.trackingNote.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  order.trackingNote,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Event Info Details
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Event Details',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _InfoRow(label: 'Event', value: order.eventName),
                        _InfoRow(label: 'Deliver to', value: order.customerName),
                        _InfoRow(label: 'Venue Address', value: '${order.address}, ${order.city}'),
                        _InfoRow(label: 'Total Amount', value: '₹${order.total.toStringAsFixed(0)}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tracking Steps Card
                  GlassCard(
                    child: Column(
                      children: List.generate(steps.length, (i) {
                        final stepItem = steps[i];
                        final done = stepItem['done'] as bool;
                        final label = stepItem['label'] as String;
                        final subtitle = stepItem['subtitle'] as String;
                        final time = stepItem['time'] as String;

                        // Customize UI color if rejected
                        final stepColor = isRejected && i == 1
                            ? Colors.red
                            : (done ? AppColors.accent : Colors.white.withValues(alpha: 0.12));

                        final iconData = isRejected && i == 1
                            ? Icons.cancel_rounded
                            : (done ? Icons.check_rounded : Icons.circle);

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: stepColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    iconData,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                                if (i < steps.length - 1)
                                  Container(
                                    width: 2,
                                    height: 50,
                                    color: done && (i + 1 < steps.length && steps[i + 1]['done'] as bool)
                                        ? AppColors.accent
                                        : Colors.white.withValues(alpha: 0.08),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          label,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: done
                                                ? AppColors.textPrimary
                                                : AppColors.textSecondary,
                                          ),
                                        ),
                                        Text(
                                          time,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: done ? AppColors.accent : AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      subtitle,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: done ? AppColors.textSecondary : AppColors.textSecondary.withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Booking History ──────────────────────────────────────────────────────────
class BookingHistoryScreen extends StatelessWidget {
  const BookingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = FirebaseService();

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            title: 'Booking History',
            leading: IconButton(
              onPressed: () => context.go('/home'),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
              child: StreamBuilder<List<OrderModel>>(
                stream: service.getCustomerOrders(uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  final bookings = snapshot.data ?? [];
                  if (bookings.isEmpty) {
                    return const Center(
                        child: Text('No bookings found',
                            style: TextStyle(color: AppColors.textSecondary)));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: bookings.length,
                    itemBuilder: (_, i) => _BookingHistoryCard(booking: bookings[i]),
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

class _BookingHistoryCard extends StatelessWidget {
  final OrderModel booking;
  const _BookingHistoryCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final color = booking.status == 'Completed' || booking.status == 'Delivered'
        ? Colors.green
        : (booking.status == 'Processing' ? Colors.orange : Colors.blue);
    
    final timeStr = '${booking.createdAt.hour.toString().padLeft(2, '0')}:${booking.createdAt.minute.toString().padLeft(2, '0')}';
    final dateStr = '${booking.createdAt.day}/${booking.createdAt.month}/${booking.createdAt.year}';
    final shortId = booking.id.length > 8 ? booking.id.substring(0, 8).toUpperCase() : booking.id.toUpperCase();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        onTap: () => context.push('/order-tracking', extra: booking.id),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.event_rounded, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(booking.eventName.isEmpty ? 'Unnamed Event' : booking.eventName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text('$shortId • $dateStr at $timeStr',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  if (booking.vendorId.startsWith('mock_'))
                    const Text('Vendor: Demo Shop', style: TextStyle(fontSize: 11, color: AppColors.textSecondary))
                  else if (booking.vendorId.isNotEmpty)
                    FutureBuilder<UserModel?>(
                      future: FirebaseService().getUserById(booking.vendorId),
                      builder: (context, snapshot) {
                        final name = snapshot.data?.shopName ?? snapshot.data?.name ?? 'Unknown Vendor';
                        return Text('Vendor: $name', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary));
                      },
                    )
                  else
                    const Text('Vendor: N/A', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('₹${booking.total.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(booking.status,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: color)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Availability Calendar ────────────────────────────────────────────────────
class AvailabilityCalendarScreen extends StatefulWidget {
  const AvailabilityCalendarScreen({super.key});

  @override
  State<AvailabilityCalendarScreen> createState() =>
      _AvailabilityCalendarScreenState();
}

class _AvailabilityCalendarScreenState
    extends State<AvailabilityCalendarScreen> {
  DateTime _selected = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            title: 'Select Dates',
            subtitle: 'Choose your rental period',
            leading: IconButton(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/home');
                }
              },
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white),
            ),
          ),
          Expanded(
            child: Container(
              decoration:
                  const BoxDecoration(gradient: AppColors.backgroundGradient),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  GlassCard(
                    child: CalendarDatePicker(
                      initialDate: _selected,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      onDateChanged: (d) => setState(() => _selected = d),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Selected Date',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 8),
                        Text(
                          '${_selected.day}/${_selected.month}/${_selected.year}',
                          style: const TextStyle(
                              fontSize: 18,
                              color: AppColors.accent,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  AppButton(
                    text: 'Add to Cart',
                    onPressed: () => context.go('/cart'),
                    fullWidth: true,
                    size: ButtonSize.lg,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

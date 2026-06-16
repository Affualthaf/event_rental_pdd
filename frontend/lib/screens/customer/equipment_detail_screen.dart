import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';
import '../../services/firebase_service.dart';
import '../../services/cart_service.dart';

class EquipmentDetailScreen extends StatefulWidget {
  final String id;
  const EquipmentDetailScreen({super.key, required this.id});

  @override
  State<EquipmentDetailScreen> createState() => _EquipmentDetailScreenState();
}

class _EquipmentDetailScreenState extends State<EquipmentDetailScreen> {
  int _quantity = 1;
  int _days = 1;
  bool _isFav = false;

  static final Map<String, Map<String, dynamic>> _mockDetails = {
    '1': {
      'id': '1',
      'name': 'Professional PA System 5000W',
      'price': '₹1500/day',
      'priceAmount': 1500.0,
      'emoji': '🎤',
      'category': 'Sound',
      'description': 'High-power professional PA system for concerts and events.',
      'rating': '4.8',
      'vendorId': 'mock_vendor_1',
    },
    '2': {
      'id': '2',
      'name': 'LED Stage Lighting Kit',
      'price': '₹2000/day',
      'priceAmount': 2000.0,
      'emoji': '💡',
      'category': 'Lighting',
      'description': 'RGB stage lights with controller and stands.',
      'rating': '4.9',
      'vendorId': 'mock_vendor_2',
    },
    '3': {
      'id': '3',
      'name': 'Portable Stage Platform',
      'price': '₹3000/day',
      'priceAmount': 3000.0,
      'emoji': '🎭',
      'category': 'Staging',
      'description': 'Sturdy modular staging platforms for events.',
      'rating': '4.7',
      'vendorId': 'mock_vendor_3',
    },
    '4': {
      'id': '4',
      'name': 'Wireless Microphone Set',
      'price': '₹800/day',
      'priceAmount': 800.0,
      'emoji': '🎙️',
      'category': 'Sound',
      'description': 'Dual wireless handheld microphones with receiver.',
      'rating': '4.6',
      'vendorId': 'mock_vendor_1',
    },
    '5': {
      'id': '5',
      'name': '4K Projector & Screen',
      'price': '₹1200/day',
      'priceAmount': 1200.0,
      'emoji': '📽️',
      'category': 'AV',
      'description': 'High brightness 4K projector with large screen.',
      'rating': '4.8',
      'vendorId': 'mock_vendor_2',
    },
    '6': {
      'id': '6',
      'name': 'DJ Controller Setup',
      'price': '₹1800/day',
      'priceAmount': 1800.0,
      'emoji': '🎛️',
      'category': 'Sound',
      'description': 'Pioneer DJ controller with laptop stand.',
      'rating': '4.7',
      'vendorId': 'mock_vendor_1',
    },
    '7': {
      'id': '7',
      'name': 'Chiavari Chair Set (50)',
      'price': '₹2500/day',
      'priceAmount': 2500.0,
      'emoji': '🪑',
      'category': 'Furniture',
      'description': 'Elegant wooden chairs for receptions and gala events.',
      'rating': '4.5',
      'vendorId': 'mock_vendor_3',
    },
    '8': {
      'id': '8',
      'name': 'Moving Head Spot Light',
      'price': '₹900/day',
      'priceAmount': 900.0,
      'emoji': '🔦',
      'category': 'Lighting',
      'description': 'DMX controlled moving head light for concerts.',
      'rating': '4.9',
      'vendorId': 'mock_vendor_2',
    },
  };

  Future<Map<String, dynamic>?> _loadItem() async {
    final fsItem = await FirebaseService().getEquipmentById(widget.id);
    if (fsItem != null) return fsItem;
    if (_mockDetails.containsKey(widget.id)) {
      return _mockDetails[widget.id];
    }
    return null;
  }

  void _addToCart(Map<String, dynamic> item, {bool navigateToCart = false}) {
    final priceAmount = item['priceAmount'] != null
        ? (item['priceAmount'] as num).toDouble()
        : 1000.0;

    final cartItem = CartItem(
      id: item['id'] as String? ?? widget.id,
      name: item['name'] as String? ?? 'Equipment Item',
      price: priceAmount,
      qty: _quantity,
      days: _days,
      emoji: item['emoji'] as String? ?? '⚙️',
      vendorId: item['vendorId'] as String? ?? '',
    );

    CartService().addItem(cartItem);

    if (navigateToCart) {
      context.go('/cart');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${cartItem.name} added to cart!',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'VIEW CART',
            textColor: Colors.white,
            onPressed: () => context.go('/cart'),
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _loadItem(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
          );
        }

        final item = snapshot.data;
        if (item == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Item Not Found'),
              backgroundColor: AppColors.primary,
            ),
            body: const Center(
              child: Text('We could not load this item.', style: TextStyle(color: Colors.white)),
            ),
          );
        }

        final priceAmount = item['priceAmount'] != null
            ? (item['priceAmount'] as num).toDouble()
            : 0.0;
        final displayPrice = '₹${priceAmount.toStringAsFixed(0)}/day';
        final name = item['name'] as String? ?? 'Equipment';
        final emoji = item['emoji'] as String? ?? '⚙️';
        final category = item['category'] as String? ?? 'General';
        final description = item['description'] as String? ?? 'No description provided by the vendor.';
        final rating = item['rating'] ?? '4.5';

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: AppColors.primary,
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
                actions: [
                  IconButton(
                    onPressed: () => setState(() => _isFav = !_isFav),
                    icon: Icon(
                      _isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: _isFav ? Colors.red : Colors.white,
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 100)),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            category,
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Item Name
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Rating & Location row
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 18),
                            Text(' $rating ', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(width: 16),
                            const Icon(Icons.location_on_outlined, color: AppColors.textSecondary, size: 16),
                            const SizedBox(width: 4),
                            const Text(
                              'Verified Vendor Partner',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Price tag
                        Text(
                          displayPrice,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Quantity selector
                        GlassCard(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Quantity',
                                style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                              ),
                              Row(
                                children: [
                                  _QtyBtn(
                                    icon: Icons.remove,
                                    onTap: () {
                                      if (_quantity > 1) {
                                        setState(() => _quantity--);
                                      }
                                    },
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      '$_quantity',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  _QtyBtn(
                                    icon: Icons.add,
                                    onTap: () => setState(() => _quantity++),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Duration selector (Days)
                        GlassCard(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Rental Duration',
                                style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                              ),
                              Row(
                                children: [
                                  _QtyBtn(
                                    icon: Icons.remove,
                                    onTap: () {
                                      if (_days > 1) {
                                        setState(() => _days--);
                                      }
                                    },
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      '$_days day${_days > 1 ? 's' : ''}',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  _QtyBtn(
                                    icon: Icons.add,
                                    onTap: () => setState(() => _days++),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Description Card
                        GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Description',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                description,
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Actions
                        Row(
                          children: [
                            Expanded(
                              child: AppButton(
                                text: 'Add to Cart',
                                variant: ButtonVariant.outline,
                                onPressed: () => _addToCart(item),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppButton(
                                text: 'Book Now',
                                onPressed: () => _addToCart(item, navigateToCart: true),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 120), // spacer for bottom nav or general padding
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';
import '../../services/firebase_service.dart';
import '../../models/user_model.dart';

class VendorItemsScreen extends StatefulWidget {
  final String vendorId;
  const VendorItemsScreen({super.key, required this.vendorId});

  @override
  State<VendorItemsScreen> createState() => _VendorItemsScreenState();
}

class _VendorItemsScreenState extends State<VendorItemsScreen> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final service = FirebaseService();

    return Scaffold(
      body: FutureBuilder<UserModel?>(
        future: service.getUserById(widget.vendorId),
        builder: (context, vendorSnap) {
          final vendor = vendorSnap.data ??
              UserModel(
                id: widget.vendorId,
                name: 'Verified Partner',
                email: '',
                phone: '',
                location: 'Local Region',
                role: 'Vendor',
                createdAt: DateTime.now(),
                shopName: 'Partner Shop',
              );

          return Column(
            children: [
              // ── Header ──────────────────────────────────────────────────────
              GradientHeader(
                title: vendor.shopName ?? 'Equipment Catalog',
                subtitle: 'By ${vendor.name} • ${vendor.location}',
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

              // ── Items from Firestore ─────────────────────────────────────────
              Expanded(
                child: Container(
                  decoration:
                      const BoxDecoration(gradient: AppColors.backgroundGradient),
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: service.getEquipmentByVendor(widget.vendorId),
                    builder: (context, itemsSnap) {
                      if (itemsSnap.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child:
                              CircularProgressIndicator(color: AppColors.accent),
                        );
                      }

                      final allItems = itemsSnap.data ?? [];

                      if (allItems.isEmpty) {
                        return _EmptyState(
                            shopName: vendor.shopName ?? vendor.name);
                      }

                      // Build category filter list from actual item categories
                      final categories = <String>{};
                      for (final item in allItems) {
                        final cat = item['category'] as String? ?? '';
                        if (cat.isNotEmpty) categories.add(cat);
                      }
                      final filterList = [
                        'All',
                        ...categories.toList()..sort()
                      ];

                      final items = _selectedCategory == 'All'
                          ? allItems
                          : allItems
                              .where((i) =>
                                  (i['category'] as String? ?? '') ==
                                  _selectedCategory)
                              .toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Category filter chips ────────────────────────────
                          if (filterList.length > 1)
                            SizedBox(
                              height: 52,
                              child: ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                                scrollDirection: Axis.horizontal,
                                itemCount: filterList.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (_, i) {
                                  final cat = filterList[i];
                                  final sel = cat == _selectedCategory;
                                  return GestureDetector(
                                    onTap: () => setState(
                                        () => _selectedCategory = cat),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 6),
                                      decoration: BoxDecoration(
                                        gradient: sel
                                            ? AppColors.accentGradient
                                            : null,
                                        color: sel
                                            ? null
                                            : Colors.white
                                                .withValues(alpha: 0.07),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                        border: Border.all(
                                          color: sel
                                              ? Colors.transparent
                                              : Colors.white
                                                  .withValues(alpha: 0.12),
                                        ),
                                      ),
                                      child: Text(
                                        cat,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: sel
                                              ? FontWeight.w700
                                              : FontWeight.w400,
                                          color: sel
                                              ? Colors.white
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                          // ── Item count ───────────────────────────────────────
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(20, 4, 20, 4),
                            child: Text(
                              '${items.length} item${items.length == 1 ? '' : 's'} available',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),

                          // ── Grid ─────────────────────────────────────────────
                          Expanded(
                            child: items.isEmpty
                                ? Center(
                                    child: Text(
                                      'No items in "$_selectedCategory"',
                                      style: const TextStyle(
                                          color: AppColors.textSecondary),
                                    ),
                                  )
                                : GridView.builder(
                                    padding: const EdgeInsets.fromLTRB(
                                        20, 8, 20, 110),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                      childAspectRatio: 0.78,
                                    ),
                                    itemCount: items.length,
                                    itemBuilder: (_, index) =>
                                        _ItemCard(item: items[index]),
                                  ),
                          ),
                        ],
                      );
                    },
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

// ─── Item Card ────────────────────────────────────────────────────────────────
class _ItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _ItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    // Support both pre-formatted price string and raw amount
    final price = item['price'] as String? ?? '';
    final priceAmount = item['priceAmount'];
    final displayPrice = price.isNotEmpty
        ? price
        : priceAmount != null
            ? '₹${priceAmount.toStringAsFixed(0)}/day'
            : 'Price on request';

    final category = item['category'] as String? ?? '';
    final emoji = item['emoji'] as String? ?? '⚙️';
    final name = item['name'] as String? ?? 'Equipment Item';
    final rating = item['rating'] ?? '4.5';

    return GlassCard(
      onTap: () => context.push('/equipment-detail/${item['id']}'),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Emoji thumbnail ──────────────────────────────────────────────
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.accent.withValues(alpha: 0.12),
                    AppColors.primary.withValues(alpha: 0.12),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 44)),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ── Category badge ───────────────────────────────────────────────
          if (category.isNotEmpty) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                category,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],

          // ── Name ─────────────────────────────────────────────────────────
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),

          // ── Price + rating ───────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  displayPrice,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              Row(children: [
                const Icon(Icons.star, color: Colors.amber, size: 12),
                Text(
                  ' $rating',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ]),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String shopName;
  const _EmptyState({required this.shopName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.inventory_2_outlined,
                    color: AppColors.accent, size: 40),
              ),
              const SizedBox(height: 20),
              Text(
                shopName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                "This vendor hasn't added any items yet.\nCheck back soon!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

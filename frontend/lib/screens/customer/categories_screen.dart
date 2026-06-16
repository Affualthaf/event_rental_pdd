import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';
import '../../services/firebase_service.dart';
import '../../models/user_model.dart';

// ─── Categories Screen ────────────────────────────────────────────────────────
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text.trim();
      });
    });
    _loadUserCity();
  }

  Future<void> _loadUserCity() async {
    final userProfile = await FirebaseService().getCurrentUserProfile();
    if (userProfile != null &&
        userProfile.location.isNotEmpty &&
        userProfile.location != 'Not set') {
      if (mounted && _searchCtrl.text.isEmpty) {
        _searchCtrl.text = userProfile.location;
      }
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // Pre-configured mock vendors to show when firestore users list is empty
  static final _mockVendors = [
    UserModel(
      id: 'mock_vendor_1',
      name: 'Sarah Connor',
      email: 'sarah@prosound.com',
      phone: '+1 (555) 123-4567',
      location: 'New York',
      role: 'Vendor',
      createdAt: DateTime.now(),
      shopName: 'ProSound & Stage Rentals',
      pincode: '10001',
    ),
    UserModel(
      id: 'mock_vendor_2',
      name: 'James Carter',
      email: 'james@luxlighting.com',
      phone: '+1 (555) 987-6543',
      location: 'Chicago',
      role: 'Vendor',
      createdAt: DateTime.now(),
      shopName: 'Lux Lighting & FX',
      pincode: '60601',
    ),
    UserModel(
      id: 'mock_vendor_3',
      name: 'Elena Rostova',
      email: 'elena@elitedecor.com',
      phone: '+1 (555) 456-7890',
      location: 'New York',
      role: 'Vendor',
      createdAt: DateTime.now(),
      shopName: 'Elite Stage & Staging',
      pincode: '10003',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final service = FirebaseService();

    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            title: 'Browse',
            subtitle: 'Find verified vendors in your city',
            bottom: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search city name...',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                          onPressed: () => _searchCtrl.clear(),
                        )
                      : null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
              child: StreamBuilder<List<UserModel>>(
                stream: service.getVendorsByCity(_searchQuery),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.accent));
                  }

                  if (_searchQuery.isEmpty) {
                    return const Center(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(32),
                        child: GlassCard(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.pin_drop_outlined,
                                color: AppColors.accent,
                                size: 64,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Search Vendors by City',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Please type a city name in the search bar above to view registered vendors.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  // Use fetched vendors, fall back to matching mock vendors if Firestore has no vendors
                  var vendors = snapshot.data ?? [];
                  if (vendors.isEmpty) {
                    final q = _searchQuery.toLowerCase();
                    vendors = _mockVendors
                        .where((v) => v.location.toLowerCase().contains(q))
                        .toList();
                  }

                  if (vendors.isEmpty) {
                    return Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(32),
                        child: GlassCard(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.storefront_outlined,
                                  color: AppColors.textSecondary, size: 64),
                              const SizedBox(height: 16),
                              const Text('No Vendors Found',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary)),
                              const SizedBox(height: 8),
                              Text('We couldn\'t find any active vendors in "$_searchQuery". Try another city like "New York" or "Chicago".',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
                    itemCount: vendors.length,
                    itemBuilder: (context, index) {
                      final vendor = vendors[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GlassCard(
                          onTap: () => context.push('/vendor-items/${vendor.id}'),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: AppColors.accentGradient,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.store_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      vendor.shopName ?? 'Event Partner',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: AppColors.textPrimary),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Owner: ${vendor.name}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on_outlined,
                                          color: AppColors.accent,
                                          size: 13,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${vendor.location} (PIN: ${vendor.pincode ?? "N/A"})',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: AppColors.textSecondary,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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

// ─── Equipment Listing Screen ─────────────────────────────────────────────────
class EquipmentListingScreen extends StatefulWidget {
  const EquipmentListingScreen({super.key});

  @override
  State<EquipmentListingScreen> createState() => _EquipmentListingScreenState();
}

class _EquipmentListingScreenState extends State<EquipmentListingScreen> {
  String _selected = 'All';
  final _filters = ['All', 'Sound', 'Lighting', 'Staging', 'AV', 'Furniture'];

  final _items = [
    {'id': '1', 'name': 'Professional PA System 5000W', 'price': '₹1500/day', 'emoji': '🎤', 'rating': '4.8', 'cat': 'Sound'},
    {'id': '2', 'name': 'LED Stage Lighting Kit', 'price': '₹2000/day', 'emoji': '💡', 'rating': '4.9', 'cat': 'Lighting'},
    {'id': '3', 'name': 'Portable Stage Platform', 'price': '₹3000/day', 'emoji': '🎭', 'rating': '4.7', 'cat': 'Staging'},
    {'id': '4', 'name': 'Wireless Microphone Set', 'price': '₹800/day', 'emoji': '🎙️', 'rating': '4.6', 'cat': 'Sound'},
    {'id': '5', 'name': '4K Projector & Screen', 'price': '₹1200/day', 'emoji': '📽️', 'rating': '4.8', 'cat': 'AV'},
    {'id': '6', 'name': 'DJ Controller Setup', 'price': '₹1800/day', 'emoji': '🎛️', 'rating': '4.7', 'cat': 'Sound'},
    {'id': '7', 'name': 'Chiavari Chair Set (50)', 'price': '₹2500/day', 'emoji': '🪑', 'rating': '4.5', 'cat': 'Furniture'},
    {'id': '8', 'name': 'Moving Head Spot Light', 'price': '₹900/day', 'emoji': '🔦', 'rating': '4.9', 'cat': 'Lighting'},
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _selected == 'All'
        ? _items
        : _items.where((i) => i['cat'] == _selected).toList();

    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            title: 'Equipment',
            subtitle: '${filtered.length} items available',
            leading: IconButton(
              onPressed: () => context.go('/home'),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            ),
            trailing: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.filter_list_rounded, color: Colors.white),
            ),
          ),
          // Filter chips
          Container(
            color: AppColors.background,
            child: SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final active = _selected == _filters[i];
                  return GestureDetector(
                    onTap: () => setState(() => _selected = _filters[i]),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: active ? AppColors.accent : Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: active ? AppColors.accent : Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Text(_filters[i],
                          style: TextStyle(
                              color: active
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ),
                  );
                },
              ),
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
                  childAspectRatio: 0.8,
                ),
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final item = filtered[i];
                  return GlassCard(
                    onTap: () => context.go('/equipment-detail/${item['id']}'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                              child: Text(item['emoji'] as String,
                                  style: const TextStyle(fontSize: 44)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(item['name'] as String,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(item['price'] as String,
                                style: const TextStyle(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                            Row(children: [
                              const Icon(Icons.star,
                                  color: Colors.amber, size: 13),
                              Text(' ${item['rating']}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary)),
                            ]),
                          ],
                        ),
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

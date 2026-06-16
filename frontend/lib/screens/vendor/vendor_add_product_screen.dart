import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firebase_service.dart';

class VendorAddProductScreen extends StatefulWidget {
  const VendorAddProductScreen({super.key});

  @override
  State<VendorAddProductScreen> createState() => _VendorAddProductScreenState();
}

class _VendorAddProductScreenState extends State<VendorAddProductScreen> {
  void _openAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.98,
        expand: false,
        builder: (_, scrollController) =>
            _AddItemSheet(scrollController: scrollController),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final service = FirebaseService();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────────
            const GradientHeader(
              title: 'My Inventory',
              subtitle: 'Manage your listed equipment',
            ),

            // ── Items from Firestore ──────────────────────────────────────────
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: service.getEquipmentByVendor(uid),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.accent),
                    );
                  }

                  final items = snap.data ?? [];

                  if (items.isEmpty) {
                    return _EmptyInventory(onAdd: _openAddSheet);
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.76,
                    ),
                    itemCount: items.length,
                    itemBuilder: (_, i) => _VendorItemCard(item: items[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // ── Floating Add Button ──────────────────────────────────────────────────
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: GestureDetector(
          onTap: _openAddSheet,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

// ─── Vendor Item Card (inventory view) ───────────────────────────────────────
class _VendorItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _VendorItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final priceAmount = item['priceAmount'];
    final priceStr = item['price'] as String? ?? '';
    // Always show in ₹
    String displayPrice;
    if (priceAmount != null) {
      displayPrice = '₹${(priceAmount as num).toStringAsFixed(0)}/day';
    } else if (priceStr.isNotEmpty) {
      // Strip any $ prefix and replace with ₹
      displayPrice = priceStr.replaceAll('\$', '₹');
    } else {
      displayPrice = 'Price N/A';
    }

    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Emoji
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  AppColors.accent.withValues(alpha: 0.12),
                  AppColors.primary.withValues(alpha: 0.12),
                ]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  item['emoji'] as String? ?? '⚙️',
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Category badge
          if ((item['category'] as String? ?? '').isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                item['category'] as String,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

          // Name
          Text(
            item['name'] as String? ?? 'Item',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),

          // Price
          Text(
            displayPrice,
            style: const TextStyle(
              color: Color(0xFF10B981),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty Inventory ──────────────────────────────────────────────────────────
class _EmptyInventory extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyInventory({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.inventory_2_outlined,
                  color: AppColors.accent, size: 44),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Items Listed Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Tap the button below to add your\nfirst equipment item.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: onAdd,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Add Your First Item',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Add Item Bottom Sheet ────────────────────────────────────────────────────
class _AddItemSheet extends StatefulWidget {
  final ScrollController scrollController;
  const _AddItemSheet({required this.scrollController});

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _selectedCategory = 'Sound';
  String _selectedEmoji = '🎤';
  bool _isLoading = false;

  static const _categories = [
    'Sound', 'Lighting', 'Staging', 'AV', 'Decor', 'Tent', 'Furniture', 'Other'
  ];

  static const _emojiOptions = [
    '🎤', '🎙️', '🎛️', '💡', '🔦', '🎭',
    '📽️', '🎪', '🎊', '🎉', '🪑', '⛺',
    '🎸', '🥁', '🎷', '🎺', '🎻', '🪗',
    '🔊', '📸', '🎬', '🎥', '💐', '🌿',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final service = FirebaseService();
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final priceNum = double.tryParse(_priceCtrl.text.trim()) ?? 0.0;

      await service.addEquipment({
        'name': _nameCtrl.text.trim(),
        'price': '₹${_priceCtrl.text.trim()}/day',   // ← INR
        'priceAmount': priceNum,
        'category': _selectedCategory,
        'emoji': _selectedEmoji,
        'description': _descCtrl.text.trim(),
        'vendorId': uid,
        'rating': '4.5',
        'createdAt': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      Navigator.pop(context); // close sheet

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 12),
            Text('Item added!',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.white)),
          ]),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: const Color(0xFFEF4444),
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF11102A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children:
        [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Sheet title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: AppColors.accentGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Add New Item',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.07),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded,
                        color: AppColors.textSecondary, size: 18),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0x12FFFFFF)),

          // Scrollable form — uses the DraggableScrollableSheet controller
          Expanded(
            child: SingleChildScrollView(
              controller: widget.scrollController,
              padding: EdgeInsets.fromLTRB(20, 16, 20, bottom + 100),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Emoji picker ───────────────────────────────────────
                    _label('Choose Icon'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _emojiOptions.map((e) {
                        final sel = e == _selectedEmoji;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedEmoji = e),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              gradient: sel
                                  ? const LinearGradient(colors: [
                                      Color(0xFF8B5CF6),
                                      Color(0xFF6366F1)
                                    ])
                                  : null,
                              color: sel
                                  ? null
                                  : Colors.white.withValues(alpha: 0.06),
                              border: Border.all(
                                color: sel
                                    ? const Color(0xFF8B5CF6)
                                    : Colors.white.withValues(alpha: 0.1),
                                width: sel ? 2 : 1,
                              ),
                            ),
                            child: Center(
                              child: Text(e,
                                  style: const TextStyle(fontSize: 20)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // ── Name ───────────────────────────────────────────────
                    _label('Item Name'),
                    const SizedBox(height: 8),
                    _field(
                      controller: _nameCtrl,
                      hint: 'e.g. Professional PA System 5000W',
                      prefix: const Icon(Icons.inventory_2_outlined,
                          color: AppColors.accent, size: 20),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please enter an item name'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // ── Price ──────────────────────────────────────────────
                    _label('Price Per Day (₹)'),
                    const SizedBox(height: 8),
                    _field(
                      controller: _priceCtrl,
                      hint: 'e.g. 1500',
                      keyboardType: TextInputType.number,
                      prefix: const Icon(Icons.currency_rupee_rounded,
                          color: Color(0xFF10B981), size: 20),
                      suffix: const Text('/day',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Please enter a price';
                        }
                        if (double.tryParse(v.trim()) == null) {
                          return 'Enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // ── Category ───────────────────────────────────────────
                    _label('Category'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((cat) {
                        final sel = cat == _selectedCategory;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedCategory = cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: sel
                                  ? const LinearGradient(colors: [
                                      Color(0xFF8B5CF6),
                                      Color(0xFFEC4899),
                                    ])
                                  : null,
                              color: sel
                                  ? null
                                  : Colors.white.withValues(alpha: 0.07),
                              border: Border.all(
                                color: sel
                                    ? Colors.transparent
                                    : Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                            child: Text(
                              cat,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: sel
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: sel
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // ── Description ────────────────────────────────────────
                    Row(children: [
                      _label('Description'),
                      const SizedBox(width: 6),
                      Text('(optional)',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary
                                  .withValues(alpha: 0.6))),
                    ]),
                    const SizedBox(height: 8),
                    _field(
                      controller: _descCtrl,
                      hint: 'Specs, condition, accessories...',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),

                    // ── Live Preview ───────────────────────────────────────
                    const Text(
                      'Preview',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _PreviewCard(
                      emoji: _selectedEmoji,
                      name: _nameCtrl.text,
                      category: _selectedCategory,
                      price: _priceCtrl.text,
                    ),
                    const SizedBox(height: 24),

                    // ── Submit ─────────────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: GestureDetector(
                        onTap: _isLoading ? null : _submit,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: _isLoading
                                ? null
                                : AppColors.accentGradient,
                            color:
                                _isLoading ? Colors.white10 : null,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: _isLoading
                                ? null
                                : [
                                    BoxShadow(
                                      color: AppColors.accent
                                          .withValues(alpha: 0.35),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                          ),
                          child: Center(
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5),
                                  )
                                : const Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                          Icons.add_circle_outline_rounded,
                                          color: Colors.white,
                                          size: 20),
                                      SizedBox(width: 10),
                                      Text(
                                        'Add to Inventory',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    Widget? prefix,
    Widget? suffix,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: (_) => setState(() {}), // live preview update
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.6),
            fontSize: 13),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        prefixIcon: prefix,
        suffix: suffix,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
      ),
      validator: validator,
    );
  }
}

// ─── Live Preview Card ────────────────────────────────────────────────────────
class _PreviewCard extends StatelessWidget {
  final String emoji;
  final String name;
  final String category;
  final String price;

  const _PreviewCard({
    required this.emoji,
    required this.name,
    required this.category,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    final displayPrice =
        price.isEmpty ? '₹0/day' : '₹$price/day';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Emoji box
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                AppColors.accent.withValues(alpha: 0.15),
                AppColors.primary.withValues(alpha: 0.15),
              ]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: 14),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'Item Name' : name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: name.isEmpty
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    // Category badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
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
                    const SizedBox(width: 10),

                    // Price in INR
                    Text(
                      displayPrice,
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

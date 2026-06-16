import 'package:flutter/foundation.dart';

class CartItem {
  final String id;
  final String name;
  final double price; // daily price
  int qty;
  int days;
  final String emoji;
  final String vendorId;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    this.qty = 1,
    this.days = 1,
    required this.emoji,
    required this.vendorId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'qty': qty,
      'days': days,
      'emoji': emoji,
      'vendorId': vendorId,
    };
  }
}

class CartService extends ChangeNotifier {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  void addItem(CartItem item) {
    final index = _items.indexWhere((element) => element.id == item.id);
    if (index >= 0) {
      _items[index].qty += item.qty;
    } else {
      _items.add(item);
    }
    notifyListeners();
  }

  void updateQty(String id, int delta) {
    final index = _items.indexWhere((element) => element.id == id);
    if (index >= 0) {
      final newQty = _items[index].qty + delta;
      if (newQty >= 1) {
        _items[index].qty = newQty;
        notifyListeners();
      }
    }
  }

  void updateDays(String id, int days) {
    final index = _items.indexWhere((element) => element.id == id);
    if (index >= 0) {
      if (days >= 1) {
        _items[index].days = days;
        notifyListeners();
      }
    }
  }

  void removeItem(String id) {
    _items.removeWhere((element) => element.id == id);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  double get subtotal => _items.fold(0.0, (sum, item) => sum + (item.price * item.qty * item.days));
  double get tax => subtotal * 0.1;
  double get total => subtotal + tax;
}

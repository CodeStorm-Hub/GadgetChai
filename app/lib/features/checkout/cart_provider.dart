import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartItem {
  final String id;
  final Map<String, dynamic> device;
  final String selectedColor;
  final int selectedTerm;
  final bool addCarePlus;
  final int quantity;

  CartItem({
    required this.id,
    required this.device,
    this.selectedColor = 'Silver',
    this.selectedTerm = 3,
    this.addCarePlus = false,
    this.quantity = 1,
  });

  CartItem copyWith({
    String? selectedColor,
    int? selectedTerm,
    bool? addCarePlus,
    int? quantity,
  }) {
    return CartItem(
      id: id,
      device: device,
      selectedColor: selectedColor ?? this.selectedColor,
      selectedTerm: selectedTerm ?? this.selectedTerm,
      addCarePlus: addCarePlus ?? this.addCarePlus,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'device': device,
        'selectedColor': selectedColor,
        'selectedTerm': selectedTerm,
        'addCarePlus': addCarePlus,
        'quantity': quantity,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as String,
      device: Map<String, dynamic>.from(json['device'] as Map),
      selectedColor: json['selectedColor'] as String? ?? 'Silver',
      selectedTerm: json['selectedTerm'] as int? ?? 3,
      addCarePlus: json['addCarePlus'] as bool? ?? false,
      quantity: json['quantity'] as int? ?? 1,
    );
  }
}

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]) {
    _restore();
  }

  static const _storageKey = 'gadgetchai_cart_v1';

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) return;
      final list = jsonDecode(raw) as List<dynamic>;
      state = list
          .map((e) => CartItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      // Corrupt cache — start fresh
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(state.map((item) => item.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (_) {
      // Non-fatal
    }
  }

  void addToCart(Map<String, dynamic> device, {int term = 3, String color = 'Silver'}) {
    final index = state.indexWhere((item) =>
        item.device['id'] == device['id'] &&
        item.selectedTerm == term &&
        item.selectedColor == color);

    if (index >= 0) {
      final item = state[index];
      state = [
        ...state.sublist(0, index),
        item.copyWith(quantity: item.quantity + 1),
        ...state.sublist(index + 1),
      ];
    } else {
      final newItem = CartItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        device: device,
        selectedTerm: term,
        selectedColor: color,
      );
      state = [...state, newItem];
    }
    _persist();
  }

  void removeFromCart(String cartItemId) {
    state = state.where((item) => item.id != cartItemId).toList();
    _persist();
  }

  void updateTerm(String cartItemId, int term) {
    state = state.map((item) {
      if (item.id == cartItemId) {
        return item.copyWith(selectedTerm: term);
      }
      return item;
    }).toList();
    _persist();
  }

  void updateColor(String cartItemId, String color) {
    state = state.map((item) {
      if (item.id == cartItemId) {
        return item.copyWith(selectedColor: color);
      }
      return item;
    }).toList();
    _persist();
  }

  void toggleCarePlus(String cartItemId, bool enabled) {
    state = state.map((item) {
      if (item.id == cartItemId) {
        return item.copyWith(addCarePlus: enabled);
      }
      return item;
    }).toList();
    _persist();
  }

  void clearCart() {
    state = [];
    _persist();
  }

  double getPriceForTerm(Map<String, dynamic> device, int term) {
    switch (term) {
      case 1:
        return (device['monthly_price_1m'] as num).toDouble();
      case 3:
        return (device['monthly_price_3m'] as num).toDouble();
      case 6:
        return (device['monthly_price_6m'] as num).toDouble();
      case 12:
        return (device['monthly_price_12m'] as num).toDouble();
      default:
        return (device['monthly_price_3m'] as num).toDouble();
    }
  }

  double getMonthlySubtotal() {
    double sub = 0;
    for (final item in state) {
      double rate = getPriceForTerm(item.device, item.selectedTerm);
      if (item.addCarePlus) {
        rate += 450.0;
      }
      sub += rate * item.quantity;
    }
    return sub;
  }

  double getOneTimeDelivery() {
    return state.isEmpty ? 0 : 200.0;
  }

  double getTotalAmount() {
    return getMonthlySubtotal() + getOneTimeDelivery();
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});

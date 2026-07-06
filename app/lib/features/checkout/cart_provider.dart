import 'package:flutter_riverpod/flutter_riverpod.dart';

class CartItem {
  final String id; // Unique ID in cart
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
}

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addToCart(Map<String, dynamic> device, {int term = 3, String color = 'Silver'}) {
    // Check if device already in cart with same term/color
    final index = state.indexWhere((item) => 
      item.device['id'] == device['id'] && 
      item.selectedTerm == term && 
      item.selectedColor == color
    );

    if (index >= 0) {
      // Increment quantity
      final item = state[index];
      state = [
        ...state.sublist(0, index),
        item.copyWith(quantity: item.quantity + 1),
        ...state.sublist(index + 1),
      ];
    } else {
      // Add new item
      final newItem = CartItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        device: device,
        selectedTerm: term,
        selectedColor: color,
      );
      state = [...state, newItem];
    }
  }

  void removeFromCart(String cartItemId) {
    state = state.where((item) => item.id != cartItemId).toList();
  }

  void updateTerm(String cartItemId, int term) {
    state = state.map((item) {
      if (item.id == cartItemId) {
        return item.copyWith(selectedTerm: term);
      }
      return item;
    }).toList();
  }

  void updateColor(String cartItemId, String color) {
    state = state.map((item) {
      if (item.id == cartItemId) {
        return item.copyWith(selectedColor: color);
      }
      return item;
    }).toList();
  }

  void toggleCarePlus(String cartItemId, bool enabled) {
    state = state.map((item) {
      if (item.id == cartItemId) {
        return item.copyWith(addCarePlus: enabled);
      }
      return item;
    }).toList();
  }

  void clearCart() {
    state = [];
  }

  // Calculation utilities
  double getPriceForTerm(Map<String, dynamic> device, int term) {
    switch (term) {
      case 1: return (device['monthly_price_1m'] as num).toDouble();
      case 3: return (device['monthly_price_3m'] as num).toDouble();
      case 6: return (device['monthly_price_6m'] as num).toDouble();
      case 12: return (device['monthly_price_12m'] as num).toDouble();
      default: return (device['monthly_price_3m'] as num).toDouble();
    }
  }

  double getMonthlySubtotal() {
    double sub = 0;
    for (var item in state) {
      double rate = getPriceForTerm(item.device, item.selectedTerm);
      if (item.addCarePlus) {
        rate += 450.0; // GadgetChai Care Plus = 450 BDT / month
      }
      sub += rate * item.quantity;
    }
    return sub;
  }

  double getOneTimeDelivery() {
    // Standard one-time dispatch delivery = 200 BDT
    return state.isEmpty ? 0 : 200.0;
  }

  double getTotalAmount() {
    return getMonthlySubtotal() + getOneTimeDelivery();
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});

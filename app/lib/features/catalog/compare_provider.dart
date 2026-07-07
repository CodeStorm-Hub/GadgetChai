import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Up to 3 devices for side-by-side comparison.
class CompareNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  CompareNotifier() : super([]);

  static const maxDevices = 3;

  bool contains(String deviceId) =>
      state.any((d) => d['id'] == deviceId);

  void toggle(Map<String, dynamic> device) {
    final id = device['id'] as String;
    if (contains(id)) {
      state = state.where((d) => d['id'] != id).toList();
      return;
    }
    if (state.length >= maxDevices) return;
    state = [...state, device];
  }

  void remove(String deviceId) {
    state = state.where((d) => d['id'] != deviceId).toList();
  }

  void clear() => state = [];
}

final compareProvider =
    StateNotifierProvider<CompareNotifier, List<Map<String, dynamic>>>(
  (ref) => CompareNotifier(),
);

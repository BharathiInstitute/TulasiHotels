/// Combo meal providers
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/features/menu/services/combo_service.dart';
import 'package:tulasihotels/models/combo_model.dart';

/// Stream all combos
final combosStreamProvider = StreamProvider.autoDispose<List<ComboModel>>((ref) {
  return ComboService.combosStream();
});

/// Stream only available combos
final availableCombosProvider = StreamProvider.autoDispose<List<ComboModel>>((ref) {
  return ComboService.availableCombosStream();
});

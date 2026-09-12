import 'package:flutter/material.dart';

/// Maps a [ServiceCategory.id] to its icon (plan §8.1: clothes / home
/// textiles / carpets / curtains).
IconData categoryIcon(String categoryId) => switch (categoryId) {
  'cat-clothes' => Icons.checkroom_rounded,
  'cat-textiles' => Icons.bed_rounded,
  'cat-carpets' => Icons.grid_on_rounded,
  'cat-curtains' => Icons.window_rounded,
  _ => Icons.local_laundry_service_rounded,
};
